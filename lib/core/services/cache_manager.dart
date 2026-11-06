import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

import '../entities/entities.dart';
import '../errors/errors.dart';
import '../utils/web_support.dart';

/// Cache eviction strategy
enum CacheEvictionStrategy {
  lru, // Least Recently Used
  lfu, // Least Frequently Used
  fifo, // First In, First Out
  size, // Largest files first
}

/// Cache manager for offline content management
class CacheManager {
  CacheManager({
    this.maxCacheSize = 2 * 1024 * 1024 * 1024, // 2GB default
    this.evictionStrategy = CacheEvictionStrategy.lru,
    this.cleanupThreshold = 0.9, // Start cleanup at 90% full
  });

  /// Maximum cache size in bytes
  final int maxCacheSize;

  /// Cache eviction strategy
  final CacheEvictionStrategy evictionStrategy;

  /// Threshold for automatic cleanup (0.0 to 1.0)
  final double cleanupThreshold;

  /// Calculates current cache statistics
  Future<Result<CacheStats>> getCacheStats(List<CacheEntry> entries) async {
    try {
      int totalSize = 0;
      int pinnedSize = 0;
      int fileCount = 0;
      int pinnedFileCount = 0;
      int validFiles = 0;

      for (final entry in entries) {
        final file = File(entry.filePath);
        if (await file.exists()) {
          totalSize += entry.fileSize;
          fileCount++;
          validFiles++;

          if (entry.isPinned) {
            pinnedSize += entry.fileSize;
            pinnedFileCount++;
          }
        }
      }

      final availableSpace = max(0, maxCacheSize - totalSize);
      final hitRate = entries.isNotEmpty ? validFiles / entries.length : 0.0;

      final stats = CacheStats(
        totalSize: totalSize,
        pinnedSize: pinnedSize,
        availableSpace: availableSpace,
        fileCount: fileCount,
        pinnedFileCount: pinnedFileCount,
        hitRate: hitRate,
      );

      return ResultHelper.success(stats);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to calculate cache stats: $e'),
      );
    }
  }

  /// Checks if cache needs cleanup
  Future<Result<bool>> needsCleanup(List<CacheEntry> entries) async {
    try {
      final statsResult = await getCacheStats(entries);
      if (statsResult.isFailure) {
        return ResultHelper.failure(statsResult.failureOrNull!);
      }

      final stats = statsResult.valueOrNull!;
      final usageRatio = stats.totalSize / maxCacheSize;

      return ResultHelper.success(usageRatio >= cleanupThreshold);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to check cleanup need: $e'),
      );
    }
  }

  /// Determines which entries should be evicted to free up space
  Future<Result<List<CacheEntry>>> selectEntriesForEviction(
    List<CacheEntry> entries,
    int targetFreeSpace,
  ) async {
    try {
      // Filter out pinned entries
      final evictableEntries = entries.where((e) => !e.isPinned).toList();

      if (evictableEntries.isEmpty) {
        return ResultHelper.success([]);
      }

      // Sort entries based on eviction strategy
      evictableEntries.sort((a, b) => _compareForEviction(a, b));

      // Select entries to evict until we have enough space
      final toEvict = <CacheEntry>[];
      int freedSpace = 0;

      for (final entry in evictableEntries) {
        if (freedSpace >= targetFreeSpace) break;

        toEvict.add(entry);
        freedSpace += entry.fileSize;
      }

      return ResultHelper.success(toEvict);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to select entries for eviction: $e'),
      );
    }
  }

  /// Performs cache cleanup by evicting entries
  Future<Result<int>> performCleanup(
    List<CacheEntry> entries, {
    int? targetFreeSpace,
  }) async {
    try {
      // Calculate target free space if not provided
      targetFreeSpace ??= (maxCacheSize * 0.3).round(); // Free up 30%

      // Select entries for eviction
      final evictionResult = await selectEntriesForEviction(
        entries,
        targetFreeSpace,
      );
      if (evictionResult.isFailure) {
        return ResultHelper.failure(evictionResult.failureOrNull!);
      }

      final toEvict = evictionResult.valueOrNull!;
      int freedSpace = 0;

      // Delete selected files
      for (final entry in toEvict) {
        try {
          final file = File(entry.filePath);
          if (await file.exists()) {
            await file.delete();
            freedSpace += entry.fileSize;
          }
        } catch (e) {
          // Continue with other files if one fails
          continue;
        }
      }

      return ResultHelper.success(freedSpace);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to perform cleanup: $e'),
      );
    }
  }

  /// Validates cache integrity and removes invalid entries
  Future<Result<List<String>>> validateCacheIntegrity(
    List<CacheEntry> entries,
  ) async {
    try {
      final invalidEntries = <String>[];

      for (final entry in entries) {
        final file = File(entry.filePath);

        if (!await file.exists()) {
          invalidEntries.add(entry.trackId);
          continue;
        }

        // Check file size matches
        final actualSize = await file.length();
        if (actualSize != entry.fileSize) {
          invalidEntries.add(entry.trackId);
          // Delete corrupted file
          try {
            await file.delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      }

      return ResultHelper.success(invalidEntries);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to validate cache integrity: $e'),
      );
    }
  }

  /// Calculates space needed for a new download
  Future<Result<bool>> canAccommodateDownload(
    List<CacheEntry> entries,
    int downloadSize,
  ) async {
    try {
      final statsResult = await getCacheStats(entries);
      if (statsResult.isFailure) {
        return ResultHelper.failure(statsResult.failureOrNull!);
      }

      final stats = statsResult.valueOrNull!;

      // Check if we have enough available space
      if (stats.availableSpace >= downloadSize) {
        return ResultHelper.success(true);
      }

      // Check if we can free up enough space by evicting non-pinned entries
      final evictableEntries = entries.where((e) => !e.isPinned).toList();
      final totalEvictableSize = evictableEntries.fold<int>(
        0,
        (sum, entry) => sum + entry.fileSize,
      );

      final spaceNeeded = downloadSize - stats.availableSpace;
      return ResultHelper.success(totalEvictableSize >= spaceNeeded);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to check download accommodation: $e'),
      );
    }
  }

  /// Gets cache directory size
  Future<Result<int>> getCacheDirectorySize() async {
    // No disk cache in the web build.
    if (!supportsOfflineDownloads) return ResultHelper.success(0);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/omnisonic_cache');

      if (!await cacheDir.exists()) {
        return ResultHelper.success(0);
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Skip files we can't read
            continue;
          }
        }
      }

      return ResultHelper.success(totalSize);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to calculate cache directory size: $e'),
      );
    }
  }

  /// Compares two cache entries for eviction priority
  int _compareForEviction(CacheEntry a, CacheEntry b) {
    switch (evictionStrategy) {
      case CacheEvictionStrategy.lru:
        // Least recently used first
        return a.lastAccessed.compareTo(b.lastAccessed);

      case CacheEvictionStrategy.lfu:
        // For LFU, we'd need access count - using last accessed as proxy
        return a.lastAccessed.compareTo(b.lastAccessed);

      case CacheEvictionStrategy.fifo:
        // First in, first out
        return a.cachedAt.compareTo(b.cachedAt);

      case CacheEvictionStrategy.size:
        // Largest files first
        return b.fileSize.compareTo(a.fileSize);
    }
  }

  /// Gets recommended cache size based on available storage
  static Future<Result<int>> getRecommendedCacheSize() async {
    try {
      // Use 10% of available space, max 5GB, min 500MB
      const minSize = 500 * 1024 * 1024; // 500MB
      const maxSize = 5 * 1024 * 1024 * 1024; // 5GB

      // This is a simplified calculation - in reality you'd want to check
      // actual available disk space
      final recommendedSize = (2 * 1024 * 1024 * 1024).clamp(minSize, maxSize);

      return ResultHelper.success(recommendedSize);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to calculate recommended cache size: $e'),
      );
    }
  }
}
