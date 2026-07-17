import 'dart:async';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/playback_repository.dart';
import '../datasources/audio_player_data_source.dart';

/// Implementation of PlaybackRepository using just_audio
class PlaybackRepositoryImpl implements PlaybackRepository {
  const PlaybackRepositoryImpl({
    required AudioPlayerDataSource audioPlayerDataSource,
  }) : _audioPlayerDataSource = audioPlayerDataSource;

  final AudioPlayerDataSource _audioPlayerDataSource;

  @override
  Future<Result<void>> play(Track track) async {
    return await _audioPlayerDataSource.play(track);
  }

  @override
  Future<Result<void>> pause() async {
    return await _audioPlayerDataSource.pause();
  }

  @override
  Future<Result<void>> resume() async {
    return await _audioPlayerDataSource.resume();
  }

  @override
  Future<Result<void>> stop() async {
    return await _audioPlayerDataSource.stop();
  }

  @override
  Future<Result<void>> seek(Duration position) async {
    return await _audioPlayerDataSource.seek(position);
  }

  @override
  Future<Result<void>> skipToNext() async {
    return await _audioPlayerDataSource.skipToNext();
  }

  @override
  Future<Result<void>> skipToPrevious() async {
    return await _audioPlayerDataSource.skipToPrevious();
  }

  @override
  Future<Result<void>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
  }) async {
    return await _audioPlayerDataSource.setQueue(
      tracks,
      startIndex: startIndex,
    );
  }

  @override
  Future<Result<void>> addToQueue(Track track) async {
    return await _audioPlayerDataSource.addToQueue(track);
  }

  @override
  Future<Result<void>> insertInQueue(Track track, int index) async {
    return await _audioPlayerDataSource.insertInQueue(track, index);
  }

  @override
  Future<Result<void>> removeFromQueue(int index) async {
    return await _audioPlayerDataSource.removeFromQueue(index);
  }

  @override
  Future<Result<void>> clearQueue() async {
    return await _audioPlayerDataSource.clearQueue();
  }

  @override
  Future<Result<void>> shuffleQueue() async {
    return await _audioPlayerDataSource.shuffleQueue();
  }

  @override
  Future<Result<void>> setRepeatMode(RepeatMode mode) async {
    return await _audioPlayerDataSource.setRepeatMode(mode);
  }

  @override
  Future<Result<void>> setShuffleMode(bool enabled) async {
    return await _audioPlayerDataSource.setShuffleMode(enabled);
  }

  @override
  Future<Result<void>> setVolume(double volume) async {
    return await _audioPlayerDataSource.setVolume(volume);
  }

  @override
  Stream<PlaybackState> observePlaybackState() {
    return _audioPlayerDataSource.observePlaybackState();
  }

  @override
  Stream<Duration> observePosition() {
    return _audioPlayerDataSource.observePosition();
  }

  @override
  Stream<List<Track>> observeQueue() {
    return _audioPlayerDataSource.observeQueue();
  }

  @override
  Future<Result<PlaybackState>> getCurrentState() async {
    try {
      final state = _audioPlayerDataSource.getCurrentState();
      return ResultHelper.success(state);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get current state: $e'),
      );
    }
  }

  @override
  Future<Result<List<Track>>> getCurrentQueue() async {
    try {
      final queue = _audioPlayerDataSource.getCurrentQueue();
      return ResultHelper.success(queue);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get current queue: $e'),
      );
    }
  }

  @override
  Future<Result<Track?>> getCurrentTrack() async {
    try {
      final track = _audioPlayerDataSource.getCurrentTrack();
      return ResultHelper.success(track);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get current track: $e'),
      );
    }
  }
}
