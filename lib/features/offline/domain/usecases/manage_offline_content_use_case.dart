import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/offline_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// Parameters for managing offline content
class ManageOfflineContentParams {
  const ManageOfflineContentParams({
    required this.action,
    this.trackIds,
    this.targetFreeSpace,
  });

  final OfflineContentAction action;
  final List<String>? trackIds;
  final int? targetFreeSpace;
}

/// Actions for offline content management
enum OfflineContentAction {
  cleanup,
  validateIntegrity,
  removeSelected,
  clearIncomplete,
}

/// Use case for managing offline content
class ManageOfflineContentUseCase
    implements UseCase<dynamic, ManageOfflineContentParams> {
  ManageOfflineContentUseCase({required OfflineRepository offlineRepository})
    : _offlineRepository = offlineRepository;

  final OfflineRepository _offlineRepository;

  @override
  Future<Result<dynamic>> call(ManageOfflineContentParams params) async {
    switch (params.action) {
      case OfflineContentAction.cleanup:
        return await _performCleanup(params.targetFreeSpace);

      case OfflineContentAction.validateIntegrity:
        return await _validateIntegrity();

      case OfflineContentAction.removeSelected:
        if (params.trackIds == null || params.trackIds!.isEmpty) {
          return ResultHelper.failure(
            ValidationFailure('Track IDs required for remove action'),
          );
        }
        return await _removeSelected(params.trackIds!);

      case OfflineContentAction.clearIncomplete:
        return await _clearIncomplete();
    }
  }

  /// Performs cache cleanup
  Future<Result<int>> _performCleanup(int? targetFreeSpace) async {
    try {
      return await _offlineRepository.performCacheCleanup(
        targetFreeSpace: targetFreeSpace,
      );
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Cleanup failed: $e'));
    }
  }

  /// Validates cache integrity
  Future<Result<List<String>>> _validateIntegrity() async {
    try {
      return await _offlineRepository.validateCacheIntegrity();
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Integrity validation failed: $e'),
      );
    }
  }

  /// Removes selected tracks
  Future<Result<void>> _removeSelected(List<String> trackIds) async {
    try {
      return await _offlineRepository.removeCachedTracks(trackIds);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to remove selected tracks: $e'),
      );
    }
  }

  /// Clears incomplete downloads
  Future<Result<void>> _clearIncomplete() async {
    try {
      // Get all cached entries
      final entriesResult = await _offlineRepository.getAllCachedEntries();
      if (entriesResult.isFailure) {
        return ResultHelper.failure(entriesResult.failureOrNull!);
      }

      final entries = entriesResult.valueOrNull!;
      final incompleteIds = entries
          .where((entry) => !entry.isComplete)
          .map((entry) => entry.trackId)
          .toList();

      if (incompleteIds.isEmpty) {
        return ResultHelper.success(null);
      }

      return await _offlineRepository.removeCachedTracks(incompleteIds);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to clear incomplete downloads: $e'),
      );
    }
  }
}
