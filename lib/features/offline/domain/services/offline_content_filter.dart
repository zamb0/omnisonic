import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/offline_repository.dart';

/// Service for filtering content based on offline availability
class OfflineContentFilter {
  OfflineContentFilter({
    required OfflineRepository offlineRepository,
  }) : _offlineRepository = offlineRepository;

  final OfflineRepository _offlineRepository;

  /// Filters tracks to only include cached ones
  Future<Result<List<Track>>> filterCachedTracks(List<Track> tracks) async {
    try {
      final cachedEntriesResult = await _offlineRepository.getAllCachedEntries();
      if (cachedEntriesResult.isFailure) {
        return ResultHelper.failure(cachedEntriesResult.failureOrNull!);
      }

      final cachedEntries = cachedEntriesResult.valueOrNull!;
      final cachedTrackIds = cachedEntries
          .where((entry) => entry.isComplete)
          .map((entry) => entry.trackId)
          .toSet();

      final cachedTracks = tracks
          .where((track) => cachedTrackIds.contains(track.id))
          .toList();

      return ResultHelper.success(cachedTracks);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to filter cached tracks: $e'));
    }
  }

  /// Filters albums to only include those with cached tracks
  Future<Result<List<Album>>> filterAlbumsWithCachedTracks(
    List<Album> albums,
    List<Track> allTracks,
  ) async {
    try {
      final cachedTracksResult = await filterCachedTracks(allTracks);
      if (cachedTracksResult.isFailure) {
        return ResultHelper.failure(cachedTracksResult.failureOrNull!);
      }

      final cachedTracks = cachedTracksResult.valueOrNull!;
      final albumsWithCachedTracks = <String>{};

      // Find albums that have at least one cached track
      for (final track in cachedTracks) {
        if (track.albumId != null) {
          albumsWithCachedTracks.add(track.albumId!);
        }
      }

      final filteredAlbums = albums
          .where((album) => albumsWithCachedTracks.contains(album.id))
          .toList();

      return ResultHelper.success(filteredAlbums);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to filter albums with cached tracks: $e'));
    }
  }

  /// Filters artists to only include those with cached tracks
  Future<Result<List<Artist>>> filterArtistsWithCachedTracks(
    List<Artist> artists,
    List<Track> allTracks,
  ) async {
    try {
      final cachedTracksResult = await filterCachedTracks(allTracks);
      if (cachedTracksResult.isFailure) {
        return ResultHelper.failure(cachedTracksResult.failureOrNull!);
      }

      final cachedTracks = cachedTracksResult.valueOrNull!;
      final artistsWithCachedTracks = <String>{};

      // Find artists that have at least one cached track
      for (final track in cachedTracks) {
        if (track.artistId != null) {
          artistsWithCachedTracks.add(track.artistId!);
        }
      }

      final filteredArtists = artists
          .where((artist) => artistsWithCachedTracks.contains(artist.id))
          .toList();

      return ResultHelper.success(filteredArtists);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to filter artists with cached tracks: $e'));
    }
  }

  /// Filters playlists to only include those with cached tracks
  Future<Result<List<Playlist>>> filterPlaylistsWithCachedTracks(
    List<Playlist> playlists,
    Map<String, List<Track>> playlistTracks,
  ) async {
    try {
      final playlistsWithCachedTracks = <Playlist>[];

      for (final playlist in playlists) {
        final tracks = playlistTracks[playlist.id] ?? [];
        
        if (tracks.isNotEmpty) {
          final cachedTracksResult = await filterCachedTracks(tracks);
          if (cachedTracksResult.isSuccess && cachedTracksResult.valueOrNull!.isNotEmpty) {
            playlistsWithCachedTracks.add(playlist);
          }
        }
      }

      return ResultHelper.success(playlistsWithCachedTracks);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to filter playlists with cached tracks: $e'));
    }
  }

  /// Gets offline-available tracks for a specific album
  Future<Result<List<Track>>> getOfflineTracksForAlbum(
    String albumId,
    List<Track> albumTracks,
  ) async {
    try {
      final albumTracksForAlbum = albumTracks
          .where((track) => track.albumId == albumId)
          .toList();

      return await filterCachedTracks(albumTracksForAlbum);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get offline tracks for album: $e'));
    }
  }

  /// Gets offline-available tracks for a specific artist
  Future<Result<List<Track>>> getOfflineTracksForArtist(
    String artistId,
    List<Track> artistTracks,
  ) async {
    try {
      final tracksForArtist = artistTracks
          .where((track) => track.artistId == artistId)
          .toList();

      return await filterCachedTracks(tracksForArtist);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get offline tracks for artist: $e'));
    }
  }

  /// Gets offline-available tracks for a specific playlist
  Future<Result<List<Track>>> getOfflineTracksForPlaylist(
    List<Track> playlistTracks,
  ) async {
    return await filterCachedTracks(playlistTracks);
  }

  /// Checks if an album is fully available offline
  Future<Result<bool>> isAlbumFullyOffline(
    String albumId,
    List<Track> albumTracks,
  ) async {
    try {
      final tracksForAlbum = albumTracks
          .where((track) => track.albumId == albumId)
          .toList();

      if (tracksForAlbum.isEmpty) {
        return ResultHelper.success(false);
      }

      final cachedTracksResult = await filterCachedTracks(tracksForAlbum);
      if (cachedTracksResult.isFailure) {
        return ResultHelper.failure(cachedTracksResult.failureOrNull!);
      }

      final cachedTracks = cachedTracksResult.valueOrNull!;
      return ResultHelper.success(cachedTracks.length == tracksForAlbum.length);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to check if album is fully offline: $e'));
    }
  }

  /// Checks if a playlist is fully available offline
  Future<Result<bool>> isPlaylistFullyOffline(List<Track> playlistTracks) async {
    try {
      if (playlistTracks.isEmpty) {
        return ResultHelper.success(true);
      }

      final cachedTracksResult = await filterCachedTracks(playlistTracks);
      if (cachedTracksResult.isFailure) {
        return ResultHelper.failure(cachedTracksResult.failureOrNull!);
      }

      final cachedTracks = cachedTracksResult.valueOrNull!;
      return ResultHelper.success(cachedTracks.length == playlistTracks.length);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to check if playlist is fully offline: $e'));
    }
  }

  /// Gets cache statistics for a collection
  Future<Result<OfflineCacheStats>> getCacheStatsForCollection(
    List<Track> tracks,
    List<Album> albums,
    List<Artist> artists,
  ) async {
    try {
      final cachedTracksResult = await filterCachedTracks(tracks);
      if (cachedTracksResult.isFailure) {
        return ResultHelper.failure(cachedTracksResult.failureOrNull!);
      }

      final cachedTracks = cachedTracksResult.valueOrNull!;
      
      final cachedAlbumsResult = await filterAlbumsWithCachedTracks(albums, tracks);
      if (cachedAlbumsResult.isFailure) {
        return ResultHelper.failure(cachedAlbumsResult.failureOrNull!);
      }

      final cachedAlbums = cachedAlbumsResult.valueOrNull!;
      
      final cachedArtistsResult = await filterArtistsWithCachedTracks(artists, tracks);
      if (cachedArtistsResult.isFailure) {
        return ResultHelper.failure(cachedArtistsResult.failureOrNull!);
      }

      final cachedArtists = cachedArtistsResult.valueOrNull!;

      final stats = OfflineCacheStats(
        totalTracks: tracks.length,
        cachedTracks: cachedTracks.length,
        totalAlbums: albums.length,
        cachedAlbums: cachedAlbums.length,
        totalArtists: artists.length,
        cachedArtists: cachedArtists.length,
      );

      return ResultHelper.success(stats);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get cache stats for collection: $e'));
    }
  }
}

/// Statistics for offline cache coverage
class OfflineCacheStats {
  const OfflineCacheStats({
    required this.totalTracks,
    required this.cachedTracks,
    required this.totalAlbums,
    required this.cachedAlbums,
    required this.totalArtists,
    required this.cachedArtists,
  });

  final int totalTracks;
  final int cachedTracks;
  final int totalAlbums;
  final int cachedAlbums;
  final int totalArtists;
  final int cachedArtists;

  /// Gets track cache percentage
  double get trackCachePercentage {
    return totalTracks > 0 ? (cachedTracks / totalTracks) * 100 : 0.0;
  }

  /// Gets album cache percentage
  double get albumCachePercentage {
    return totalAlbums > 0 ? (cachedAlbums / totalAlbums) * 100 : 0.0;
  }

  /// Gets artist cache percentage
  double get artistCachePercentage {
    return totalArtists > 0 ? (cachedArtists / totalArtists) * 100 : 0.0;
  }

  /// Checks if collection is well cached (>50% tracks)
  bool get isWellCached => trackCachePercentage > 50.0;

  @override
  String toString() {
    return 'OfflineCacheStats('
           'tracks: $cachedTracks/$totalTracks (${trackCachePercentage.toStringAsFixed(1)}%), '
           'albums: $cachedAlbums/$totalAlbums (${albumCachePercentage.toStringAsFixed(1)}%), '
           'artists: $cachedArtists/$totalArtists (${artistCachePercentage.toStringAsFixed(1)}%))';
  }
}