import 'dart:async';

import 'package:audio_service/audio_service.dart' hide PlaybackState;

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart' show PlaybackState, RepeatMode;
import 'audio_player_data_source.dart';

/// Audio service handler for background playback and system integration
class AudioServiceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioServiceHandler({
    required AudioPlayerDataSource audioPlayerDataSource,
  }) : _audioPlayerDataSource = audioPlayerDataSource {
    _init();
  }

  final AudioPlayerDataSource _audioPlayerDataSource;
  late StreamSubscription<PlaybackState> _playbackStateSubscription;
  late StreamSubscription<List<Track>> _queueSubscription;

  void _init() {
    // Listen to playback state changes and update media session
    _playbackStateSubscription = _audioPlayerDataSource.observePlaybackState().listen((state) {
      _updateMediaSession(state);
    });

    // Listen to queue changes and update media session queue
    _queueSubscription = _audioPlayerDataSource.observeQueue().listen((queue) {
      _updateQueue(queue);
    });
  }

  @override
  Future<void> play() async {
    final result = await _audioPlayerDataSource.resume();
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> pause() async {
    final result = await _audioPlayerDataSource.pause();
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> stop() async {
    final result = await _audioPlayerDataSource.stop();
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> seek(Duration position) async {
    final result = await _audioPlayerDataSource.seek(position);
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> skipToNext() async {
    final result = await _audioPlayerDataSource.skipToNext();
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> skipToPrevious() async {
    final result = await _audioPlayerDataSource.skipToPrevious();
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final queue = _audioPlayerDataSource.getCurrentQueue();
    if (index >= 0 && index < queue.length) {
      final result = await _audioPlayerDataSource.setQueue(queue, startIndex: index);
      result.fold(
        (failure) => throw Exception(failure.toString()),
        (_) => null,
      );
      await play();
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final track = _mediaItemToTrack(mediaItem);
    final result = await _audioPlayerDataSource.addToQueue(track);
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final queue = _audioPlayerDataSource.getCurrentQueue();
    final index = queue.indexWhere((track) => track.id == mediaItem.id);
    if (index != -1) {
      final result = await _audioPlayerDataSource.removeFromQueue(index);
      result.fold(
        (failure) => throw Exception(failure.toString()),
        (_) => null,
      );
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    RepeatMode mode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        mode = RepeatMode.none;
        break;
      case AudioServiceRepeatMode.one:
        mode = RepeatMode.one;
        break;
      case AudioServiceRepeatMode.all:
        mode = RepeatMode.all;
        break;
      default:
        mode = RepeatMode.none;
    }
    
    final result = await _audioPlayerDataSource.setRepeatMode(mode);
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    final result = await _audioPlayerDataSource.setShuffleMode(enabled);
    result.fold(
      (failure) => throw Exception(failure.toString()),
      (_) => null,
    );
  }

  /// Updates the media session with current playback state
  void _updateMediaSession(PlaybackState state) {
    print('📱 Updating media session: isPlaying=${state.isPlaying}, track=${state.currentTrack?.title}, queue=${state.queue.length} tracks, currentIndex=${state.currentIndex}');
    
    final controls = <MediaControl>[];
    
    // Always show skip buttons if there's a queue
    final hasQueue = state.queue.isNotEmpty && state.queue.length > 1;
    
    // Add previous control
    if (hasQueue) {
      controls.add(MediaControl.skipToPrevious);
    }
    
    // Add play/pause control
    if (state.isPlaying) {
      controls.add(MediaControl.pause);
    } else {
      controls.add(MediaControl.play);
    }
    
    // Add next control
    if (hasQueue) {
      controls.add(MediaControl.skipToNext);
    }

    // Update playback state
    playbackState.add(playbackState.value.copyWith(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: hasQueue 
          ? [0, 1, 2]  // Show all three: previous, play/pause, next
          : [0],  // Show only play/pause
      processingState: _mapProcessingState(state),
      playing: state.isPlaying,
      updatePosition: state.position,
      bufferedPosition: state.position, // Simplified - could be enhanced
      speed: state.isPlaying ? 1.0 : 0.0,
      queueIndex: state.currentIndex,
    ));

    // Update media item if there's a current track
    if (state.currentTrack != null) {
      final mediaItem = _trackToMediaItem(state.currentTrack!);
      print('📱 Setting media item: ${mediaItem.title} by ${mediaItem.artist}');
      this.mediaItem.add(mediaItem);
    }
  }

  /// Updates the queue in the media session
  void _updateQueue(List<Track> tracks) {
    final mediaItems = tracks.map(_trackToMediaItem).toList();
    queue.add(mediaItems);
  }

  /// Converts a Track to a MediaItem
  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.id,
      album: track.album,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: track.coverArtUrl != null ? Uri.parse(track.coverArtUrl!) : null,
      extras: {
        'serverId': track.serverId,
        'streamUrl': track.streamUrl,
        'quality': track.quality.name,
        'trackNumber': track.trackNumber,
        'discNumber': track.discNumber,
        'year': track.year,
        'genre': track.genre,
      },
    );
  }

  /// Converts a MediaItem to a Track
  Track _mediaItemToTrack(MediaItem mediaItem) {
    return Track(
      id: mediaItem.id,
      title: mediaItem.title,
      artist: mediaItem.artist ?? 'Unknown Artist',
      album: mediaItem.album ?? 'Unknown Album',
      duration: mediaItem.duration ?? Duration.zero,
      serverId: mediaItem.extras?['serverId'] ?? '',
      streamUrl: mediaItem.extras?['streamUrl'] ?? '',
      quality: AudioQuality.values.firstWhere(
        (q) => q.name == mediaItem.extras?['quality'],
        orElse: () => AudioQuality.medium,
      ),
      lastModified: DateTime.now(),
      trackNumber: mediaItem.extras?['trackNumber'],
      discNumber: mediaItem.extras?['discNumber'],
      year: mediaItem.extras?['year'],
      genre: mediaItem.extras?['genre'],
      coverArtUrl: mediaItem.artUri?.toString(),
    );
  }

  /// Maps internal processing state to AudioService processing state
  AudioProcessingState _mapProcessingState(PlaybackState state) {
    if (state.currentTrack == null) {
      return AudioProcessingState.idle;
    }
    
    if (state.isPlaying) {
      return AudioProcessingState.ready;
    } else {
      return AudioProcessingState.ready;
    }
  }

  /// Disposes of resources
  void dispose() {
    _playbackStateSubscription.cancel();
    _queueSubscription.cancel();
  }
}