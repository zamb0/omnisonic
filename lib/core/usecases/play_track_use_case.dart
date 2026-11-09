import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../entities/entities.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../repositories/repositories.dart';
import 'usecase.dart';

/// Use case for playing a track with intelligent server selection
///
/// This use case handles:
/// - Selecting the best available server for the track
/// - Handling server failover if the primary source fails
/// - Starting audio streaming
/// - Updating playback state
@injectable
class PlayTrackUseCase implements UseCase<void, PlayTrackParams> {
  const PlayTrackUseCase(
    this._playbackRepository,
    this._musicRepository,
    this._serverRepository,
  );

  final PlaybackRepository _playbackRepository;
  final MusicRepository _musicRepository;
  final ServerRepository _serverRepository;

  @override
  Future<Either<Failure, void>> call(PlayTrackParams params) async {
    try {
      Track trackToPlay = params.track;

      // If this is a deduplicated track, get the best available source
      if (params.useBestSource) {
        final bestSourceResult = await _musicRepository.getBestSourceForTrack(
          params.track.id,
        );
        if (bestSourceResult.isSuccess) {
          trackToPlay = bestSourceResult.valueOrNull!;
        }
        // If getting best source fails, continue with original track
      }

      // Verify the server is online before attempting playback
      final serverResult = await _serverRepository.getServerById(
        trackToPlay.serverId,
      );
      if (serverResult.isFailure) {
        return Left(ServerFailure('Server not found: ${trackToPlay.serverId}'));
      }

      final server = serverResult.valueOrNull;
      if (server == null) {
        return Left(ServerFailure('Server not found: ${trackToPlay.serverId}'));
      }

      if (server.status != ServerStatus.online) {
        // Try to find a fallback source for this track
        final fallbackResult = await _musicRepository.getFallbackSource(
          params.track.id,
          trackToPlay.id,
        );
        if (fallbackResult.isSuccess) {
          trackToPlay = fallbackResult.valueOrNull!;
        } else {
          return Left(
            ServerFailure('Server is offline and no fallback source available'),
          );
        }
      }

      // Set up the queue if provided, with the copy chosen above in place
      // of the requested track. Setting the queue loads its current entry:
      // with the requested track there, a track whose own server was down
      // failed right here, before the fallback below was ever tried, and
      // otherwise the track was loaded twice, once per copy.
      if (params.queue != null && params.queue!.isNotEmpty) {
        final queue = List<Track>.of(params.queue!);
        final startIndex = params.startIndex ?? 0;
        final placed =
            startIndex >= 0 &&
            startIndex < queue.length &&
            queue[startIndex].id == params.track.id;
        if (placed) queue[startIndex] = trackToPlay;

        var queueResult = await _playbackRepository.setQueue(
          queue,
          startIndex: startIndex,
        );
        if (queueResult.isFailure && placed && params.allowFallback) {
          final fallbackResult = await _musicRepository.getFallbackSource(
            params.track.id,
            trackToPlay.id,
          );
          if (fallbackResult.isSuccess) {
            trackToPlay = fallbackResult.valueOrNull!;
            queue[startIndex] = trackToPlay;
            queueResult = await _playbackRepository.setQueue(
              queue,
              startIndex: startIndex,
            );
          }
        }
        if (queueResult.isFailure) {
          return Left(
            PlaybackFailure(
              'Failed to set queue: ${queueResult.failureOrNull}',
            ),
          );
        }
      }

      // Start playback
      final playResult = await _playbackRepository.play(trackToPlay);
      if (playResult.isFailure) {
        // If playback fails, try to find a fallback source
        if (params.allowFallback) {
          final fallbackResult = await _musicRepository.getFallbackSource(
            params.track.id,
            trackToPlay.id,
          );
          if (fallbackResult.isSuccess) {
            final fallbackTrack = fallbackResult.valueOrNull!;
            final fallbackPlayResult = await _playbackRepository.play(
              fallbackTrack,
            );
            if (fallbackPlayResult.isFailure) {
              return Left(
                PlaybackFailure(
                  'Playback failed even with fallback: ${fallbackPlayResult.failureOrNull}',
                ),
              );
            }
          } else {
            return Left(
              PlaybackFailure(
                'Playback failed and no fallback available: ${playResult.failureOrNull}',
              ),
            );
          }
        } else {
          return Left(
            PlaybackFailure('Playback failed: ${playResult.failureOrNull}'),
          );
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Unexpected error during playback: $e'));
    }
  }
}

/// Parameters for the PlayTrackUseCase
class PlayTrackParams extends Params {
  const PlayTrackParams({
    required this.track,
    this.queue,
    this.startIndex,
    this.useBestSource = true,
    this.allowFallback = true,
  });

  /// The track to play
  final Track track;

  /// Optional queue to set before playing
  final List<Track>? queue;

  /// Starting index in the queue (if queue is provided)
  final int? startIndex;

  /// Whether to automatically select the best source for deduplicated tracks
  final bool useBestSource;

  /// Whether to allow fallback to alternative sources if primary fails
  final bool allowFallback;

  @override
  List<Object?> get props => [
    track,
    queue,
    startIndex,
    useBestSource,
    allowFallback,
  ];
}
