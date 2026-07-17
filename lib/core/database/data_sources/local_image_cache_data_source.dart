import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../errors/result.dart';
import '../../errors/failures.dart';

/// Image cache entry model
class ImageCacheEntry {
  const ImageCacheEntry({
    required this.url,
    required this.filePath,
    required this.fileSize,
    required this.cachedAt,
    required this.lastAccessed,
    required this.mimeType,
  });

  final String url;
  final String filePath;
  final int fileSize;
  final DateTime cachedAt;
  final DateTime lastAccessed;
  final String mimeType;

  ImageCacheEntry copyWith({
    String? url,
    String? filePath,
    int? fileSize,
    DateTime? cachedAt,
    DateTime? lastAccessed,
    String? mimeType,
  }) {
    return ImageCacheEntry(
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      mimeType: mimeType ?? this.mimeType,
    );
  }
}

/// Local data source for image caching operations
class LocalImageCacheDataSource {
  LocalImageCacheDataSource();

  static const String _imageCacheDir = 'omnisonic_image_cache';
  static const String _metadataFileName = 'cache_metadata.json';

  // In-memory cache for metadata to avoid frequent file I/O
  Map<String, ImageCacheEntry>? _metadataCache;

  /// Get image cache directory
  Future<Directory> _getImageCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, _imageCacheDir));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Get metadata file
  Future<File> _getMetadataFile() async {
    final cacheDir = await _getImageCacheDirectory();
    return File(path.join(cacheDir.path, _metadataFileName));
  }

  /// Load metadata from file
  Future<Map<String, ImageCacheEntry>> _loadMetadata() async {
    if (_metadataCache != null) {
      return _metadataCache!;
    }

    try {
      final metadataFile = await _getMetadataFile();

      if (!await metadataFile.exists()) {
        _metadataCache = {};
        return _metadataCache!;
      }

      final jsonString = await metadataFile.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      _metadataCache = {};
      for (final entry in jsonData.entries) {
        final data = entry.value as Map<String, dynamic>;
        _metadataCache![entry.key] = ImageCacheEntry(
          url: data['url'] as String,
          filePath: data['filePath'] as String,
          fileSize: data['fileSize'] as int,
          cachedAt: DateTime.parse(data['cachedAt'] as String),
          lastAccessed: DateTime.parse(data['lastAccessed'] as String),
          mimeType: data['mimeType'] as String,
        );
      }

      return _metadataCache!;
    } catch (e) {
      _metadataCache = {};
      return _metadataCache!;
    }
  }

  /// Save metadata to file
  Future<void> _saveMetadata() async {
    if (_metadataCache == null) return;

    try {
      final metadataFile = await _getMetadataFile();
      final jsonData = <String, dynamic>{};

      for (final entry in _metadataCache!.entries) {
        jsonData[entry.key] = {
          'url': entry.value.url,
          'filePath': entry.value.filePath,
          'fileSize': entry.value.fileSize,
          'cachedAt': entry.value.cachedAt.toIso8601String(),
          'lastAccessed': entry.value.lastAccessed.toIso8601String(),
          'mimeType': entry.value.mimeType,
        };
      }

      await metadataFile.writeAsString(json.encode(jsonData));
    } catch (e) {
      // Ignore metadata save errors to avoid blocking image operations
    }
  }

  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate file path for cached image
  Future<String> _generateFilePath(String cacheKey, String mimeType) async {
    final cacheDir = await _getImageCacheDirectory();
    final extension = _getFileExtensionFromMimeType(mimeType);
    return path.join(cacheDir.path, '$cacheKey.$extension');
  }

  /// Get file extension from MIME type
  String _getFileExtensionFromMimeType(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'image/bmp':
        return 'bmp';
      default:
        return 'jpg'; // Default to jpg
    }
  }

  /// Check if image is cached
  Future<Result<bool>> isImageCached(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final metadata = await _loadMetadata();

      if (!metadata.containsKey(cacheKey)) {
        return ResultHelper.success(false);
      }

      final entry = metadata[cacheKey]!;
      final file = File(entry.filePath);

      if (await file.exists()) {
        return ResultHelper.success(true);
      } else {
        // File doesn't exist, remove from metadata
        metadata.remove(cacheKey);
        await _saveMetadata();
        return ResultHelper.success(false);
      }
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to check if image is cached: $e'),
      );
    }
  }

  /// Get cached image file path
  Future<Result<String?>> getCachedImagePath(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final metadata = await _loadMetadata();

      if (!metadata.containsKey(cacheKey)) {
        return ResultHelper.success(null);
      }

      final entry = metadata[cacheKey]!;
      final file = File(entry.filePath);

      if (await file.exists()) {
        // Update last accessed time
        final updatedEntry = entry.copyWith(lastAccessed: DateTime.now());
        metadata[cacheKey] = updatedEntry;
        await _saveMetadata();

        return ResultHelper.success(entry.filePath);
      } else {
        // File doesn't exist, remove from metadata
        metadata.remove(cacheKey);
        await _saveMetadata();
        return ResultHelper.success(null);
      }
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to get cached image path: $e'),
      );
    }
  }

  /// Cache image data
  Future<Result<String>> cacheImage(
    String url,
    Uint8List imageData,
    String mimeType,
  ) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final filePath = await _generateFilePath(cacheKey, mimeType);
      final file = File(filePath);

      // Write image data to file
      await file.writeAsBytes(imageData);

      // Update metadata
      final metadata = await _loadMetadata();
      final now = DateTime.now();

      metadata[cacheKey] = ImageCacheEntry(
        url: url,
        filePath: filePath,
        fileSize: imageData.length,
        cachedAt: now,
        lastAccessed: now,
        mimeType: mimeType,
      );

      await _saveMetadata();
      return ResultHelper.success(filePath);
    } catch (e) {
      return ResultHelper.failure(CacheFailure('Failed to cache image: $e'));
    }
  }

  /// Remove cached image
  Future<Result<void>> removeCachedImage(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final metadata = await _loadMetadata();

      if (metadata.containsKey(cacheKey)) {
        final entry = metadata[cacheKey]!;
        final file = File(entry.filePath);

        // Delete physical file
        if (await file.exists()) {
          await file.delete();
        }

        // Remove from metadata
        metadata.remove(cacheKey);
        await _saveMetadata();
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to remove cached image: $e'),
      );
    }
  }

  /// Get all cached images
  Future<Result<List<ImageCacheEntry>>> getAllCachedImages() async {
    try {
      final metadata = await _loadMetadata();
      return ResultHelper.success(metadata.values.toList());
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to get all cached images: $e'),
      );
    }
  }

  /// Get cache statistics
  Future<Result<Map<String, dynamic>>> getCacheStats() async {
    try {
      final metadata = await _loadMetadata();
      final entries = metadata.values.toList();

      final totalSize = entries.fold<int>(
        0,
        (sum, entry) => sum + entry.fileSize,
      );
      final totalCount = entries.length;

      final stats = {
        'totalSize': totalSize,
        'totalCount': totalCount,
        'averageFileSize': totalCount > 0 ? totalSize / totalCount : 0,
        'oldestEntry': entries.isNotEmpty
            ? entries
                  .map((e) => e.cachedAt)
                  .reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        'newestEntry': entries.isNotEmpty
            ? entries
                  .map((e) => e.cachedAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };

      return ResultHelper.success(stats);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to get cache stats: $e'),
      );
    }
  }

  /// Clean up cache by size limit
  Future<Result<void>> cleanupCacheBySize(int maxSizeBytes) async {
    try {
      final metadata = await _loadMetadata();
      final entries = metadata.values.toList();

      final currentSize = entries.fold<int>(
        0,
        (sum, entry) => sum + entry.fileSize,
      );

      if (currentSize <= maxSizeBytes) {
        return ResultHelper.success(null); // No cleanup needed
      }

      // Sort by last accessed time (oldest first)
      entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

      int freedSize = 0;
      final sizeToFree = currentSize - maxSizeBytes;

      for (final entry in entries) {
        if (freedSize >= sizeToFree) break;

        await removeCachedImage(entry.url);
        freedSize += entry.fileSize;
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to cleanup cache by size: $e'),
      );
    }
  }

  /// Clean up cache by age
  Future<Result<void>> cleanupCacheByAge(Duration maxAge) async {
    try {
      final metadata = await _loadMetadata();
      final cutoffDate = DateTime.now().subtract(maxAge);

      final entriesToRemove = metadata.values
          .where((entry) => entry.cachedAt.isBefore(cutoffDate))
          .toList();

      for (final entry in entriesToRemove) {
        await removeCachedImage(entry.url);
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to cleanup cache by age: $e'),
      );
    }
  }

  /// Clear all cached images
  Future<Result<void>> clearAllCache() async {
    try {
      final cacheDir = await _getImageCacheDirectory();

      // Delete all files in cache directory
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      // Clear metadata
      _metadataCache = {};
      await _saveMetadata();

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to clear all cache: $e'),
      );
    }
  }

  /// Get cache size in bytes
  Future<Result<int>> getCacheSize() async {
    try {
      final metadata = await _loadMetadata();
      final totalSize = metadata.values.fold<int>(
        0,
        (sum, entry) => sum + entry.fileSize,
      );
      return ResultHelper.success(totalSize);
    } catch (e) {
      return ResultHelper.failure(CacheFailure('Failed to get cache size: $e'));
    }
  }

  /// Get cache entry count
  Future<Result<int>> getCacheEntryCount() async {
    try {
      final metadata = await _loadMetadata();
      return ResultHelper.success(metadata.length);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to get cache entry count: $e'),
      );
    }
  }
}
