import 'dart:async';

import 'package:audio_service/audio_service.dart' hide PlaybackState;

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/playback_repository.dart'
    show PlaybackState, RepeatMode;
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/platform_info.dart';
import '../repositories/playback_repository_impl.dart';
import 'audio_player_data_source.dart';
import 'audio_service_handler.dart';
import 'audio_focus_manager.dart';
import 'media_library_browser.dart';
import 'mpris_handler.dart';

/// High-level playback service that coordinates all audio components
class PlaybackService {
  PlaybackService({
    required AudioPlayerDataSource audioPlayerDataSource,
    required AudioServiceHandler audioServiceHandler,
    required AudioFocusManager audioFocusManager,
    required MprisHandler mprisHandler,
  }) : _audioPlayerDataSource = audioPlayerDataSource,
       _audioServiceHandler = audioServiceHandler,
       _audioFocusManager = audioFocusManager,
       _mprisHandler = mprisHandler;

  final AudioPlayerDataSource _audioPlayerDataSource;
  final AudioServiceHandler _audioServiceHandler;
  final AudioFocusManager _audioFocusManager;
  final MprisHandler _mprisHandler;

  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  /// Public method to initialize the service (should be called at app startup)
  Future<void> initialize() => _init();

  /// Initializes the playback service.
  ///
  /// Concurrent and repeat calls share the same in-flight future. Callers that
  /// time out (see `main.dart`) must not trigger a second `AudioService.init()`.
  Future<void> _init() {
    if (_isInitialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      // audio_service only supports Android, iOS, macOS, and Windows
      // Skip initialization on Linux and Web
      if (!AppPlatform.isLinux) {
        AppLog.info('Initializing AudioService for media notifications');
        // Initialize audio service for background playback
        await AudioService.init(
          builder: () => _audioServiceHandler,
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.omnisonic.audio',
            androidNotificationChannelName: 'Omnisonic Audio',
            androidNotificationChannelDescription: 'Audio playback controls',
            androidNotificationOngoing: false,
            androidStopForegroundOnPause: false,
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidShowNotificationBadge: true,
            fastForwardInterval: Duration(seconds: 10),
            rewindInterval: Duration(seconds: 10),
            androidBrowsableRootExtras: MediaLibraryBrowser.rootExtras,
          ),
        );

        AppLog.info('AudioService initialized successfully');
      } else {
        AppLog.info('Skipping AudioService on Linux - using MPRIS instead');
        // Initialize MPRIS on Linux
        await _mprisHandler.initialize();
      }
    } catch (e) {
      // If audio service initialization fails, continue without it
      // The app can still function with basic playback
      AppLog.warn('Audio service initialization failed: $e');
    }

    // The gapless listener must be attached even when the media-notification
    // layer above failed to start, so it is set up separately.
    try {
      _playbackStateSubscription ??= _audioPlayerDataSource
          .observePlaybackState()
          .listen((state) {
            _handlePlaybackStateForGapless(state);
          });
    } catch (e) {
      AppLog.warn('Failed to observe playback state for gapless: $e');
    }

    _isInitialized = true;
    _initFuture = null;
  }

  /// Ensures the service is initialized before operations
  Future<void> _ensureInitialized() => _init();

  /// Plays a track with gapless preparation
  Future<Result<void>> playTrack(Track track) async {
    await _ensureInitialized();

    try {
      final result = await _audioPlayerDataSource.play(track);
      if (result.isSuccess) {
        await _prepareNextTrackForGapless();
      }
      return result;
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to play track: $e'));
    }
  }

  /// Sets a queue and prepares for gapless playback
  Future<Result<void>> setQueueWithGapless(
    List<Track> tracks, {
    int startIndex = 0,
  }) async {
    await _ensureInitialized();

    try {
      final result = await _audioPlayerDataSource.setQueue(
        tracks,
        startIndex: startIndex,
      );
      if (result.isSuccess) {
        await _prepareNextTrackForGapless();
      }
      return result;
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to set queue: $e'));
    }
  }

  /// Prepares the next track for gapless playback
  Future<void> _prepareNextTrackForGapless() async {
    try {
      final currentState = _audioPlayerDataSource.getCurrentState();
      final queue = currentState.queue;
      final currentIndex = currentState.currentIndex;

      // Determine next track index based on repeat and shuffle modes
      int? nextIndex;

      if (currentState.shuffleEnabled) {
        // In shuffle mode, we can't easily predict the next track
        // Just ensure we have tracks available
        if (queue.length > 1) {
          nextIndex = (currentIndex + 1) % queue.length;
        }
      } else {
        // Normal sequential playback
        if (currentIndex + 1 < queue.length) {
          nextIndex = currentIndex + 1;
        } else if (currentState.repeatMode == RepeatMode.all) {
          nextIndex = 0; // Loop back to first track
        }
      }

      // Pre-cache the next track if available and not already cached
      if (nextIndex != null && nextIndex < queue.length) {
        final nextTrack = queue[nextIndex];
        if (!nextTrack.isCached) {
          // Start background caching for the next track
          _startBackgroundCaching(nextTrack);
        }
      }
    } catch (e) {
      // Gapless preparation failure shouldn't stop playback
      AppLog.warn('Failed to prepare next track for gapless playback: $e');
    }
  }

  /// Starts background caching for a track (placeholder implementation)
  void _startBackgroundCaching(Track track) {
    // This would typically involve:
    // 1. Starting a background download of the track
    // 2. Storing it in a temporary cache
    // 3. Making it available for immediate playback
    //
    // For now, this is a placeholder as the actual caching
    // implementation would depend on the caching strategy
    AppLog.info('Starting background cache for next track');
  }

  /// Handles playback state changes for gapless management
  void _handlePlaybackStateForGapless(PlaybackState state) {
    // When a track is near completion, prepare the next one
    if (state.currentTrack != null && state.duration.inMilliseconds > 0) {
      final remainingTime = state.duration - state.position;

      // Prepare next track when 10 seconds remaining
      if (remainingTime.inSeconds <= 10 && remainingTime.inSeconds > 8) {
        _prepareNextTrackForGapless();
      }
    }
  }

  /// Handles audio interruptions
  Future<void> handleAudioInterruption({
    required bool interrupted,
    required bool shouldPause,
  }) async {
    await _audioFocusManager.handleAudioInterruption(
      interrupted: interrupted,
      shouldPause: shouldPause,
    );
  }

  /// Handles becoming noisy (headphones unplugged)
  Future<void> handleBecomingNoisy() async {
    await _audioFocusManager.handleBecomingNoisy();
  }

  /// Handles audio route changes
  Future<void> handleAudioRouteChange({
    required String newRoute,
    required String previousRoute,
  }) async {
    await _audioFocusManager.handleAudioRouteChange(
      newRoute: newRoute,
      previousRoute: previousRoute,
    );
  }

  /// Gets the underlying playback repository for direct access.
  ///
  /// Built once: the getter used to allocate a fresh repository — and with it
  /// a fresh set of stream subscriptions — on every access.
  late final PlaybackRepositoryImpl repository = PlaybackRepositoryImpl(
    audioPlayerDataSource: _audioPlayerDataSource,
  );

  /// Disposes of resources
  void dispose() {
    _playbackStateSubscription?.cancel();
    _playbackStateSubscription = null;
    _audioFocusManager.dispose();
    _audioServiceHandler.dispose();
    _audioPlayerDataSource.dispose();
  }
}
