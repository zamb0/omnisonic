import 'dart:async';
import 'package:rxdart/rxdart.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/offline_repository.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../core/services/cache_manager.dart';
import '../../../../core/database/data_sources/offline_local_data_source.dart';

/// Implementation of offline repository
class OfflineRepositoryImpl implements OfflineRepository {
  OfflineRepositoryImpl({
    required DownloadManager downloadManager,
    required CacheManager cacheManager,
    required OfflineLocalDataSource localDataSource,
  })  : _downloadManager = downloadManager,
        _cacheManager = cacheManager,
        _localDataSource = localDataSource;

  final DownloadManager _downloadManager;
  final CacheManager _cacheManager;
  final OfflineLocalDataSource _localDataSource;

  final _downloadProgressController = BehaviorSubject<Map<String, double>>();
  final _cacheStatsController = BehaviorSubject<CacheStats>();

  @override
  Future<Result<CacheEntry>> downloadTrack(
    Track track, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if we can accommodate the download
      final canAccommodateResult = await canAccommodateDownload(
        track.fileSize ?? 10 * 1024 * 1024, // Default 10MB if size unknown
      );
      
      if (canAccommodateResult.isFailure) {
        return ResultHelper.failure(canAccommodateResult.failureOrNull!);
      }

      if (!canAccommodateResult.valueOrNull!) {
        // Try to free up space
        final cleanupResult = await performCacheCleanup();
        if (cleanupResult.isFailure) {
          return ResultHelper.failure(CacheFailure('Cannot accommodate download and cleanup failed'));
        }
      }

      // Start download with progress tracking
      final downloadResult = await _downloadManager.downloadTrack(
        track,
        onProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          _updateDownloadProgress(track.id, progress);
          onProgress?.call(received, total);
        },
      );

      if (downloadResult.isFailure) {
        _removeDownloadProgress(track.id);
        return ResultHelper.failure(downloadResult.failureOrNull!);
      }

      final cacheEntry = downloadResult.valueOrNull!;

      // Save to database
      final saveResult = await _localDataSource.saveCacheEntry(cacheEntry);
      if (saveResult.isFailure) {
        // Clean up downloaded file if database save fails
        await _downloadManager.deleteCachedFile(cacheEntry.filePath);
        _removeDownloadProgress(track.id);
        return ResultHelper.failure(saveResult.failureOrNull!);
      }

      _removeDownloadProgress(track.id);
      await _updateCacheStats();

      return ResultHelper.success(cacheEntry);
    } catch (e) {
      _removeDownloadProgress(track.id);
      return ResultHelper.failure(UnknownFailure('Download failed: $e'));
    }
  }

  @override
  Future<Result<void>> cancelDownload(String trackId) async {
    final result = await _downloadManager.cancelDownload(trackId);
    if (result.isSuccess) {
      _removeDownloadProgress(trackId);
    }
    return result;
  }

  @override
  Future<Result<List<CacheEntry>>> getAllCachedEntries() async {
    return await _localDataSource.getAllCachedEntries();
  }

  @override
  Future<Result<CacheEntry?>> getCachedEntry(String trackId) async {
    return await _localDataSource.getCachedEntry(trackId);
  }

  @override
  Future<Result<void>> removeCachedTrack(String trackId) async {
    try {
      // Get cache entry first
      final entryResult = await _localDataSource.getCachedEntry(trackId);
      if (entryResult.isFailure) return ResultHelper.failure(entryResult.failureOrNull!);

      final entry = entryResult.valueOrNull;
      if (entry != null) {
        // Delete file
        await _downloadManager.deleteCachedFile(entry.filePath);
      }

      // Remove from database
      final removeResult = await _localDataSource.removeCacheEntry(trackId);
      if (removeResult.isFailure) return ResultHelper.failure(removeResult.failureOrNull!);

      await _updateCacheStats();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to remove cached track: $e'));
    }
  }

  @override
  Future<Result<void>> removeCachedTracks(List<String> trackIds) async {
    try {
      // Get all entries first
      final entriesResult = await _localDataSource.getAllCachedEntries();
      if (entriesResult.isFailure) return ResultHelper.failure(entriesResult.failureOrNull!);

      final allEntries = entriesResult.valueOrNull!;
      final entriesToRemove = allEntries.where((e) => trackIds.contains(e.trackId));

      // Delete files
      for (final entry in entriesToRemove) {
        await _downloadManager.deleteCachedFile(entry.filePath);
      }

      // Remove from database
      final removeResult = await _localDataSource.removeCacheEntries(trackIds);
      if (removeResult.isFailure) return ResultHelper.failure(removeResult.failureOrNull!);

      await _updateCacheStats();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to remove cached tracks: $e'));
    }
  }

  @override
  Future<Result<CacheStats>> getCacheStats() async {
    try {
      final entriesResult = await _localDataSource.getAllCachedEntries();
      if (entriesResult.isFailure) return ResultHelper.failure(entriesResult.failureOrNull!);

      final entries = entriesResult.valueOrNull!;
      return await _cacheManager.getCacheStats(entries);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get cache stats: $e'));
    }
  }

  @override
  Future<Result<int>> performCacheCleanup({int? targetFreeSpace}) async {
    try {
      final entriesResult = await _localDataSource.getAllCachedEntries();
      if (entriesResult.isFailure) return ResultHelper.failure(entriesResult.failureOrNull!);

      final entries = entriesResult.valueOrNull!;
      
      // Select entries for eviction
      final evictionResult = await _cacheManager.selectEntriesForEviction(
        entries,
        targetFreeSpace ?? (2 * 1024 * 1024 * 1024 * 0.3).round(), // 30% of 2GB
      );
      
      if (evictionResult.isFailure) return ResultHelper.failure(evictionResult.failureOrNull!);

      final toEvict = evictionResult.valueOrNull!;
      final trackIds = toEvict.map((e) => e.trackId).toList();

      // Remove the selected entries
      final removeResult = await removeCachedTracks(trackIds);
      if (removeResult.isFailure) return ResultHelper.failure(removeResult.failureOrNull!);

      final freedSpace = toEvict.fold<int>(0, (sum, entry) => sum + entry.fileSize);
      await _updateCacheStats();

      return ResultHelper.success(freedSpace);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to perform cache cleanup: $e'));
    }
  }

  @override
  Future<Result<List<String>>> validateCacheIntegrity() async {
    try {
      final entriesResult = await _localDataSource.getAllCachedEntries();
      if (entriesResult.isFailure) return ResultHelper.failure(entriesResult.failureOrNull!);

      final entries = entriesResult.valueOrNull!;
      return await _cacheManager.validateCacheIntegrity(entries);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to validate cache integrity: $e'));
    }
  }

  @override
  Future<Result<bool>> isTrackCached(String trackId) async {
    final entryResult = await _localDataSource.getCachedEntry(trackId);
    if (entryResult.isFailure) return ResultHelper.failure(entryResult.failureOrNull!);

    final entry = entryResult.valueOrNull;
    if (entry == null) return ResultHelper.success(false);

    // Verify file exists and is complete
    final verifyResult = await _downloadManager.verifyCachedFile(entry);
    if (verifyResult.isFailure) return ResultHelper.failure(verifyResult.failureOrNull!);

    return ResultHelper.success(verifyResult.valueOrNull!);
  }

  @override
  bool isTrackDownloading(String trackId) {
    return _downloadManager.isDownloading(trackId);
  }

  @override
  List<String> getActiveDownloads() {
    return _downloadManager.activeDownloads;
  }

  @override
  Future<Result<void>> pinTrack(String trackId) async {
    final result = await _localDataSource.pinTrack(trackId);
    if (result.isSuccess) {
      await _updateCacheStats();
    }
    return result;
  }

  @override
  Future<Result<void>> unpinTrack(String trackId) async {
    final result = await _localDataSource.unpinTrack(trackId);
    if (result.isSuccess) {
      await _updateCacheStats();
    }
    return result;
  }

  @override
  Future<Result<List<CacheEntry>>> getPinnedTracks() async {
    return await _localDataSource.getPinnedTracks();
  }

  @override
  Future<Result<bool>> canAccommodateDownload(int downloadSize) async {
    try {
      final entriesResult = await _localDataSource.getAllCachedEntries();
      if (entriesResult.isFailure) return ResultHelper.failure(entriesResult.failureOrNull!);

      final entries = entriesResult.valueOrNull!;
      return await _cacheManager.canAccommodateDownload(entries, downloadSize);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to check download accommodation: $e'));
    }
  }

  @override
  Future<Result<void>> updateLastAccessed(String trackId) async {
    return await _localDataSource.updateLastAccessed(trackId);
  }

  @override
  Future<Result<List<CacheEntry>>> getCachedTracksByServer(String serverId) async {
    return await _localDataSource.getCachedTracksByServer(serverId);
  }

  @override
  Future<Result<void>> removeCachedTracksFromServer(String serverId) async {
    try {
      final entriesResult = await getCachedTracksByServer(serverId);
      if (entriesResult.isFailure) return ResultHelper.failure(entriesResult.failureOrNull!);

      final entries = entriesResult.valueOrNull!;
      final trackIds = entries.map((e) => e.trackId).toList();

      return await removeCachedTracks(trackIds);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to remove cached tracks from server: $e'));
    }
  }

  @override
  Stream<CacheStats> observeCacheStats() {
    return _cacheStatsController.stream;
  }

  @override
  Stream<Map<String, double>> observeDownloadProgress() {
    return _downloadProgressController.stream;
  }

  /// Updates download progress
  void _updateDownloadProgress(String trackId, double progress) {
    final currentProgress = _downloadProgressController.valueOrNull ?? <String, double>{};
    currentProgress[trackId] = progress;
    _downloadProgressController.add(Map.from(currentProgress));
  }

  /// Removes download progress
  void _removeDownloadProgress(String trackId) {
    final currentProgress = _downloadProgressController.valueOrNull ?? <String, double>{};
    currentProgress.remove(trackId);
    _downloadProgressController.add(Map.from(currentProgress));
  }

  /// Updates cache statistics
  Future<void> _updateCacheStats() async {
    final statsResult = await getCacheStats();
    if (statsResult.isSuccess) {
      _cacheStatsController.add(statsResult.valueOrNull!);
    }
  }

  /// Disposes the repository
  void dispose() {
    _downloadProgressController.close();
    _cacheStatsController.close();
    _downloadManager.dispose();
  }
}