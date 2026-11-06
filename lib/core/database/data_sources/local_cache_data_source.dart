import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../app_database.dart';
import '../../entities/cache_entry.dart';
import '../../errors/result.dart';
import '../../errors/failures.dart';
import '../../utils/web_support.dart';

/// Local data source for cache operations and offline content management
class LocalCacheDataSource {
  const LocalCacheDataSource(this._database);

  final AppDatabase _database;

  /// Get all cache entries
  Future<Result<List<CacheEntry>>> getAllCacheEntries() async {
    try {
      final entries = await _database.cacheDao.getAllCacheEntries();
      return ResultHelper.success(entries);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get cache entries: $e'),
      );
    }
  }

  /// Get cache entry by track ID
  Future<Result<CacheEntry?>> getCacheEntryByTrackId(String trackId) async {
    try {
      final entry = await _database.cacheDao.getCacheEntryByTrackId(trackId);
      return ResultHelper.success(entry);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get cache entry: $e'),
      );
    }
  }

  /// Get complete cache entries (fully downloaded)
  Future<Result<List<CacheEntry>>> getCompleteCacheEntries() async {
    try {
      final entries = await _database.cacheDao.getCompleteCacheEntries();
      return ResultHelper.success(entries);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get complete cache entries: $e'),
      );
    }
  }

  /// Get incomplete cache entries (partially downloaded)
  Future<Result<List<CacheEntry>>> getIncompleteCacheEntries() async {
    try {
      final entries = await _database.cacheDao.getIncompleteCacheEntries();
      return ResultHelper.success(entries);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get incomplete cache entries: $e'),
      );
    }
  }

  /// Insert cache entry
  Future<Result<void>> insertCacheEntry(CacheEntry entry) async {
    try {
      await _database.cacheDao.insertCacheEntry(entry);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert cache entry: $e'),
      );
    }
  }

  /// Update cache entry
  Future<Result<void>> updateCacheEntry(CacheEntry entry) async {
    try {
      await _database.cacheDao.updateCacheEntry(entry);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update cache entry: $e'),
      );
    }
  }

  /// Update cache entry last accessed time
  Future<Result<void>> updateCacheEntryLastAccessed(String trackId) async {
    try {
      await _database.cacheDao.updateCacheEntryLastAccessed(
        trackId,
        DateTime.now(),
      );
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update cache entry access time: $e'),
      );
    }
  }

  /// Mark cache entry as complete
  Future<Result<void>> markCacheEntryComplete(String trackId) async {
    try {
      await _database.cacheDao.updateCacheEntryCompletion(trackId, true);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to mark cache entry complete: $e'),
      );
    }
  }

  /// Delete cache entry
  Future<Result<void>> deleteCacheEntry(String trackId) async {
    try {
      // Get the cache entry to find the file path
      final entry = await _database.cacheDao.getCacheEntryByTrackId(trackId);

      // Delete the physical file if it exists
      if (entry != null) {
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete the database entry
      await _database.cacheDao.deleteCacheEntry(trackId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete cache entry: $e'),
      );
    }
  }

  /// Delete multiple cache entries
  Future<Result<void>> deleteCacheEntries(List<String> trackIds) async {
    try {
      // Get all cache entries to find file paths
      final entries = await _database.cacheDao.getAllCacheEntries();
      final wanted = trackIds.toSet();
      final entriesToDelete = entries.where(
        (entry) => wanted.contains(entry.trackId),
      );

      // Delete physical files
      for (final entry in entriesToDelete) {
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete database entries
      await _database.cacheDao.deleteCacheEntries(trackIds);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete cache entries: $e'),
      );
    }
  }

  /// Get total cache size in bytes
  Future<Result<int>> getTotalCacheSize() async {
    try {
      final size = await _database.cacheDao.getTotalCacheSize();
      return ResultHelper.success(size);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get total cache size: $e'),
      );
    }
  }

  /// Get cache entry count
  Future<Result<int>> getCacheEntryCount() async {
    try {
      final count = await _database.cacheDao.getCacheEntryCount();
      return ResultHelper.success(count);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get cache entry count: $e'),
      );
    }
  }

  /// Get cache statistics
  Future<Result<Map<String, dynamic>>> getCacheStats() async {
    try {
      final totalSize = await _database.cacheDao.getTotalCacheSize();
      final totalCount = await _database.cacheDao.getCacheEntryCount();
      final completeEntries = await _database.cacheDao
          .getCompleteCacheEntries();
      final incompleteEntries = await _database.cacheDao
          .getIncompleteCacheEntries();

      final stats = {
        'totalSize': totalSize,
        'totalCount': totalCount,
        'completeCount': completeEntries.length,
        'incompleteCount': incompleteEntries.length,
        'averageFileSize': totalCount > 0 ? totalSize / totalCount : 0,
        'completionRate': totalCount > 0
            ? completeEntries.length / totalCount
            : 0.0,
      };

      return ResultHelper.success(stats);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get cache stats: $e'),
      );
    }
  }

  /// Clean up cache based on size limit
  Future<Result<void>> cleanupCacheBySize(int maxSizeBytes) async {
    try {
      final currentSize = await _database.cacheDao.getTotalCacheSize();

      if (currentSize <= maxSizeBytes) {
        return ResultHelper.success(null); // No cleanup needed
      }

      final sizeToFree = currentSize - maxSizeBytes;
      int freedSize = 0;

      // Get least recently accessed entries
      final entries = await _database.cacheDao.getLeastRecentlyAccessedEntries(
        1000,
      );

      for (final entry in entries) {
        if (freedSize >= sizeToFree) break;

        await deleteCacheEntry(entry.trackId);
        freedSize += entry.fileSize;
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to cleanup cache by size: $e'),
      );
    }
  }

  /// Clean up cache based on age
  Future<Result<void>> cleanupCacheByAge(Duration maxAge) async {
    try {
      final cutoffDate = DateTime.now().subtract(maxAge);
      await _database.cacheDao.deleteOldCacheEntries(cutoffDate);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to cleanup cache by age: $e'),
      );
    }
  }

  /// Clean up incomplete cache entries
  Future<Result<void>> cleanupIncompleteCacheEntries() async {
    try {
      final incompleteEntries = await _database.cacheDao
          .getIncompleteCacheEntries();

      // Delete physical files for incomplete entries
      for (final entry in incompleteEntries) {
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await _database.cacheDao.deleteIncompleteCacheEntries();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to cleanup incomplete cache entries: $e'),
      );
    }
  }

  /// Clear all cache entries and files
  Future<Result<void>> clearAllCache() async {
    try {
      // Get all entries to delete physical files
      final entries = await _database.cacheDao.getAllCacheEntries();

      // Delete all physical files
      for (final entry in entries) {
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear database entries
      await _database.cacheDao.clearAllCacheEntries();
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to clear all cache: $e'),
      );
    }
  }

  /// Check if track is cached and file exists
  Future<Result<bool>> isTrackCached(String trackId) async {
    try {
      final entry = await _database.cacheDao.getCacheEntryByTrackId(trackId);
      if (entry == null || !entry.isComplete) {
        return ResultHelper.success(false);
      }

      final file = File(entry.filePath);
      final exists = await file.exists();

      // If database says it's cached but file doesn't exist, clean up the entry
      if (!exists) {
        await _database.cacheDao.deleteCacheEntry(trackId);
        return ResultHelper.success(false);
      }

      return ResultHelper.success(true);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to check if track is cached: $e'),
      );
    }
  }

  /// Get cache file path for track
  Future<Result<String?>> getCacheFilePath(String trackId) async {
    try {
      final entry = await _database.cacheDao.getCacheEntryByTrackId(trackId);
      if (entry == null || !entry.isComplete) {
        return ResultHelper.success(null);
      }

      final file = File(entry.filePath);
      if (await file.exists()) {
        return ResultHelper.success(entry.filePath);
      } else {
        // Clean up stale entry
        await _database.cacheDao.deleteCacheEntry(trackId);
        return ResultHelper.success(null);
      }
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get cache file path: $e'),
      );
    }
  }

  /// Generate cache file path for a track
  Future<Result<String>> generateCacheFilePath(
    String trackId,
    String fileExtension,
  ) async {
    // dart:io file access throws in a browser; the web build streams only.
    if (!supportsOfflineDownloads) {
      return ResultHelper.failure(CacheFailure(offlineUnavailableOnWebMessage));
    }
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName =
          '${trackId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = path.join(cacheDir.path, fileName);
      return ResultHelper.success(filePath);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to generate cache file path: $e'),
      );
    }
  }

  /// Get cache directory, creating it if it doesn't exist
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'omnisonic_cache'));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Watch cache entries for changes
  Stream<List<CacheEntry>> watchAllCacheEntries() {
    return _database.cacheDao.watchAllCacheEntries();
  }

  /// Watch specific cache entry for changes
  Stream<CacheEntry?> watchCacheEntryByTrackId(String trackId) {
    return _database.cacheDao.watchCacheEntryByTrackId(trackId);
  }

  /// Watch total cache size for changes
  Stream<int> watchTotalCacheSize() {
    return _database.cacheDao.watchTotalCacheSize();
  }
}
