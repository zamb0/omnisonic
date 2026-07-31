import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/offline_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// Parameters for downloading a track
class DownloadTrackParams {
  const DownloadTrackParams({required this.track, this.onProgress});

  final Track track;
  final void Function(int received, int total)? onProgress;
}

/// Use case for downloading a track for offline use
class DownloadTrackUseCase implements UseCase<CacheEntry, DownloadTrackParams> {
  DownloadTrackUseCase({required OfflineRepository offlineRepository})
    : _offlineRepository = offlineRepository;

  final OfflineRepository _offlineRepository;

  @override
  Future<Result<CacheEntry>> call(DownloadTrackParams params) async {
    // Validate track
    if (!params.track.isValid) {
      return ResultHelper.failure(ValidationFailure('Invalid track data'));
    }

    // Check if already cached
    final isCachedResult = await _offlineRepository.isTrackCached(
      params.track.id,
    );
    if (isCachedResult.isFailure) {
      return ResultHelper.failure(isCachedResult.failureOrNull!);
    }

    if (isCachedResult.valueOrNull!) {
      // Already cached, get the entry
      final entryResult = await _offlineRepository.getCachedEntry(
        params.track.id,
      );
      if (entryResult.isFailure) {
        return ResultHelper.failure(entryResult.failureOrNull!);
      }

      final entry = entryResult.valueOrNull;
      if (entry != null) {
        return ResultHelper.success(entry);
      }
    }

    // Check if already downloading
    if (_offlineRepository.isTrackDownloading(params.track.id)) {
      return ResultHelper.failure(
        CacheFailure('Track is already being downloaded'),
      );
    }

    // Start download
    return await _offlineRepository.downloadTrack(
      params.track,
      onProgress: params.onProgress,
    );
  }
}
