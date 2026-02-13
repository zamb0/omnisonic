import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/utils/app_log.dart';

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
  ) {
    _initialize();
  }

  final PlaybackRepository _playbackRepository;
  final PlayTrackUseCase _playTrackUseCase;

  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<List<Track>>? _queueSubscription;

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

  void _initialize() {
    _subscribeToPlaybackState();
    _subscribeToPosition();
    _subscribeToQueue();
    _loadCurrentState();
  }

  void _subscribeToPlaybackState() {
    _playbackStateSubscription = _playbackRepository.observePlaybackState().listen(
      (state) {
        _playbackState = state;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Playback state error: $error');
      },
    );
  }

  void _subscribeToPosition() {
    _positionSubscription = _playbackRepository.observePosition().listen(
      (position) {
        _playbackState = _playbackState.copyWith(position: position);
        notifyListeners();
      },
      onError: (error) {
        AppLog.warn('Position stream error: $error');
      },
    );
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
        (failure) => AppLog.warn('Failed to load current state: ${failure.message}'),
        (state) {
          _playbackState = state;
          notifyListeners();
        },
      );
    } catch (e) {
      AppLog.warn('Error loading current state: $e');
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
    if (_isLoading) return;

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
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
        milliseconds: (duration.inMilliseconds * progress.clamp(0.0, 1.0)).round(),
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
    final result = await _playbackRepository.setQueue(tracks, startIndex: startIndex);
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

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }
}