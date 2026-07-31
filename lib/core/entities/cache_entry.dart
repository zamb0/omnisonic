import 'package:equatable/equatable.dart';

/// Cache entry entity representing cached audio file metadata
class CacheEntry extends Equatable {
  const CacheEntry({
    required this.trackId,
    required this.filePath,
    required this.fileSize,
    required this.cachedAt,
    required this.lastAccessed,
    required this.isComplete,
    this.isPinned = false,
  });

  /// Reference to cached track
  final String trackId;

  /// Local file path for cached audio
  final String filePath;

  /// File size in bytes
  final int fileSize;

  /// When the file was cached
  final DateTime cachedAt;

  /// Last time the cached file was accessed
  final DateTime lastAccessed;

  /// Whether the download is complete
  final bool isComplete;

  /// Whether the entry is pinned (protected from eviction)
  final bool isPinned;

  /// Creates a copy of this CacheEntry with updated fields
  CacheEntry copyWith({
    String? trackId,
    String? filePath,
    int? fileSize,
    DateTime? cachedAt,
    DateTime? lastAccessed,
    bool? isComplete,
    bool? isPinned,
  }) {
    return CacheEntry(
      trackId: trackId ?? this.trackId,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isComplete: isComplete ?? this.isComplete,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Validates cache entry data
  bool get isValid {
    return trackId.isNotEmpty && filePath.isNotEmpty && fileSize > 0;
  }

  /// Gets the formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    if (fileSize < 1024 * 1024 * 1024)
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Gets the file size in MB
  double get fileSizeMB => fileSize / (1024 * 1024);

  /// Gets the age of the cache entry
  Duration get age => DateTime.now().difference(cachedAt);

  /// Gets time since last access
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);

  /// Checks if the cache entry is stale (not accessed recently)
  bool isStale({Duration threshold = const Duration(days: 30)}) {
    return timeSinceLastAccess > threshold;
  }

  /// Updates the last accessed time to now
  CacheEntry touch() {
    return copyWith(lastAccessed: DateTime.now());
  }

  /// Pins the cache entry to protect from eviction
  CacheEntry pin() {
    return copyWith(isPinned: true);
  }

  /// Unpins the cache entry to allow eviction
  CacheEntry unpin() {
    return copyWith(isPinned: false);
  }

  @override
  List<Object?> get props => [
    trackId,
    filePath,
    fileSize,
    cachedAt,
    lastAccessed,
    isComplete,
    isPinned,
  ];

  @override
  String toString() {
    return 'CacheEntry(trackId: $trackId, filePath: $filePath, '
        'fileSize: $formattedFileSize, isPinned: $isPinned)';
  }
}

/// Cache statistics entity
class CacheStats extends Equatable {
  const CacheStats({
    required this.totalSize,
    required this.pinnedSize,
    required this.availableSpace,
    required this.fileCount,
    required this.pinnedFileCount,
    required this.hitRate,
    this.lastCleanup,
  });

  /// Total cache size in bytes
  final int totalSize;

  /// Size of pinned files in bytes
  final int pinnedSize;

  /// Available space in bytes (based on cache limit)
  final int availableSpace;

  /// Number of cached files
  final int fileCount;

  /// Number of pinned files
  final int pinnedFileCount;

  /// Cache hit rate (0.0 to 1.0)
  final double hitRate;

  /// Last cleanup timestamp
  final DateTime? lastCleanup;

  /// Gets the formatted total size
  String get formattedTotalSize => _formatBytes(totalSize);

  /// Gets the formatted pinned size
  String get formattedPinnedSize => _formatBytes(pinnedSize);

  /// Gets the formatted available space
  String get formattedAvailableSpace => _formatBytes(availableSpace);

  /// Gets the cache usage percentage
  double get usagePercentage {
    final totalCapacity = totalSize + availableSpace;
    return totalCapacity > 0 ? (totalSize / totalCapacity) * 100 : 0.0;
  }

  /// Gets the formatted usage percentage
  String get formattedUsagePercentage =>
      '${usagePercentage.toStringAsFixed(1)}%';

  /// Gets the formatted hit rate
  String get formattedHitRate => '${(hitRate * 100).toStringAsFixed(1)}%';

  /// Checks if cache is nearly full (>90% usage)
  bool get isNearlyFull => usagePercentage > 90.0;

  /// Checks if cache needs cleanup
  bool get needsCleanup {
    return isNearlyFull ||
        (lastCleanup != null &&
            DateTime.now().difference(lastCleanup!) > const Duration(days: 7));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  List<Object?> get props => [
    totalSize,
    pinnedSize,
    availableSpace,
    fileCount,
    pinnedFileCount,
    hitRate,
    lastCleanup,
  ];

  @override
  String toString() {
    return 'CacheStats(totalSize: $formattedTotalSize, '
        'fileCount: $fileCount, hitRate: $formattedHitRate)';
  }
}
