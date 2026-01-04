import '../daos/cache_dao.dart';
import '../../entities/entities.dart';
import '../../errors/errors.dart';

/// Local data source for offline content management
class OfflineLocalDataSource {
  OfflineLocalDataSource({
    required CacheDao cacheDao,
  }) : _cacheDao = cacheDao;

  final CacheDao _cacheDao;

  /// Gets all cached entries
  Future<Result<List<CacheEntry>>> getAllCachedEntries() async {
    try {
      final entries = await _cacheDao.getAllCacheEntries();
      return ResultHelper.success(entries);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get cached entries: $e'));
    }
  }

  /// Gets a cached entry by track ID
  Future<Result<CacheEntry?>> getCachedEntry(String trackId) async {
    try {
      final entry = await _cacheDao.getCacheEntryByTrackId(trackId);
      return ResultHelper.success(entry);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get cached entry: $e'));
    }
  }

  /// Saves a cache entry
  Future<Result<void>> saveCacheEntry(CacheEntry entry) async {
    try {
      await _cacheDao.insertCacheEntry(entry);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to save cache entry: $e'));
    }
  }

  /// Updates a cache entry
  Future<Result<void>> updateCacheEntry(CacheEntry entry) async {
    try {
      await _cacheDao.updateCacheEntry(entry);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to update cache entry: $e'));
    }
  }

  /// Removes a cached entry
  Future<Result<void>> removeCacheEntry(String trackId) async {
    try {
      await _cacheDao.deleteCacheEntry(trackId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to remove cache entry: $e'));
    }
  }

  /// Removes multiple cached entries
  Future<Result<void>> removeCacheEntries(List<String> trackIds) async {
    try {
      await _cacheDao.deleteCacheEntries(trackIds);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to remove cache entries: $e'));
    }
  }

  /// Gets cache statistics
  Future<Result<Map<String, int>>> getCacheStatistics() async {
    try {
      final totalSize = await _cacheDao.getTotalCacheSize();
      final pinnedSize = await _cacheDao.getPinnedCacheSize();
      final fileCount = await _cacheDao.getCacheEntryCount();
      final pinnedFileCount = await _cacheDao.getPinnedCacheEntryCount();

      return ResultHelper.success({
        'totalSize': totalSize,
        'pinnedSize': pinnedSize,
        'fileCount': fileCount,
        'pinnedFileCount': pinnedFileCount,
      });
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get cache statistics: $e'));
    }
  }

  /// Gets entries for eviction (unpinned, ordered by strategy)
  Future<Result<List<CacheEntry>>> getEntriesForEviction({
    required int limit,
    bool oldestFirst = true,
  }) async {
    try {
      List<CacheEntry> entries;
      
      if (oldestFirst) {
        entries = await _cacheDao.getLeastRecentlyAccessedEntries(limit);
      } else {
        entries = await _cacheDao.getLargestCacheEntries(limit);
      }

      // Filter out pinned entries
      final unpinnedEntries = entries.where((e) => !e.isPinned).toList();
      
      return ResultHelper.success(unpinnedEntries);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get entries for eviction: $e'));
    }
  }

  /// Updates last accessed time
  Future<Result<void>> updateLastAccessed(String trackId) async {
    try {
      await _cacheDao.updateCacheEntryLastAccessed(trackId, DateTime.now());
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to update last accessed: $e'));
    }
  }

  /// Pins a track
  Future<Result<void>> pinTrack(String trackId) async {
    try {
      await _cacheDao.updateCacheEntryPinned(trackId, true);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to pin track: $e'));
    }
  }

  /// Unpins a track
  Future<Result<void>> unpinTrack(String trackId) async {
    try {
      await _cacheDao.updateCacheEntryPinned(trackId, false);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to unpin track: $e'));
    }
  }

  /// Gets all pinned tracks
  Future<Result<List<CacheEntry>>> getPinnedTracks() async {
    try {
      final entries = await _cacheDao.getPinnedCacheEntries();
      return ResultHelper.success(entries);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get pinned tracks: $e'));
    }
  }

  /// Gets cached tracks by server (requires joining with tracks table)
  Future<Result<List<CacheEntry>>> getCachedTracksByServer(String serverId) async {
    try {
      // This would require a join query - for now, get all and filter
      // In a real implementation, you'd want to add a proper join query to the DAO
      final allEntries = await _cacheDao.getAllCacheEntries();
      
      // Note: This is a simplified implementation
      // In practice, you'd want to join with the tracks table to filter by serverId
      return ResultHelper.success(allEntries);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get cached tracks by server: $e'));
    }
  }

  /// Clears incomplete downloads
  Future<Result<void>> clearIncompleteDownloads() async {
    try {
      await _cacheDao.deleteIncompleteCacheEntries();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to clear incomplete downloads: $e'));
    }
  }

  /// Watches cache statistics
  Stream<Map<String, int>> watchCacheStatistics() {
    return _cacheDao.watchTotalCacheSize().asyncMap((totalSize) async {
      final pinnedSize = await _cacheDao.getPinnedCacheSize();
      final fileCount = await _cacheDao.getCacheEntryCount();
      final pinnedFileCount = await _cacheDao.getPinnedCacheEntryCount();

      return {
        'totalSize': totalSize,
        'pinnedSize': pinnedSize,
        'fileCount': fileCount,
        'pinnedFileCount': pinnedFileCount,
      };
    });
  }

  /// Watches all cache entries
  Stream<List<CacheEntry>> watchAllCacheEntries() {
    return _cacheDao.watchAllCacheEntries();
  }

  /// Watches a specific cache entry
  Stream<CacheEntry?> watchCacheEntry(String trackId) {
    return _cacheDao.watchCacheEntryByTrackId(trackId);
  }
}