import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/subsonic_api_client.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/id_generator.dart';
import '../../data/datasources/playback_tracking_service.dart';
import '../../data/datasources/adaptive_streaming_service.dart';

/// ViewModel for managing audio playback state
///
/// Handles:
/// - Current track and playback state
/// - Queue management and navigation
/// - Playback controls (play, pause, seek, etc.)
/// - Volume and repeat/shuffle settings
@injectable
class PlaybackViewModel extends ChangeNotifier {
  PlaybackViewModel(
    this._playbackRepository,
    this._playTrackUseCase,
    this._trackingService,
    this._apiClient,
    this._serverRepository,
    this._adaptiveStreamingService,
    this._database,
  ) {
    _initialize();
  }

  final PlaybackRepository _playbackRepository;
  final PlayTrackUseCase _playTrackUseCase;
  final PlaybackTrackingService _trackingService;
  final SubsonicApiClient _apiClient;
  final ServerRepository _serverRepository;
  final AdaptiveStreamingService _adaptiveStreamingService;
  final AppDatabase _database;

  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<List<Track>>? _queueSubscription;
  StreamSubscription<AudioQuality>? _qualitySubscription;
  StreamSubscription<Track>? _scrobbleSubscription;
  Timer? _positionTicker;
  DateTime? _lastPositionUpdate;
  Duration _lastObservedPosition = Duration.zero;

  // State
  PlaybackState _playbackState = const PlaybackState(
    isPlaying: false,
    currentTrack: null,
    position: Duration.zero,
    duration: Duration.zero,
    queue: [],
    currentIndex: -1,
    repeatMode: RepeatMode.none,
    shuffleEnabled: false,
    volume: 1.0,
  );
  bool _isLoading = false;
  String? _errorMessage;
  Track? _previousTrack; // Track previous track for scrobbling
  bool _isRestoring = false; // Flag to prevent auto-play during restoration
  AudioQuality _streamingQuality = AudioQuality.ultra;
  AudioQuality _maxStreamingQuality = AudioQuality.ultra;
  bool _hasScrobbledCurrentTrack = false;

  // Getters
  PlaybackState get playbackState => _playbackState;
  bool get isPlaying => _playbackState.isPlaying;
  bool get isPaused => _playbackState.isPaused;
  bool get isStopped => _playbackState.isStopped;
  Track? get currentTrack => _playbackState.currentTrack;
  Duration get position => _playbackState.position;
  Duration get duration => _playbackState.duration;
  List<Track> get queue => _playbackState.queue;
  int get currentIndex => _playbackState.currentIndex;
  RepeatMode get repeatMode => _playbackState.repeatMode;
  bool get shuffleEnabled => _playbackState.shuffleEnabled;
  double get volume => _playbackState.volume;
  bool get hasCurrentTrack => _playbackState.hasCurrentTrack;
  bool get hasNext => _playbackState.hasNext;
  bool get hasPrevious => _playbackState.hasPrevious;
  double get progress => _playbackState.progress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasQueue => queue.isNotEmpty;
  int get queueLength => queue.length;
  bool get isRestoring => _isRestoring;

  // TODO: Connect to AdaptiveStreamingService for real quality monitoring
  AudioQuality get currentQuality => _streamingQuality;
  AudioQuality get maxQuality => _maxStreamingQuality;
  double get streamingQualityRatio {
    if (_maxStreamingQuality.qualityScore == 0) return 0;
    return _streamingQuality.qualityScore / _maxStreamingQuality.qualityScore;
  }

  /// Whether the current track has already been registered as played
  /// (scrobbled) with its server. Resets on every track change.
  bool get hasScrobbledCurrentTrack => _hasScrobbledCurrentTrack;

  void _initialize() {
    try {
      AppLog.info('Initializing PlaybackViewModel...');
      _subscribeToPlaybackState();
      _subscribeToPosition();
      _subscribeToQueue();
      _subscribeToQuality();
      _subscribeToScrobbles();
      _loadCurrentState();

      // Restore queue as early as possible, with a delayed retry to
      // catch cases where subscriptions set up state slightly later.
      _restorePlayQueueIfNeeded();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!hasQueue && !_isRestoring) {
          _restorePlayQueueIfNeeded();
        }
      });
      AppLog.info('PlaybackViewModel initialized successfully');
    } catch (e, stackTrace) {
      AppLog.warn(
        'Error during PlaybackViewModel initialization: $e\n$stackTrace',
      );
    }
  }

  /// Restores the play queue from the server only if there's no current queue
  Future<void> _restorePlayQueueIfNeeded() async {
    try {
      if (_isRestoring) {
        return;
      }
      // Don't restore if we already have an active queue
      if (hasQueue && currentTrack != null) {
        AppLog.info('Active queue found, skipping restore from server');
        return;
      }

      AppLog.info('No active queue, attempting restore from server');
      await _restorePlayQueue();
    } catch (e, stackTrace) {
      AppLog.warn('Error in _restorePlayQueueIfNeeded: $e\n$stackTrace');
      // Non-critical: app should continue if restore fails
    }
  }

  void _subscribeToPlaybackState() {
    _playbackStateSubscription = _playbackRepository
        .observePlaybackState()
        .listen(
          (state) {
            // Check if track changed
            final trackChanged =
                state.currentTrack != null &&
                state.currentTrack != _previousTrack;

            _playbackState = state;
            if (state.isPlaying) {
              _startPositionTicker();
            } else {
              _stopPositionTicker();
            }
            _clearError();

            // Start tracking when track changes (but not during restoration)
            if (trackChanged && !_isRestoring) {
              _maxStreamingQuality = state.currentTrack!.quality;
              _streamingQuality = _clampQuality(
                _streamingQuality,
                _maxStreamingQuality,
              );
              _trackingService.startTrackingTrack(state.currentTrack!);
              _previousTrack = state.currentTrack;
              _hasScrobbledCurrentTrack = false;

              // Start periodic queue saving
              _trackingService.startPeriodicQueueSave(
                () async => queue,
                () async => currentIndex,
                () async => position,
              );
            }

            notifyListeners();
          },
          onError: (error) {
            _setError('Playback state error: $error');
          },
        );
  }

  void _subscribeToQuality() {
    _qualitySubscription = _adaptiveStreamingService
        .observeRecommendedQuality()
        .listen((quality) {
          _streamingQuality = _clampQuality(quality, _maxStreamingQuality);
          notifyListeners();
        });
  }

  void _subscribeToScrobbles() {
    _scrobbleSubscription = _trackingService.onScrobbled.listen((track) {
      if (currentTrack?.id == track.id) {
        _hasScrobbledCurrentTrack = true;
        notifyListeners();
      }
    });
  }

  AudioQuality _clampQuality(AudioQuality quality, AudioQuality maxQuality) {
    if (quality.qualityScore > maxQuality.qualityScore) {
      return maxQuality;
    }
    return quality;
  }

  void _subscribeToPosition() {
    _positionSubscription = _playbackRepository.observePosition().listen(
      (position) {
        _playbackState = _playbackState.copyWith(position: position);
        _lastObservedPosition = position;
        _lastPositionUpdate = DateTime.now();
        notifyListeners();
      },
      onError: (error) {
        AppLog.warn('Position stream error: $error');
      },
    );
  }

  void _startPositionTicker() {
    if (_positionTicker != null) return;

    _lastPositionUpdate ??= DateTime.now();
    _lastObservedPosition = _playbackState.position;

    _positionTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_playbackState.isPlaying || _lastPositionUpdate == null) return;

      final elapsed = DateTime.now().difference(_lastPositionUpdate!);
      final estimated = _lastObservedPosition + elapsed;
      final durationMs = _playbackState.duration.inMilliseconds;
      final clamped = durationMs > 0
          ? Duration(
              milliseconds: estimated.inMilliseconds.clamp(0, durationMs),
            )
          : estimated;

      final deltaMs =
          (clamped.inMilliseconds - _playbackState.position.inMilliseconds)
              .abs();
      if (deltaMs >= 200) {
        _playbackState = _playbackState.copyWith(position: clamped);
        notifyListeners();
      }
    });
  }

  void _stopPositionTicker() {
    _positionTicker?.cancel();
    _positionTicker = null;
  }

  void _subscribeToQueue() {
    _queueSubscription = _playbackRepository.observeQueue().listen(
      (queue) {
        _playbackState = _playbackState.copyWith(queue: queue);
        notifyListeners();
      },
      onError: (error) {
        AppLog.warn('Queue stream error: $error');
      },
    );
  }

  Future<void> _loadCurrentState() async {
    try {
      final stateResult = await _playbackRepository.getCurrentState();
      stateResult.fold(
        (failure) =>
            AppLog.warn('Failed to load current state: ${failure.message}'),
        (state) {
          _playbackState = state;
          notifyListeners();
        },
      );
    } catch (e) {
      AppLog.warn('Error loading current state: $e');
    }
  }

  /// Restores the play queue from the server
  Future<void> _restorePlayQueue() async {
    _isRestoring = true;
    notifyListeners();
    try {
      final savedState = await _trackingService.getPlayQueue();
      if (savedState == null || savedState.tracks.isEmpty) {
        AppLog.debug('No saved play queue to restore');
        return;
      }

      AppLog.info('Restoring play queue: ${savedState.tracks.length} tracks');

      // If there's a current track and position, load it
      if (savedState.currentIndex != null &&
          savedState.currentIndex! >= 0 &&
          savedState.currentIndex! < savedState.tracks.length) {
        final track = savedState.tracks[savedState.currentIndex!];
        final restoredPosition = savedState.position ?? Duration.zero;

        // Optimistically surface restored state so the UI doesn't show 0:00.
        _playbackState = _playbackState.copyWith(
          queue: savedState.tracks,
          currentIndex: savedState.currentIndex!,
          currentTrack: track,
          duration: track.duration,
          position: restoredPosition,
        );
        _lastObservedPosition = restoredPosition;
        _lastPositionUpdate = DateTime.now();
        notifyListeners();

        // Set the queue - this should load the track at the given index
        // without starting playback
        final setQueueResult = await _playbackRepository.setQueue(
          savedState.tracks,
          startIndex: savedState.currentIndex!,
        );

        var hasError = false;
        setQueueResult.fold((failure) {
          AppLog.warn('Failed to restore queue: ${failure.message}');
          hasError = true;
        }, (_) {});

        if (hasError) return;

        // Wait for the queue to be set
        await Future.delayed(const Duration(milliseconds: 500));

        // Seek to the saved position if available
        if (savedState.position != null &&
            savedState.position! > Duration.zero) {
          await _playbackRepository.seek(savedState.position!);
        }

        AppLog.info(
          'Session restored: track "${track.title}" at ${savedState.position?.inSeconds ?? 0}s (paused)',
        );
      }
    } catch (e, stackTrace) {
      AppLog.warn('Error restoring play queue: $e\n$stackTrace');
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Plays a specific track
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? startIndex,
    bool useBestSource = true,
    bool allowFallback = true,
  }) async {
    final isSwitchRequest =
        currentTrack != null && currentTrack!.id != track.id;
    if (_isLoading && !isSwitchRequest) return;
    if (_isLoading && isSwitchRequest) {
      AppLog.debug('Play requested while loading; forcing switch');
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      AppLog.debug('Play requested: ${track.title} (${track.id})');

      final shouldDirectSwitch =
          currentTrack != null &&
          currentTrack!.id != track.id &&
          queue != null &&
          queue.isNotEmpty;

      if (shouldDirectSwitch) {
        AppLog.debug('Direct switch to: ${track.title}');
        await _playbackRepository.stop();

        await _playbackRepository.setQueue(queue, startIndex: startIndex ?? 0);

        final playResult = await _playbackRepository.play(track);
        playResult.fold(
          (failure) => _setError('Failed to play track: ${failure.message}'),
          (_) => AppLog.info('Track playback started successfully'),
        );
        return;
      }

      final params = PlayTrackParams(
        track: track,
        queue: queue,
        startIndex: startIndex,
        useBestSource: useBestSource,
        allowFallback: allowFallback,
      );

      final result = await _playTrackUseCase(params);
      result.fold(
        (failure) => _setError('Failed to play track: ${failure.message}'),
        (_) => AppLog.info('Track playback started successfully'),
      );
    } catch (e) {
      _setError('Unexpected error playing track: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pauses the current playback
  Future<void> pause() async {
    final result = await _playbackRepository.pause();
    result.fold(
      (failure) => _setError('Failed to pause: ${failure.message}'),
      (_) => AppLog.info('Playback paused'),
    );
  }

  /// Resumes the current playback
  Future<void> resume() async {
    final result = await _playbackRepository.resume();
    result.fold(
      (failure) => _setError('Failed to resume: ${failure.message}'),
      (_) => AppLog.info('Playback resumed'),
    );
  }

  /// Toggles play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else if (hasCurrentTrack) {
      await resume();
    }
  }

  /// Stops the current playback
  Future<void> stop() async {
    final result = await _playbackRepository.stop();
    result.fold(
      (failure) => _setError('Failed to stop: ${failure.message}'),
      (_) => AppLog.info('Playback stopped'),
    );
  }

  /// Seeks to a specific position in the current track
  Future<void> seek(Duration position) async {
    final result = await _playbackRepository.seek(position);
    result.fold(
      (failure) => _setError('Failed to seek: ${failure.message}'),
      (_) => AppLog.debug('Seeked to ${position.inSeconds}s'),
    );
  }

  /// Seeks to a specific progress percentage (0.0 to 1.0)
  Future<void> seekToProgress(double progress) async {
    if (duration.inMilliseconds > 0) {
      final position = Duration(
        milliseconds: (duration.inMilliseconds * progress.clamp(0.0, 1.0))
            .round(),
      );
      await seek(position);
    }
  }

  /// Skips to the next track in the queue
  Future<void> skipToNext() async {
    final result = await _playbackRepository.skipToNext();
    result.fold(
      (failure) => _setError('Failed to skip to next: ${failure.message}'),
      (_) => AppLog.info('Skipped to next track'),
    );
  }

  /// Skips to the previous track in the queue
  Future<void> skipToPrevious() async {
    final result = await _playbackRepository.skipToPrevious();
    result.fold(
      (failure) => _setError('Failed to skip to previous: ${failure.message}'),
      (_) => AppLog.info('Skipped to previous track'),
    );
  }

  /// Sets the playback queue
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    final result = await _playbackRepository.setQueue(
      tracks,
      startIndex: startIndex,
    );
    result.fold(
      (failure) => _setError('Failed to set queue: ${failure.message}'),
      (_) => AppLog.info('Queue set with ${tracks.length} tracks'),
    );
  }

  /// Adds a track to the end of the queue
  Future<void> addToQueue(Track track) async {
    final result = await _playbackRepository.addToQueue(track);
    result.fold(
      (failure) => _setError('Failed to add to queue: ${failure.message}'),
      (_) => AppLog.info('Track added to queue'),
    );
  }

  /// Inserts a track at a specific position in the queue
  Future<void> insertInQueue(Track track, int index) async {
    final result = await _playbackRepository.insertInQueue(track, index);
    result.fold(
      (failure) => _setError('Failed to insert in queue: ${failure.message}'),
      (_) => AppLog.debug('Track inserted in queue at index $index'),
    );
  }

  /// Removes a track from the queue
  Future<void> removeFromQueue(int index) async {
    final result = await _playbackRepository.removeFromQueue(index);
    result.fold(
      (failure) => _setError('Failed to remove from queue: ${failure.message}'),
      (_) => AppLog.debug('Track removed from queue at index $index'),
    );
  }

  /// Moves the item at absolute queue index [oldIndex] so it ends up at
  /// absolute index [newIndex] **after removal** (i.e. `newIndex` is in the
  /// same post-removal coordinate space `ReorderableListView.onReorderItem`
  /// already hands back — no further -1 adjustment needed by the caller).
  ///
  /// Composed from [removeFromQueue] + [insertInQueue] rather than
  /// `setQueue`, because `setQueue` reloads the track at its start index —
  /// fine for replacing the whole queue, but it would restart whatever's
  /// currently playing if used here. removeFromQueue/insertInQueue only
  /// touch queue bookkeeping for indices past the current one, so reordering
  /// the "up next" tail never interrupts playback.
  Future<void> reorderQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= queue.length) {
      return;
    }
    final track = queue[oldIndex];
    await removeFromQueue(oldIndex);
    await insertInQueue(track, newIndex.clamp(0, queue.length - 1));
  }

  /// Clears the entire queue
  Future<void> clearQueue() async {
    final result = await _playbackRepository.clearQueue();
    result.fold(
      (failure) => _setError('Failed to clear queue: ${failure.message}'),
      (_) => AppLog.info('Queue cleared'),
    );
  }

  /// Shuffles the current queue
  Future<void> shuffleQueue() async {
    final result = await _playbackRepository.shuffleQueue();
    result.fold(
      (failure) => _setError('Failed to shuffle queue: ${failure.message}'),
      (_) => AppLog.info('Queue shuffled'),
    );
  }

  /// Sets the repeat mode
  Future<void> setRepeatMode(RepeatMode mode) async {
    final result = await _playbackRepository.setRepeatMode(mode);
    result.fold(
      (failure) => _setError('Failed to set repeat mode: ${failure.message}'),
      (_) => AppLog.debug('Repeat mode set to $mode'),
    );
  }

  /// Toggles repeat mode (none -> all -> one -> none)
  Future<void> toggleRepeatMode() async {
    RepeatMode nextMode;
    switch (repeatMode) {
      case RepeatMode.none:
        nextMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        nextMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        nextMode = RepeatMode.none;
        break;
    }
    await setRepeatMode(nextMode);
  }

  /// Sets the shuffle mode
  Future<void> setShuffleMode(bool enabled) async {
    final result = await _playbackRepository.setShuffleMode(enabled);
    result.fold(
      (failure) => _setError('Failed to set shuffle mode: ${failure.message}'),
      (_) => AppLog.debug('Shuffle mode set to $enabled'),
    );
  }

  /// Toggles shuffle mode
  Future<void> toggleShuffleMode() async {
    await setShuffleMode(!shuffleEnabled);
  }

  /// Sets the playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final result = await _playbackRepository.setVolume(clampedVolume);
    result.fold(
      (failure) => _setError('Failed to set volume: ${failure.message}'),
      (_) => AppLog.debug('Volume set to ${(clampedVolume * 100).round()}%'),
    );
  }

  /// Jumps to a specific track in the queue
  Future<void> jumpToTrack(int index) async {
    if (index >= 0 && index < queue.length) {
      await playTrack(queue[index], queue: queue, startIndex: index);
    }
  }

  /// Gets the next track in the queue (if any)
  Track? getNextTrack() {
    if (hasNext) {
      return queue[currentIndex + 1];
    }
    return null;
  }

  /// Gets the previous track in the queue (if any)
  Track? getPreviousTrack() {
    if (hasPrevious) {
      return queue[currentIndex - 1];
    }
    return null;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clears the current error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Toggles the favorite (starred) status of a track
  Future<void> toggleFavorite(Track track) async {
    try {
      AppLog.info(
        '🌟 Toggle favorite for track: ${track.title} (current: ${track.isStarred})',
      );

      // Get server credentials
      final serversResult = await _serverRepository.getOnlineServers();

      MusicServer? server;
      serversResult.fold(
        (failure) {
          AppLog.warn('Failed to get online servers: ${failure.message}');
          _setError('No server connection available');
        },
        (servers) {
          if (servers.isEmpty) {
            AppLog.warn('No online servers available');
            _setError('No server connection available');
          } else {
            server = servers.first;
            AppLog.debug('Using server: ${server!.name}');
          }
        },
      );

      if (server == null) return;

      final passwordResult = await _serverRepository.getCredentials(server!.id);

      String? password;
      passwordResult.fold(
        (failure) {
          AppLog.warn('Failed to get server credentials: ${failure.message}');
          _setError('Server credentials not available');
        },
        (pwd) {
          password = pwd;
        },
      );

      if (password == null) return;

      // Extract subsonic ID from composite ID
      final subsonicId = IdGenerator.extractSubsonicId(track.id);
      AppLog.info('📋 Track ID extraction:');
      AppLog.info('  - Composite ID: ${track.id}');
      AppLog.info('  - Extracted Subsonic ID: $subsonicId');
      AppLog.info('  - Server ID: ${IdGenerator.extractServerId(track.id)}');

      // Toggle favorite status
      if (track.isStarred) {
        AppLog.info('📤 Sending unstar request to server...');
        final response = await _apiClient.unstar(
          server!,
          password!,
          id: subsonicId,
        );
        AppLog.info(
          '✓ Unstar response status: ${response.subsonicResponse.status}, isSuccess: ${response.isSuccess}',
        );
        if (!response.isSuccess) {
          AppLog.error(
            '❌ Server returned error: ${response.error?.message ?? "Unknown error"}',
          );
          _setError(
            'Failed to unstar track: ${response.error?.message ?? "Unknown error"}',
          );
          return;
        }
        AppLog.info('✓ Unstarred track: ${track.title}');
      } else {
        AppLog.info('📤 Sending star request to server...');
        final response = await _apiClient.star(
          server!,
          password!,
          id: subsonicId,
        );
        AppLog.info(
          '✓ Star response status: ${response.subsonicResponse.status}, isSuccess: ${response.isSuccess}',
        );
        if (!response.isSuccess) {
          AppLog.error(
            '❌ Server returned error: ${response.error?.message ?? "Unknown error"}',
          );
          _setError(
            'Failed to star track: ${response.error?.message ?? "Unknown error"}',
          );
          return;
        }
        AppLog.info('✓ Starred track: ${track.title}');
      }

      // Update track in current state
      final updatedTrack = track.copyWith(isStarred: !track.isStarred);
      AppLog.debug('Updated track isStarred: ${updatedTrack.isStarred}');

      // Update queue if this track is in it
      final updatedQueue = queue
          .map((t) => t.id == track.id ? updatedTrack : t)
          .toList();

      // Update playback state
      _playbackState = _playbackState.copyWith(
        currentTrack: currentTrack?.id == track.id
            ? updatedTrack
            : currentTrack,
        queue: updatedQueue,
      );

      // Persist to local database
      try {
        await _database.musicDao.updateTrack(updatedTrack);
        AppLog.info(
          '💾 Updated track in local database: ${updatedTrack.title}',
        );
      } catch (e) {
        AppLog.warn('Failed to update track in local database: $e');
        // Don't fail the whole operation if local update fails
      }

      notifyListeners();
      AppLog.info('✨ UI notified of favorite change');
    } catch (e) {
      AppLog.error('❌ Failed to toggle favorite: $e');
      _setError('Failed to update favorite status');
    }
  }

  @override
  void dispose() {
    // Don't save here - it's async and won't complete before app closes
    // Queue saving is handled by:
    // 1. Periodic timer (every 30s)
    // 2. App lifecycle observer in main.dart

    _playbackStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _queueSubscription?.cancel();
    _qualitySubscription?.cancel();
    _scrobbleSubscription?.cancel();
    _stopPositionTicker();
    _trackingService.dispose();
    super.dispose();
  }
}
