import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../entities/entities.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../repositories/repositories.dart';
import 'usecase.dart';

/// Use case for managing playlist operations
///
/// This use case handles:
/// - Creating, updating, and deleting playlists
/// - Adding and removing tracks from playlists
/// - Reordering tracks within playlists
/// - Managing playlist metadata and settings
@injectable
class ManagePlaylistUseCase
    implements UseCase<PlaylistOperationResult, ManagePlaylistParams> {
  const ManagePlaylistUseCase(this._playlistRepository, this._musicRepository);

  final PlaylistRepository _playlistRepository;
  final MusicRepository _musicRepository;

  @override
  Future<Either<Failure, PlaylistOperationResult>> call(
    ManagePlaylistParams params,
  ) async {
    try {
      switch (params.operation) {
        case PlaylistOperation.create:
          return await _createPlaylist(params);
        case PlaylistOperation.update:
          return await _updatePlaylist(params);
        case PlaylistOperation.delete:
          return await _deletePlaylist(params);
        case PlaylistOperation.addTrack:
          return await _addTrack(params);
        case PlaylistOperation.removeTrack:
          return await _removeTrack(params);
        case PlaylistOperation.reorderTracks:
          return await _reorderTracks(params);
        case PlaylistOperation.moveTrack:
          return await _moveTrack(params);
        case PlaylistOperation.duplicate:
          return await _duplicatePlaylist(params);
        case PlaylistOperation.export:
          return await _exportPlaylist(params);
        case PlaylistOperation.import:
          return await _importPlaylist(params);
      }
    } catch (e) {
      return Left(
        UnknownFailure('Unexpected error during playlist operation: $e'),
      );
    }
  }

  Future<Either<Failure, PlaylistOperationResult>> _createPlaylist(
    ManagePlaylistParams params,
  ) async {
    if (params.name == null || params.name!.trim().isEmpty) {
      return Left(ValidationFailure('Playlist name is required'));
    }

    final result = await _playlistRepository.createPlaylist(
      name: params.name!,
      description: params.description,
      isPublic: params.isPublic ?? false,
    );

    if (result.isFailure) {
      return Left(
        DataFailure('Failed to create playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Playlist "${result.valueOrNull!.name}" created successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _updatePlaylist(
    ManagePlaylistParams params,
  ) async {
    if (params.playlist == null) {
      return Left(
        ValidationFailure('Playlist is required for update operation'),
      );
    }

    final result = await _playlistRepository.updatePlaylist(params.playlist!);
    if (result.isFailure) {
      return Left(
        DataFailure('Failed to update playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Playlist updated successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _deletePlaylist(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null) {
      return Left(
        ValidationFailure('Playlist ID is required for delete operation'),
      );
    }

    final result = await _playlistRepository.deletePlaylist(params.playlistId!);
    if (result.isFailure) {
      return Left(
        DataFailure('Failed to delete playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(message: 'Playlist deleted successfully'),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _addTrack(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null || params.trackId == null) {
      return Left(
        ValidationFailure(
          'Playlist ID and track ID are required for add track operation',
        ),
      );
    }

    // Verify the track exists
    final tracksResult = await _musicRepository.getAllTracks();
    if (tracksResult.isFailure) {
      return Left(
        DataFailure(
          'Failed to verify track existence: ${tracksResult.failureOrNull}',
        ),
      );
    }

    final trackExists = tracksResult.valueOrNull!.any(
      (track) => track.id == params.trackId,
    );
    if (!trackExists) {
      return Left(ValidationFailure('Track not found: ${params.trackId}'));
    }

    final result = await _playlistRepository.addTrackToPlaylist(
      params.playlistId!,
      params.trackId!,
    );
    if (result.isFailure) {
      return Left(
        DataFailure('Failed to add track to playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Track added to playlist successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _removeTrack(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null || params.trackId == null) {
      return Left(
        ValidationFailure(
          'Playlist ID and track ID are required for remove track operation',
        ),
      );
    }

    final result = await _playlistRepository.removeTrackFromPlaylist(
      params.playlistId!,
      params.trackId!,
    );
    if (result.isFailure) {
      return Left(
        DataFailure(
          'Failed to remove track from playlist: ${result.failureOrNull}',
        ),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Track removed from playlist successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _reorderTracks(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null || params.trackIds == null) {
      return Left(
        ValidationFailure(
          'Playlist ID and track IDs are required for reorder operation',
        ),
      );
    }

    final result = await _playlistRepository.reorderPlaylistTracks(
      params.playlistId!,
      params.trackIds!,
    );
    if (result.isFailure) {
      return Left(
        DataFailure(
          'Failed to reorder playlist tracks: ${result.failureOrNull}',
        ),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Playlist tracks reordered successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _moveTrack(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null ||
        params.fromIndex == null ||
        params.toIndex == null) {
      return Left(
        ValidationFailure(
          'Playlist ID, from index, and to index are required for move operation',
        ),
      );
    }

    final result = await _playlistRepository.moveTrackInPlaylist(
      params.playlistId!,
      params.fromIndex!,
      params.toIndex!,
    );
    if (result.isFailure) {
      return Left(
        DataFailure(
          'Failed to move track in playlist: ${result.failureOrNull}',
        ),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Track moved successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _duplicatePlaylist(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null || params.name == null) {
      return Left(
        ValidationFailure(
          'Playlist ID and new name are required for duplicate operation',
        ),
      );
    }

    final result = await _playlistRepository.duplicatePlaylist(
      params.playlistId!,
      params.name!,
    );
    if (result.isFailure) {
      return Left(
        DataFailure('Failed to duplicate playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Playlist duplicated successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _exportPlaylist(
    ManagePlaylistParams params,
  ) async {
    if (params.playlistId == null) {
      return Left(
        ValidationFailure('Playlist ID is required for export operation'),
      );
    }

    final result = await _playlistRepository.exportPlaylist(
      params.playlistId!,
      format: params.exportFormat ?? 'm3u',
    );
    if (result.isFailure) {
      return Left(
        DataFailure('Failed to export playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        exportData: result.valueOrNull!,
        message: 'Playlist exported successfully',
      ),
    );
  }

  Future<Either<Failure, PlaylistOperationResult>> _importPlaylist(
    ManagePlaylistParams params,
  ) async {
    if (params.importData == null || params.name == null) {
      return Left(
        ValidationFailure(
          'Import data and name are required for import operation',
        ),
      );
    }

    final result = await _playlistRepository.importPlaylist(
      params.importData!,
      params.importFormat ?? 'm3u',
      params.name!,
    );
    if (result.isFailure) {
      return Left(
        DataFailure('Failed to import playlist: ${result.failureOrNull}'),
      );
    }

    return Right(
      PlaylistOperationResult.success(
        playlist: result.valueOrNull!,
        message: 'Playlist imported successfully',
      ),
    );
  }
}

/// Parameters for the ManagePlaylistUseCase
class ManagePlaylistParams extends Params {
  const ManagePlaylistParams({
    required this.operation,
    this.playlistId,
    this.playlist,
    this.name,
    this.description,
    this.isPublic,
    this.trackId,
    this.trackIds,
    this.fromIndex,
    this.toIndex,
    this.exportFormat,
    this.importFormat,
    this.importData,
  });

  final PlaylistOperation operation;
  final String? playlistId;
  final Playlist? playlist;
  final String? name;
  final String? description;
  final bool? isPublic;
  final String? trackId;
  final List<String>? trackIds;
  final int? fromIndex;
  final int? toIndex;
  final String? exportFormat;
  final String? importFormat;
  final String? importData;

  @override
  List<Object?> get props => [
    operation,
    playlistId,
    playlist,
    name,
    description,
    isPublic,
    trackId,
    trackIds,
    fromIndex,
    toIndex,
    exportFormat,
    importFormat,
    importData,
  ];
}

/// Types of playlist operations
enum PlaylistOperation {
  create,
  update,
  delete,
  addTrack,
  removeTrack,
  reorderTracks,
  moveTrack,
  duplicate,
  export,
  import,
}

/// Result of a playlist operation
class PlaylistOperationResult {
  const PlaylistOperationResult({
    required this.isSuccess,
    this.playlist,
    this.message,
    this.exportData,
  });

  const PlaylistOperationResult.success({
    this.playlist,
    this.message,
    this.exportData,
  }) : isSuccess = true;

  const PlaylistOperationResult.failure({required this.message})
    : isSuccess = false,
      playlist = null,
      exportData = null;

  final bool isSuccess;
  final Playlist? playlist;
  final String? message;
  final String? exportData;

  bool get isFailure => !isSuccess;
}
