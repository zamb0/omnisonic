import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/music_repository.dart';
import '../../../../core/repositories/playlist_repository.dart';
import '../../../../core/repositories/offline_repository.dart';
import '../../../../core/services/offline_mode_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../services/offline_content_filter.dart';

/// Parameters for offline mode management
class OfflineModeParams {
  const OfflineModeParams({required this.action, this.forceOffline});

  final OfflineModeAction action;
  final bool? forceOffline;
}

/// Actions for offline mode
enum OfflineModeAction {
  getOfflineCollection,
  checkConnectivity,
  setOfflineMode,
  getOfflineStats,
}

/// Result for offline collection
class OfflineCollectionResult {
  const OfflineCollectionResult({
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.stats,
  });

  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final OfflineCacheStats stats;
}

/// Use case for managing offline mode functionality
class ManageOfflineModeUseCase implements UseCase<dynamic, OfflineModeParams> {
  ManageOfflineModeUseCase({
    required OfflineModeService offlineModeService,
    required MusicRepository musicRepository,
    required PlaylistRepository playlistRepository,
    required OfflineRepository offlineRepository,
    required OfflineContentFilter contentFilter,
  }) : _offlineModeService = offlineModeService,
       _musicRepository = musicRepository,
       _playlistRepository = playlistRepository,
       _offlineRepository = offlineRepository,
       _contentFilter = contentFilter;

  final OfflineModeService _offlineModeService;
  final MusicRepository _musicRepository;
  final PlaylistRepository _playlistRepository;
  final OfflineRepository _offlineRepository;
  final OfflineContentFilter _contentFilter;

  @override
  Future<Result<dynamic>> call(OfflineModeParams params) async {
    switch (params.action) {
      case OfflineModeAction.getOfflineCollection:
        return await _getOfflineCollection();

      case OfflineModeAction.checkConnectivity:
        return await _checkConnectivity();

      case OfflineModeAction.setOfflineMode:
        return await _setOfflineMode(params.forceOffline ?? false);

      case OfflineModeAction.getOfflineStats:
        return await _getOfflineStats();
    }
  }

  /// Gets the offline-available collection
  Future<Result<OfflineCollectionResult>> _getOfflineCollection() async {
    try {
      // Get all content from music repository
      final tracksResult = await _musicRepository.getAllTracks();
      if (tracksResult.isFailure)
        return ResultHelper.failure(tracksResult.failureOrNull!);

      final albumsResult = await _musicRepository.getAllAlbums();
      if (albumsResult.isFailure)
        return ResultHelper.failure(albumsResult.failureOrNull!);

      final artistsResult = await _musicRepository.getAllArtists();
      if (artistsResult.isFailure)
        return ResultHelper.failure(artistsResult.failureOrNull!);

      final playlistsResult = await _playlistRepository.getAllPlaylists();
      if (playlistsResult.isFailure)
        return ResultHelper.failure(UnknownFailure('Failed to get playlists'));

      final allTracks = tracksResult.valueOrNull!;
      final allAlbums = albumsResult.valueOrNull!;
      final allArtists = artistsResult.valueOrNull!;
      final allPlaylists = playlistsResult.valueOrNull!;

      // Filter to only cached content
      final cachedTracksResult = await _contentFilter.filterCachedTracks(
        allTracks,
      );
      if (cachedTracksResult.isFailure)
        return ResultHelper.failure(cachedTracksResult.failureOrNull!);

      final cachedAlbumsResult = await _contentFilter
          .filterAlbumsWithCachedTracks(allAlbums, allTracks);
      if (cachedAlbumsResult.isFailure)
        return ResultHelper.failure(cachedAlbumsResult.failureOrNull!);

      final cachedArtistsResult = await _contentFilter
          .filterArtistsWithCachedTracks(allArtists, allTracks);
      if (cachedArtistsResult.isFailure)
        return ResultHelper.failure(cachedArtistsResult.failureOrNull!);

      // For playlists, we need to get playlist tracks first
      final playlistTracksMap = <String, List<Track>>{};
      for (final playlist in allPlaylists) {
        final playlistTracksResult = await _playlistRepository
            .getPlaylistTracks(playlist.id);
        if (playlistTracksResult.isSuccess) {
          playlistTracksMap[playlist.id] = playlistTracksResult.valueOrNull!;
        }
      }

      final cachedPlaylistsResult = await _contentFilter
          .filterPlaylistsWithCachedTracks(allPlaylists, playlistTracksMap);
      if (cachedPlaylistsResult.isFailure)
        return ResultHelper.failure(cachedPlaylistsResult.failureOrNull!);

      // Get cache statistics
      final statsResult = await _contentFilter.getCacheStatsForCollection(
        allTracks,
        allAlbums,
        allArtists,
      );
      if (statsResult.isFailure)
        return ResultHelper.failure(statsResult.failureOrNull!);

      final result = OfflineCollectionResult(
        tracks: cachedTracksResult.valueOrNull!,
        albums: cachedAlbumsResult.valueOrNull!,
        artists: cachedArtistsResult.valueOrNull!,
        playlists: cachedPlaylistsResult.valueOrNull!,
        stats: statsResult.valueOrNull!,
      );

      return ResultHelper.success(result);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get offline collection: $e'),
      );
    }
  }

  /// Checks current connectivity status
  Future<Result<Map<String, dynamic>>> _checkConnectivity() async {
    try {
      final connectivityResult = await _offlineModeService.checkConnectivity();
      if (connectivityResult.isFailure)
        return ResultHelper.failure(connectivityResult.failureOrNull!);

      final currentConnectivityResult = await _offlineModeService
          .getCurrentConnectivity();
      if (currentConnectivityResult.isFailure)
        return ResultHelper.failure(currentConnectivityResult.failureOrNull!);

      final result = {
        'isOffline': connectivityResult.valueOrNull!,
        'connectivityType': currentConnectivityResult.valueOrNull!.name,
        'hasNetworkConnection': _offlineModeService.hasNetworkConnection,
        'isWiFiConnection': _offlineModeService.isWiFiConnection,
        'isMeteredConnection': _offlineModeService.isMeteredConnection,
        'networkQuality': _offlineModeService.networkQuality.description,
      };

      return ResultHelper.success(result);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to check connectivity: $e'),
      );
    }
  }

  /// Sets offline mode manually
  Future<Result<void>> _setOfflineMode(bool forceOffline) async {
    try {
      _offlineModeService.setOfflineMode(forceOffline);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to set offline mode: $e'),
      );
    }
  }

  /// Gets offline statistics
  Future<Result<Map<String, dynamic>>> _getOfflineStats() async {
    try {
      // Get cache stats from offline repository
      final cacheStatsResult = await _offlineRepository.getCacheStats();
      if (cacheStatsResult.isFailure)
        return ResultHelper.failure(cacheStatsResult.failureOrNull!);

      // Get collection stats
      final collectionResult = await _getOfflineCollection();
      if (collectionResult.isFailure)
        return ResultHelper.failure(collectionResult.failureOrNull!);

      final cacheStats = cacheStatsResult.valueOrNull!;
      final collection = collectionResult.valueOrNull!;

      final result = {
        'cacheStats': {
          'totalSize': cacheStats.totalSize,
          'formattedTotalSize': cacheStats.formattedTotalSize,
          'availableSpace': cacheStats.availableSpace,
          'formattedAvailableSpace': cacheStats.formattedAvailableSpace,
          'fileCount': cacheStats.fileCount,
          'pinnedFileCount': cacheStats.pinnedFileCount,
          'usagePercentage': cacheStats.usagePercentage,
          'hitRate': cacheStats.hitRate,
          'isNearlyFull': cacheStats.isNearlyFull,
          'needsCleanup': cacheStats.needsCleanup,
        },
        'collectionStats': {
          'totalTracks': collection.stats.totalTracks,
          'cachedTracks': collection.stats.cachedTracks,
          'trackCachePercentage': collection.stats.trackCachePercentage,
          'totalAlbums': collection.stats.totalAlbums,
          'cachedAlbums': collection.stats.cachedAlbums,
          'albumCachePercentage': collection.stats.albumCachePercentage,
          'totalArtists': collection.stats.totalArtists,
          'cachedArtists': collection.stats.cachedArtists,
          'artistCachePercentage': collection.stats.artistCachePercentage,
          'isWellCached': collection.stats.isWellCached,
        },
        'connectivity': {
          'isOffline': _offlineModeService.isOffline,
          'networkQuality': _offlineModeService.networkQuality.description,
          'hasNetworkConnection': _offlineModeService.hasNetworkConnection,
        },
      };

      return ResultHelper.success(result);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get offline stats: $e'),
      );
    }
  }
}
