import 'dart:async';
import 'dart:io';

import '../../../../core/repositories/playback_repository.dart' show PlaybackState;
import 'audio_player_data_source.dart';

/// Manages audio focus and handles interruptions
class AudioFocusManager {
  AudioFocusManager({
    required AudioPlayerDataSource audioPlayerDataSource,
  }) : _audioPlayerDataSource = audioPlayerDataSource {
    _init();
  }

  final AudioPlayerDataSource _audioPlayerDataSource;
  late StreamSubscription<PlaybackState> _playbackStateSubscription;
  
  bool _wasPlayingBeforeInterruption = false;
  bool _hasAudioFocus = false;

  void _init() {
    // Listen to playback state changes to manage audio focus
    _playbackStateSubscription = _audioPlayerDataSource.observePlaybackState().listen((state) {
      _handlePlaybackStateChange(state);
    });

    // Set up audio session for iOS
    if (Platform.isIOS) {
      _setupIOSAudioSession();
    }
  }

  /// Handles playback state changes for audio focus management
  void _handlePlaybackStateChange(PlaybackState state) {
    if (state.isPlaying && !_hasAudioFocus) {
      _requestAudioFocus();
    } else if (!state.isPlaying && _hasAudioFocus) {
      // Don't abandon focus immediately when pausing, 
      // as user might resume quickly
      _scheduleAudioFocusAbandon();
    }
  }

  /// Requests audio focus from the system
  void _requestAudioFocus() {
    _hasAudioFocus = true;
    // Audio focus is handled automatically by audio_service and just_audio
    // This method serves as a placeholder for any custom focus logic
  }

  /// Abandons audio focus
  void _abandonAudioFocus() {
    _hasAudioFocus = false;
    // Audio focus is handled automatically by audio_service and just_audio
    // This method serves as a placeholder for any custom focus logic
  }

  /// Schedules audio focus abandon after a delay
  void _scheduleAudioFocusAbandon() {
    Timer(const Duration(seconds: 30), () {
      final currentState = _audioPlayerDataSource.getCurrentState();
      if (!currentState.isPlaying) {
        _abandonAudioFocus();
      }
    });
  }

  /// Sets up iOS audio session
  void _setupIOSAudioSession() {
    // iOS audio session is handled by just_audio and audio_service
    // This method serves as a placeholder for any custom iOS setup
  }

  /// Handles audio interruption (e.g., phone call, notification)
  Future<void> handleAudioInterruption({
    required bool interrupted,
    required bool shouldPause,
  }) async {
    if (interrupted) {
      // Audio is being interrupted
      final currentState = _audioPlayerDataSource.getCurrentState();
      _wasPlayingBeforeInterruption = currentState.isPlaying;
      
      if (shouldPause && currentState.isPlaying) {
        await _audioPlayerDataSource.pause();
      }
      
      _abandonAudioFocus();
    } else {
      // Audio interruption ended
      _requestAudioFocus();
      
      // Resume playback if it was playing before interruption
      if (_wasPlayingBeforeInterruption) {
        await _audioPlayerDataSource.resume();
      }
      
      _wasPlayingBeforeInterruption = false;
    }
  }

  /// Handles becoming noisy (e.g., headphones unplugged)
  Future<void> handleBecomingNoisy() async {
    final currentState = _audioPlayerDataSource.getCurrentState();
    if (currentState.isPlaying) {
      await _audioPlayerDataSource.pause();
    }
  }

  /// Handles audio route change (e.g., Bluetooth connection/disconnection)
  Future<void> handleAudioRouteChange({
    required String newRoute,
    required String previousRoute,
  }) async {
    // Handle specific route changes if needed
    // For example, pause when Bluetooth disconnects
    if (previousRoute.contains('Bluetooth') && !newRoute.contains('Bluetooth')) {
      final currentState = _audioPlayerDataSource.getCurrentState();
      if (currentState.isPlaying) {
        await _audioPlayerDataSource.pause();
      }
    }
  }

  /// Disposes of resources
  void dispose() {
    _playbackStateSubscription.cancel();
    _abandonAudioFocus();
  }
}