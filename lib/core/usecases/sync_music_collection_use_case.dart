import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../errors/failures.dart';
import '../errors/result.dart';
import '../repositories/repositories.dart';
import 'usecase.dart';

/// Use case for synchronizing music collection metadata from all connected servers
///
/// This use case handles:
/// - Fetching metadata from all connected servers
/// - Running deduplication algorithm on the collected data
/// - Updating the unified collection
/// - Notifying observers of changes
@injectable
class SyncMusicCollectionUseCase
    implements UseCase<UnifiedCollection, SyncMusicCollectionParams> {
  const SyncMusicCollectionUseCase(
    this._musicRepository,
    this._serverRepository,
  );

  final MusicRepository _musicRepository;
  final ServerRepository _serverRepository;

  @override
  Future<Either<Failure, UnifiedCollection>> call(
    SyncMusicCollectionParams params,
  ) async {
    try {
      // Get all online servers first
      final serversResult = await _serverRepository.getOnlineServers();
      if (serversResult.isFailure) {
        return Left(
          ServerFailure(
            'Failed to get online servers: ${serversResult.failureOrNull}',
          ),
        );
      }

      final onlineServers = serversResult.valueOrNull!;
      if (onlineServers.isEmpty) {
        return Left(
          ServerFailure('No online servers available for synchronization'),
        );
      }

      // Sync from all servers or specific server if provided
      if (params.serverId != null) {
        // Sync from specific server
        final syncResult = await _musicRepository.syncFromServer(
          params.serverId!,
        );
        if (syncResult.isFailure) {
          return Left(
            SyncFailure(
              'Failed to sync from server ${params.serverId}: ${syncResult.failureOrNull}',
            ),
          );
        }
      } else {
        // Sync from all servers
        final syncResult = await _musicRepository.syncFromServers();
        if (syncResult.isFailure) {
          return Left(
            SyncFailure(
              'Failed to sync from servers: ${syncResult.failureOrNull}',
            ),
          );
        }
      }

      // The repository rebuilds and publishes the unified collection at the
      // end of a sync, so read that instead of materialising the whole library
      // into Dart lists a second time.
      final unifiedCollection = await _musicRepository.observeCollection().first;

      return Right(unifiedCollection);
    } catch (e) {
      return Left(UnknownFailure('Unexpected error during sync: $e'));
    }
  }
}

/// Parameters for the SyncMusicCollectionUseCase
class SyncMusicCollectionParams extends Params {
  const SyncMusicCollectionParams({this.serverId, this.forceRefresh = false});

  /// Optional server ID to sync from specific server only
  final String? serverId;

  /// Whether to force a complete refresh ignoring cache
  final bool forceRefresh;

  @override
  List<Object?> get props => [serverId, forceRefresh];
}
