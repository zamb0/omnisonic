import '../entities/entities.dart';
import '../errors/errors.dart';

/// Repository interface for offline content management
abstract class OfflineRepository {
  /// Downloads a track for offline use
  Future<Result<CacheEntry>> downloadTrack(
    Track track, {
    void Function(int received, int total)? onProgress,
  });

  /// Cancels an active download
  Future<Result<void>> cancelDownload(String trackId);

  /// Gets all cached entries
  Future<Result<List<CacheEntry>>> getAllCachedEntries();

  /// Gets a cached entry by track ID
  Future<Result<CacheEntry?>> getCachedEntry(String trackId);

  /// Removes a track from cache
  Future<Result<void>> removeCachedTrack(String trackId);

  /// Removes multiple tracks from cache
  Future<Result<void>> removeCachedTracks(List<String> trackIds);

  /// Gets cache statistics
  Future<Result<CacheStats>> getCacheStats();

  /// Performs cache cleanup
  Future<Result<int>> performCacheCleanup({int? targetFreeSpace});

  /// Validates cache integrity
  Future<Result<List<String>>> validateCacheIntegrity();

  /// Checks if a track is cached
  Future<Result<bool>> isTrackCached(String trackId);

  /// Checks if a track is currently downloading
  bool isTrackDownloading(String trackId);

  /// Gets list of currently downloading track IDs
  List<String> getActiveDownloads();

  /// Pins a cached track to protect from eviction
  Future<Result<void>> pinTrack(String trackId);

  /// Unpins a cached track
  Future<Result<void>> unpinTrack(String trackId);

  /// Gets all pinned tracks
  Future<Result<List<CacheEntry>>> getPinnedTracks();

  /// Checks if cache can accommodate a download
  Future<Result<bool>> canAccommodateDownload(int downloadSize);

  /// Updates last accessed time for a cached track
  Future<Result<void>> updateLastAccessed(String trackId);

  /// Gets cached tracks by server ID
  Future<Result<List<CacheEntry>>> getCachedTracksByServer(String serverId);

  /// Removes all cached tracks from a specific server
  Future<Result<void>> removeCachedTracksFromServer(String serverId);

  /// Stream of cache statistics updates
  Stream<CacheStats> observeCacheStats();

  /// Stream of download progress updates
  Stream<Map<String, double>> observeDownloadProgress();
}