import '../app_database.dart';
import '../../entities/audio_quality.dart';
import '../../entities/track.dart';
import '../../entities/album.dart';
import '../../entities/artist.dart';
import '../../errors/result.dart';
import '../../errors/failures.dart';

/// Local data source for music operations (tracks, albums, artists)
class LocalMusicDataSource {
  const LocalMusicDataSource(this._database);

  final AppDatabase _database;

  // Track operations
  /// Get all tracks from local database
  Future<Result<List<Track>>> getAllTracks() async {
    try {
      final tracks = await _database.musicDao.getAllTracks();
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get tracks: $e'));
    }
  }

  /// Get tracks by server ID
  Future<Result<List<Track>>> getTracksByServerId(String serverId) async {
    try {
      final tracks = await _database.musicDao.getTracksByServerId(serverId);
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get tracks by server: $e'),
      );
    }
  }

  /// Get tracks by album ID
  Future<Result<List<Track>>> getTracksByAlbumId(String albumId) async {
    try {
      final tracks = await _database.musicDao.getTracksByAlbumId(albumId);
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get tracks by album: $e'),
      );
    }
  }

  /// Get tracks by artist ID
  Future<Result<List<Track>>> getTracksByArtistId(String artistId) async {
    try {
      final tracks = await _database.musicDao.getTracksByArtistId(artistId);
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get tracks by artist: $e'),
      );
    }
  }

  /// Get track by ID
  Future<Result<Track?>> getTrackById(String id) async {
    try {
      final track = await _database.musicDao.getTrackById(id);
      return ResultHelper.success(track);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get track: $e'));
    }
  }

  /// Get the tracks matching [ids], in database order.
  Future<Result<List<Track>>> getTracksByIds(Iterable<String> ids) async {
    try {
      final tracks = await _database.musicDao.getTracksByIds(ids);
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get tracks by id: $e'),
      );
    }
  }

  /// Get the tracks matching the given filters
  Future<Result<List<Track>>> filterTracks({
    String? genre,
    int? year,
    String? serverId,
    List<AudioQuality>? allowedQualities,
  }) async {
    try {
      final tracks = await _database.musicDao.filterTracks(
        genre: genre,
        year: year,
        serverId: serverId,
        allowedQualities: allowedQualities,
      );
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to filter tracks: $e'),
      );
    }
  }

  /// Get cached tracks
  Future<Result<List<Track>>> getCachedTracks() async {
    try {
      final tracks = await _database.musicDao.getCachedTracks();
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get cached tracks: $e'),
      );
    }
  }

  /// Insert single track
  Future<Result<void>> insertTrack(Track track) async {
    try {
      await _database.musicDao.insertTrack(track);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert track: $e'),
      );
    }
  }

  /// Insert multiple tracks (batch operation)
  Future<Result<void>> insertTracks(List<Track> tracks) async {
    try {
      await _database.musicDao.insertTracks(tracks);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert tracks: $e'),
      );
    }
  }

  /// Update track
  Future<Result<void>> updateTrack(Track track) async {
    try {
      await _database.musicDao.updateTrack(track);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update track: $e'),
      );
    }
  }

  /// Update track cache status
  Future<Result<void>> updateTrackCacheStatus(
    String trackId,
    bool isCached,
    String? cachePath,
  ) async {
    try {
      await _database.musicDao.updateTrackCacheStatus(
        trackId,
        isCached,
        cachePath,
      );
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update track cache status: $e'),
      );
    }
  }

  /// Delete track
  Future<Result<void>> deleteTrack(String id) async {
    try {
      await _database.musicDao.deleteTrack(id);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete track: $e'),
      );
    }
  }

  /// Delete tracks by server ID
  Future<Result<void>> deleteTracksByServerId(String serverId) async {
    try {
      await _database.musicDao.deleteTracksByServerId(serverId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete tracks by server: $e'),
      );
    }
  }

  // Album operations
  /// Get all albums from local database
  Future<Result<List<Album>>> getAllAlbums() async {
    try {
      final albums = await _database.musicDao.getAllAlbums();
      return ResultHelper.success(albums);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get albums: $e'));
    }
  }

  /// Get albums by server ID
  Future<Result<List<Album>>> getAlbumsByServerId(String serverId) async {
    try {
      final albums = await _database.musicDao.getAlbumsByServerId(serverId);
      return ResultHelper.success(albums);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get albums by server: $e'),
      );
    }
  }

  /// Get albums by artist ID
  Future<Result<List<Album>>> getAlbumsByArtistId(String artistId) async {
    try {
      final albums = await _database.musicDao.getAlbumsByArtistId(artistId);
      return ResultHelper.success(albums);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get albums by artist: $e'),
      );
    }
  }

  /// Get album by ID
  Future<Result<Album?>> getAlbumById(String id) async {
    try {
      final album = await _database.musicDao.getAlbumById(id);
      return ResultHelper.success(album);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get album: $e'));
    }
  }

  /// Insert single album
  Future<Result<void>> insertAlbum(Album album) async {
    try {
      await _database.musicDao.insertAlbum(album);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert album: $e'),
      );
    }
  }

  /// Insert multiple albums (batch operation)
  Future<Result<void>> insertAlbums(List<Album> albums) async {
    try {
      await _database.musicDao.insertAlbums(albums);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert albums: $e'),
      );
    }
  }

  /// Update album
  Future<Result<void>> updateAlbum(Album album) async {
    try {
      await _database.musicDao.updateAlbum(album);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update album: $e'),
      );
    }
  }

  /// Delete album
  Future<Result<void>> deleteAlbum(String id) async {
    try {
      await _database.musicDao.deleteAlbum(id);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete album: $e'),
      );
    }
  }

  /// Delete albums by server ID
  Future<Result<void>> deleteAlbumsByServerId(String serverId) async {
    try {
      await _database.musicDao.deleteAlbumsByServerId(serverId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete albums by server: $e'),
      );
    }
  }

  // Artist operations
  /// Get all artists from local database
  Future<Result<List<Artist>>> getAllArtists() async {
    try {
      final artists = await _database.musicDao.getAllArtists();
      return ResultHelper.success(artists);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get artists: $e'));
    }
  }

  /// Get artists by server ID
  Future<Result<List<Artist>>> getArtistsByServerId(String serverId) async {
    try {
      final artists = await _database.musicDao.getArtistsByServerId(serverId);
      return ResultHelper.success(artists);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get artists by server: $e'),
      );
    }
  }

  /// Get artist by ID
  Future<Result<Artist?>> getArtistById(String id) async {
    try {
      final artist = await _database.musicDao.getArtistById(id);
      return ResultHelper.success(artist);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get artist: $e'));
    }
  }

  /// Insert single artist
  Future<Result<void>> insertArtist(Artist artist) async {
    try {
      await _database.musicDao.insertArtist(artist);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert artist: $e'),
      );
    }
  }

  /// Insert multiple artists (batch operation)
  Future<Result<void>> insertArtists(List<Artist> artists) async {
    try {
      await _database.musicDao.insertArtists(artists);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert artists: $e'),
      );
    }
  }

  /// Update artist
  Future<Result<void>> updateArtist(Artist artist) async {
    try {
      await _database.musicDao.updateArtist(artist);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update artist: $e'),
      );
    }
  }

  /// Delete artist
  Future<Result<void>> deleteArtist(String id) async {
    try {
      await _database.musicDao.deleteArtist(id);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete artist: $e'),
      );
    }
  }

  /// Delete artists by server ID
  Future<Result<void>> deleteArtistsByServerId(String serverId) async {
    try {
      await _database.musicDao.deleteArtistsByServerId(serverId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete artists by server: $e'),
      );
    }
  }

  // Search operations
  /// Search tracks by query
  Future<Result<List<Track>>> searchTracks(String query) async {
    try {
      final tracks = await _database.musicDao.searchTracks(query);
      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to search tracks: $e'),
      );
    }
  }

  /// Search albums by query
  Future<Result<List<Album>>> searchAlbums(String query) async {
    try {
      final albums = await _database.musicDao.searchAlbums(query);
      return ResultHelper.success(albums);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to search albums: $e'),
      );
    }
  }

  /// Search artists by query
  Future<Result<List<Artist>>> searchArtists(String query) async {
    try {
      final artists = await _database.musicDao.searchArtists(query);
      return ResultHelper.success(artists);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to search artists: $e'),
      );
    }
  }

  // Watch operations for reactive UI
  /// Watch all tracks for changes
  Stream<List<Track>> watchAllTracks() {
    return _database.musicDao.watchAllTracks();
  }

  /// Watch all albums for changes
  Stream<List<Album>> watchAllAlbums() {
    return _database.musicDao.watchAllAlbums();
  }

  /// Watch all artists for changes
  Stream<List<Artist>> watchAllArtists() {
    return _database.musicDao.watchAllArtists();
  }

  // Utility operations
  /// Clear all music data for a specific server
  Future<Result<void>> clearServerData(String serverId) async {
    try {
      await _database.clearServerData(serverId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to clear server data: $e'),
      );
    }
  }

  /// Sync music data from a server into the local database.
  ///
  /// Rows are upserted and only the ones the server no longer reports are
  /// deleted. A delete-then-insert would reset each track's download and star
  /// state, and — now that foreign keys are enforced — would cascade the
  /// user's playlist entries and cached files away on every sync.
  Future<Result<void>> syncMusicData(
    String serverId, {
    List<Track>? tracks,
    List<Album>? albums,
    List<Artist>? artists,
  }) async {
    try {
      await _database.transaction(() async {
        final dao = _database.musicDao;

        // Artists and albums first: tracks reference them.
        if (artists != null) {
          await dao.upsertArtists(artists);
          await dao.deleteStaleArtists(serverId, {
            for (final a in artists) a.id,
          });
        }
        if (albums != null) {
          await dao.upsertAlbums(albums);
          await dao.deleteStaleAlbums(serverId, {for (final a in albums) a.id});
        }
        if (tracks != null) {
          await dao.upsertTracks(tracks);
          await dao.deleteStaleTracks(serverId, {for (final t in tracks) t.id});
        }
      });
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to sync music data: $e'),
      );
    }
  }

  /// Clear all data from the database
  Future<void> clearAllData() async {
    await _database.clearAllData();
  }
}
