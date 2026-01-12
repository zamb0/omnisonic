import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/playback_repository.dart' show PlaybackState, RepeatMode;
import 'adaptive_streaming_service.dart';
import 'platform_audio_player.dart';

/// Data source for audio playback using platform-specific audio players
class AudioPlayerDataSource {
  AudioPlayerDataSource({
    AdaptiveStreamingService? adaptiveStreamingService,
  }) : _adaptiveStreamingService = adaptiveStreamingService ?? AdaptiveStreamingService() {
    _init();
  }

  final PlatformAudioPlayer _audioPlayer = PlatformAudioPlayer();
  final AdaptiveStreamingService _adaptiveStreamingService;
  final BehaviorSubject<PlaybackState> _playbackStateController = 
      BehaviorSubject<PlaybackState>.seeded(_getInitialState());
  final BehaviorSubject<List<Track>> _queueController = 
      BehaviorSubject<List<Track>>.seeded([]);

  List<Track> _currentQueue = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleEnabled = false;
  double _volume = 1.0;
  Track? _currentTrack;
  late StreamSubscription<AudioQuality> _qualitySubscription;

  static PlaybackState _getInitialState() => PlaybackState(
    isPlaying: false,
    currentTrack: null,
    position: Duration.zero,
    duration: Duration.zero,
    queue: const [],
    currentIndex: 0,
    repeatMode: RepeatMode.none,
    shuffleEnabled: false,
    volume: 1.0,
  );

  void _init() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      _updatePlaybackState();
      
      // Report buffering status to adaptive streaming service
      final isBuffering = playerState == PlayerState.buffering ||
                         playerState == PlayerState.loading;
      _adaptiveStreamingService.reportBufferingStatus(isBuffering);
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _updatePlaybackState();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _updatePlaybackState();
    });

    // Handle playback completion
    _audioPlayer.playerStateStream.listen((processingState) {
      if (processingState == PlayerState.completed) {
        _handleTrackCompletion();
      }
    });

    // Listen to buffer position for adaptive streaming
    _audioPlayer.positionStream.listen((position) {
      _reportBufferHealth(position);
    });

    // Listen to adaptive quality changes
    _qualitySubscription = _adaptiveStreamingService.observeRecommendedQuality().listen((quality) {
      _handleQualityChange(quality);
    });

    // Set initial volume
    _audioPlayer.setVolume(_volume);
  }

  /// Plays a specific track
  Future<Result<void>> play(Track track) async {
    try {
      // If it's a different track, load it first
      if (_currentTrack?.id != track.id) {
        await _loadTrack(track);
      }
      
      await _audioPlayer.play();
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to play track: $e'));
    }
  }

  /// Pauses the current playback
  Future<Result<void>> pause() async {
    try {
      await _audioPlayer.pause();
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to pause playback: $e'));
    }
  }

  /// Resumes the current playback
  Future<Result<void>> resume() async {
    try {
      await _audioPlayer.play();
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to resume playback: $e'));
    }
  }

  /// Stops the current playback
  Future<Result<void>> stop() async {
    try {
      await _audioPlayer.stop();
      _currentTrack = null;
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to stop playback: $e'));
    }
  }

  /// Seeks to a specific position in the current track
  Future<Result<void>> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to seek: $e'));
    }
  }

  /// Skips to the next track in the queue
  Future<Result<void>> skipToNext() async {
    try {
      final nextIndex = _getNextTrackIndex();
      if (nextIndex != null) {
        _currentIndex = nextIndex;
        final nextTrack = _currentQueue[_currentIndex];
        await _loadTrack(nextTrack);
        await _audioPlayer.play();
        _updatePlaybackState();
      }
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to skip to next: $e'));
    }
  }

  /// Skips to the previous track in the queue
  Future<Result<void>> skipToPrevious() async {
    try {
      final previousIndex = _getPreviousTrackIndex();
      if (previousIndex != null) {
        _currentIndex = previousIndex;
        final previousTrack = _currentQueue[_currentIndex];
        await _loadTrack(previousTrack);
        await _audioPlayer.play();
        _updatePlaybackState();
      }
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to skip to previous: $e'));
    }
  }

  /// Sets the playback queue
  Future<Result<void>> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    try {
      _currentQueue = List.from(tracks);
      _currentIndex = startIndex.clamp(0, tracks.length - 1);
      _queueController.add(_currentQueue);
      
      if (tracks.isNotEmpty && startIndex < tracks.length) {
        await _loadTrack(tracks[startIndex]);
      }
      
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to set queue: $e'));
    }
  }

  /// Adds a track to the end of the queue
  Future<Result<void>> addToQueue(Track track) async {
    try {
      _currentQueue.add(track);
      _queueController.add(_currentQueue);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to add to queue: $e'));
    }
  }

  /// Inserts a track at a specific position in the queue
  Future<Result<void>> insertInQueue(Track track, int index) async {
    try {
      final insertIndex = index.clamp(0, _currentQueue.length);
      _currentQueue.insert(insertIndex, track);
      
      // Adjust current index if insertion affects it
      if (insertIndex <= _currentIndex) {
        _currentIndex++;
      }
      
      _queueController.add(_currentQueue);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to insert in queue: $e'));
    }
  }

  /// Removes a track from the queue
  Future<Result<void>> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= _currentQueue.length) {
        return ResultHelper.failure(ValidationFailure('Invalid queue index: $index'));
      }
      
      _currentQueue.removeAt(index);
      
      // Adjust current index if removal affects it
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        // If we removed the current track, stop playback
        await stop();
        _currentIndex = _currentIndex.clamp(0, _currentQueue.length - 1);
      }
      
      _queueController.add(_currentQueue);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to remove from queue: $e'));
    }
  }

  /// Clears the entire queue
  Future<Result<void>> clearQueue() async {
    try {
      await stop();
      _currentQueue.clear();
      _currentIndex = 0;
      _queueController.add(_currentQueue);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to clear queue: $e'));
    }
  }

  /// Shuffles the current queue
  Future<Result<void>> shuffleQueue() async {
    try {
      if (_currentQueue.isEmpty) return ResultHelper.success(null);
      
      // Save current track
      final currentTrack = _currentTrack;
      
      // Shuffle the queue
      _currentQueue.shuffle();
      
      // Find the new index of the current track
      if (currentTrack != null) {
        _currentIndex = _currentQueue.indexWhere((track) => track.id == currentTrack.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }
      
      _queueController.add(_currentQueue);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to shuffle queue: $e'));
    }
  }

  /// Sets the repeat mode
  Future<Result<void>> setRepeatMode(RepeatMode mode) async {
    try {
      _repeatMode = mode;
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to set repeat mode: $e'));
    }
  }

  /// Sets the shuffle mode
  Future<Result<void>> setShuffleMode(bool enabled) async {
    try {
      _shuffleEnabled = enabled;
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to set shuffle mode: $e'));
    }
  }

  /// Sets the playback volume (0.0 to 1.0)
  Future<Result<void>> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      _updatePlaybackState();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to set volume: $e'));
    }
  }

  /// Observes the current playback state
  Stream<PlaybackState> observePlaybackState() => _playbackStateController.stream;

  /// Observes the current playback position
  Stream<Duration> observePosition() => _audioPlayer.positionStream;

  /// Observes the current queue
  Stream<List<Track>> observeQueue() => _queueController.stream;

  /// Gets the current playback state
  PlaybackState getCurrentState() => _playbackStateController.value;

  /// Gets the current queue
  List<Track> getCurrentQueue() => List.from(_currentQueue);

  /// Gets the current track
  Track? getCurrentTrack() => _currentTrack;

  /// Loads a track into the audio player with adaptive quality selection
  Future<void> _loadTrack(Track track) async {
    _currentTrack = track;
    
    // Get optimal quality for current network conditions
    final qualityResult = await _adaptiveStreamingService.getOptimalQuality(track);
    final optimalQuality = qualityResult.fold(
      (_) => track.quality, // Fallback to track's original quality
      (quality) => quality,
    );
    
    print('Loading track: ${track.title}');
    print('Track original quality: ${track.quality}');
    print('Selected playback quality: $optimalQuality');
    
    // Use cached file if available, otherwise stream from URL with optimal quality
    if (track.isCached && track.cachePath != null) {
      await _audioPlayer.setFilePath(track.cachePath!);
      print('Playing from cache: ${track.cachePath}');
    } else {
      // In a real implementation, you would modify the stream URL to request the optimal quality
      // For now, we use the original URL but could add quality parameters
      final streamUrl = _buildStreamUrlWithQuality(track.streamUrl, optimalQuality);
      print('Streaming from URL with quality params');
      await _audioPlayer.setUrl(streamUrl);
    }
  }

  /// Builds a stream URL with quality parameters
  String _buildStreamUrlWithQuality(String baseUrl, AudioQuality quality) {
    // This is a placeholder implementation
    // In a real Subsonic implementation, you would add quality parameters like:
    // - maxBitRate parameter for quality control
    // - format parameter for codec selection
    
    final uri = Uri.parse(baseUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    // Add quality-specific parameters
    switch (quality) {
      case AudioQuality.low:
        queryParams['maxBitRate'] = '128';
        queryParams['format'] = 'mp3';
        break;
      case AudioQuality.medium:
        queryParams['maxBitRate'] = '192';
        queryParams['format'] = 'mp3';
        break;
      case AudioQuality.high:
        queryParams['maxBitRate'] = '320';
        queryParams['format'] = 'mp3';
        break;
      case AudioQuality.lossless:
      case AudioQuality.ultra:
        // Request original format without transcoding for lossless
        queryParams.remove('maxBitRate');
        queryParams.remove('format');
        // Some Subsonic servers use 'raw' to indicate no transcoding
        queryParams['format'] = 'raw';
        break;
    }
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Reports buffer health to adaptive streaming service
  void _reportBufferHealth(Duration bufferedPosition) {
    if (_currentTrack != null && _audioPlayer.duration != null) {
      final totalDuration = _audioPlayer.duration!;
      final bufferPercentage = totalDuration.inMilliseconds > 0
          ? (bufferedPosition.inMilliseconds * 100) ~/ totalDuration.inMilliseconds
          : 0;
      
      _adaptiveStreamingService.reportBufferLevel(bufferPercentage);
    }
  }

  /// Handles quality changes from adaptive streaming service
  void _handleQualityChange(AudioQuality newQuality) {
    // Only switch quality if we're currently streaming (not using cached content)
    if (_currentTrack != null && !_currentTrack!.isCached && _audioPlayer.playing) {
      // In a real implementation, you might want to:
      // 1. Check if the quality change is significant enough to warrant a switch
      // 2. Seamlessly switch to the new quality stream
      // 3. Maintain playback position during the switch
      
      // For now, we'll just log the quality change
      print('Adaptive streaming: Quality changed to $newQuality');
    }
  }

  /// Gets the adaptive streaming service
  AdaptiveStreamingService get adaptiveStreamingService => _adaptiveStreamingService;

  /// Updates the playback state and notifies listeners
  void _updatePlaybackState() {
    final state = PlaybackState(
      isPlaying: _audioPlayer.playing,
      currentTrack: _currentTrack,
      position: _audioPlayer.position,
      duration: _audioPlayer.duration ?? Duration.zero,
      queue: _currentQueue,
      currentIndex: _currentIndex,
      repeatMode: _repeatMode,
      shuffleEnabled: _shuffleEnabled,
      volume: _volume,
    );
    
    _playbackStateController.add(state);
  }

  /// Handles track completion based on repeat mode
  Future<void> _handleTrackCompletion() async {
    switch (_repeatMode) {
      case RepeatMode.one:
        // Repeat the current track
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
        break;
      case RepeatMode.all:
        // Move to next track, or loop back to first
        final nextIndex = _getNextTrackIndex() ?? 0;
        _currentIndex = nextIndex;
        if (_currentQueue.isNotEmpty) {
          await _loadTrack(_currentQueue[_currentIndex]);
          await _audioPlayer.play();
        }
        break;
      case RepeatMode.none:
        // Move to next track if available
        final nextIndex = _getNextTrackIndex();
        if (nextIndex != null) {
          _currentIndex = nextIndex;
          await _loadTrack(_currentQueue[_currentIndex]);
          await _audioPlayer.play();
        } else {
          // No more tracks, stop playback
          await stop();
        }
        break;
    }
    _updatePlaybackState();
  }

  /// Gets the index of the next track based on current mode
  int? _getNextTrackIndex() {
    if (_currentQueue.isEmpty) return null;
    
    if (_shuffleEnabled) {
      // In shuffle mode, pick a random track (excluding current)
      if (_currentQueue.length <= 1) return null;
      int nextIndex;
      do {
        nextIndex = DateTime.now().millisecondsSinceEpoch % _currentQueue.length;
      } while (nextIndex == _currentIndex);
      return nextIndex;
    } else {
      // Normal sequential playback
      final nextIndex = _currentIndex + 1;
      if (nextIndex < _currentQueue.length) {
        return nextIndex;
      } else if (_repeatMode == RepeatMode.all) {
        return 0; // Loop back to first track
      }
      return null;
    }
  }

  /// Gets the index of the previous track
  int? _getPreviousTrackIndex() {
    if (_currentQueue.isEmpty) return null;
    
    if (_shuffleEnabled) {
      // In shuffle mode, this is more complex - for now, just go to previous index
      final previousIndex = _currentIndex - 1;
      return previousIndex >= 0 ? previousIndex : null;
    } else {
      // Normal sequential playback
      final previousIndex = _currentIndex - 1;
      if (previousIndex >= 0) {
        return previousIndex;
      } else if (_repeatMode == RepeatMode.all) {
        return _currentQueue.length - 1; // Loop to last track
      }
      return null;
    }
  }

  /// Disposes of resources
  void dispose() {
    _qualitySubscription.cancel();
    _audioPlayer.dispose();
    _playbackStateController.close();
    _queueController.close();
    _adaptiveStreamingService.dispose();
  }
}