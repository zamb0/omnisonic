import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import '../../entities/audio_quality.dart';
import '../../entities/track.dart';
import '../../entities/album.dart';
import '../../entities/artist.dart';

part 'music_dao.g.dart';

@DriftAccessor(tables: [TracksTable, AlbumsTable, ArtistsTable])
class MusicDao extends DatabaseAccessor<AppDatabase> with _$MusicDaoMixin {
  MusicDao(super.db);

  // Convert between entity and database models
  Track _trackFromData(TrackData data) {
    return Track(
      id: data.id,
      title: data.title,
      artist: data.artist,
      album: data.album,
      duration: Duration(milliseconds: data.durationMs),
      serverId: data.serverId,
      streamUrl: data.streamUrl,
      quality: data.quality,
      lastModified: data.lastModified,
      albumId: data.albumId,
      artistId: data.artistId,
      trackNumber: data.trackNumber,
      discNumber: data.discNumber,
      year: data.year,
      genre: data.genre,
      fileSize: data.fileSize,
      coverArtUrl: data.coverArtUrl,
      isCached: data.isCached,
      cachePath: data.cachePath,
      isStarred: data.isStarred,
    );
  }

  TracksTableCompanion _trackToCompanion(Track track) {
    return TracksTableCompanion(
      id: Value(track.id),
      serverId: Value(track.serverId),
      title: Value(track.title),
      artist: Value(track.artist),
      album: Value(track.album),
      durationMs: Value(track.duration.inMilliseconds),
      streamUrl: Value(track.streamUrl),
      quality: Value(track.quality),
      lastModified: Value(track.lastModified),
      albumId: Value.absentIfNull(track.albumId),
      artistId: Value.absentIfNull(track.artistId),
      trackNumber: Value.absentIfNull(track.trackNumber),
      discNumber: Value.absentIfNull(track.discNumber),
      year: Value.absentIfNull(track.year),
      genre: Value.absentIfNull(track.genre),
      fileSize: Value.absentIfNull(track.fileSize),
      coverArtUrl: Value.absentIfNull(track.coverArtUrl),
      isCached: Value(track.isCached),
      cachePath: Value.absentIfNull(track.cachePath),
      isStarred: Value(track.isStarred),
    );
  }

  Album _albumFromData(AlbumData data) {
    return Album(
      id: data.id,
      title: data.title,
      artist: data.artist,
      serverId: data.serverId,
      lastModified: data.lastModified,
      artistId: data.artistId,
      year: data.year,
      genre: data.genre,
      trackCount: data.trackCount,
      duration: data.durationMs != null
          ? Duration(milliseconds: data.durationMs!)
          : null,
      coverArtUrl: data.coverArtUrl,
      description: data.description,
    );
  }

  AlbumsTableCompanion _albumToCompanion(Album album) {
    return AlbumsTableCompanion(
      id: Value(album.id),
      serverId: Value(album.serverId),
      title: Value(album.title),
      artist: Value(album.artist),
      lastModified: Value(album.lastModified),
      artistId: Value.absentIfNull(album.artistId),
      year: Value.absentIfNull(album.year),
      genre: Value.absentIfNull(album.genre),
      trackCount: Value.absentIfNull(album.trackCount),
      durationMs: Value.absentIfNull(album.duration?.inMilliseconds),
      coverArtUrl: Value.absentIfNull(album.coverArtUrl),
      description: Value.absentIfNull(album.description),
    );
  }

  Artist _artistFromData(ArtistData data) {
    return Artist(
      id: data.id,
      name: data.name,
      serverId: data.serverId,
      lastModified: data.lastModified,
      albumCount: data.albumCount,
      biography: data.biography,
      imageUrl: data.imageUrl,
      musicBrainzId: data.musicBrainzId,
      lastFmUrl: data.lastFmUrl,
    );
  }

  ArtistsTableCompanion _artistToCompanion(Artist artist) {
    return ArtistsTableCompanion(
      id: Value(artist.id),
      serverId: Value(artist.serverId),
      name: Value(artist.name),
      lastModified: Value(artist.lastModified),
      albumCount: Value.absentIfNull(artist.albumCount),
      biography: Value.absentIfNull(artist.biography),
      imageUrl: Value.absentIfNull(artist.imageUrl),
      musicBrainzId: Value.absentIfNull(artist.musicBrainzId),
      lastFmUrl: Value.absentIfNull(artist.lastFmUrl),
    );
  }

  // Track operations
  Future<List<Track>> getAllTracks() async {
    final data = await select(tracksTable).get();
    return data.map(_trackFromData).toList();
  }

  Future<List<Track>> getTracksByServerId(String serverId) async {
    final data = await (select(
      tracksTable,
    )..where((tbl) => tbl.serverId.equals(serverId))).get();
    return data.map(_trackFromData).toList();
  }

  Future<List<Track>> getTracksByAlbumId(String albumId) async {
    final data = await (select(
      tracksTable,
    )..where((tbl) => tbl.albumId.equals(albumId))).get();
    return data.map(_trackFromData).toList();
  }

  Future<List<Track>> getTracksByArtistId(String artistId) async {
    final data = await (select(
      tracksTable,
    )..where((tbl) => tbl.artistId.equals(artistId))).get();
    return data.map(_trackFromData).toList();
  }

  Future<Track?> getTrackById(String id) async {
    final data = await (select(
      tracksTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return data != null ? _trackFromData(data) : null;
  }

  /// Loads the tracks matching [ids] in chunks, so callers do not have to pull
  /// the whole library into memory to resolve a handful of IDs.
  Future<List<Track>> getTracksByIds(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return const [];

    final tracks = <Track>[];
    for (final chunk in _chunked(unique)) {
      final data = await (select(
        tracksTable,
      )..where((tbl) => tbl.id.isIn(chunk))).get();
      tracks.addAll(data.map(_trackFromData));
    }
    return tracks;
  }

  /// Returns the tracks matching every non-null filter.
  ///
  /// Pushed into SQL so callers do not have to load the whole library and
  /// filter it in Dart.
  Future<List<Track>> filterTracks({
    String? genre,
    int? year,
    String? serverId,
    List<AudioQuality>? allowedQualities,
  }) async {
    final query = select(tracksTable);

    if (genre != null) {
      query.where((tbl) => tbl.genre.lower().equals(genre.toLowerCase()));
    }
    if (year != null) {
      query.where((tbl) => tbl.year.equals(year));
    }
    if (serverId != null) {
      query.where((tbl) => tbl.serverId.equals(serverId));
    }
    if (allowedQualities != null) {
      query.where(
        (tbl) => tbl.quality.isIn(allowedQualities.map((q) => q.name).toList()),
      );
    }

    final data = await query.get();
    return data.map(_trackFromData).toList();
  }

  Future<List<Track>> getCachedTracks() async {
    final data = await (select(
      tracksTable,
    )..where((tbl) => tbl.isCached.equals(true))).get();
    return data.map(_trackFromData).toList();
  }

  Future<void> insertTrack(Track track) async {
    await into(tracksTable).insert(_trackToCompanion(track));
  }

  Future<void> insertTracks(List<Track> tracks) async {
    await batch((batch) {
      batch.insertAll(tracksTable, tracks.map(_trackToCompanion));
    });
  }

  /// Inserts [tracks], updating the rows that already exist.
  ///
  /// `isCached`, `cachePath` and `isStarred` are deliberately left alone: they
  /// describe local state that the freshly mapped remote track knows nothing
  /// about, so overwriting them would drop downloads and stars on every sync.
  Future<void> upsertTracks(List<Track> tracks) async {
    await batch((batch) {
      for (final track in tracks) {
        batch.insert(
          tracksTable,
          _trackToCompanion(track),
          onConflict: DoUpdate((_) => _trackToRemoteCompanion(track)),
        );
      }
    });
  }

  /// The subset of [_trackToCompanion] the server owns, used when updating a
  /// track that is already in the database.
  TracksTableCompanion _trackToRemoteCompanion(Track track) {
    return TracksTableCompanion(
      serverId: Value(track.serverId),
      title: Value(track.title),
      artist: Value(track.artist),
      album: Value(track.album),
      durationMs: Value(track.duration.inMilliseconds),
      streamUrl: Value(track.streamUrl),
      quality: Value(track.quality),
      lastModified: Value(track.lastModified),
      albumId: Value(track.albumId),
      artistId: Value(track.artistId),
      trackNumber: Value(track.trackNumber),
      discNumber: Value(track.discNumber),
      year: Value(track.year),
      genre: Value(track.genre),
      fileSize: Value(track.fileSize),
      coverArtUrl: Value(track.coverArtUrl),
    );
  }

  /// Deletes the tracks of [serverId] whose IDs are not in [keepIds].
  ///
  /// Used instead of a blanket delete-then-insert so that playlist entries and
  /// cache rows referencing surviving tracks are not cascaded away.
  Future<void> deleteStaleTracks(String serverId, Set<String> keepIds) async {
    final existing =
        await (selectOnly(tracksTable)
              ..addColumns([tracksTable.id])
              ..where(tracksTable.serverId.equals(serverId)))
            .map((row) => row.read(tracksTable.id)!)
            .get();

    final stale = existing.where((id) => !keepIds.contains(id)).toList();
    if (stale.isEmpty) return;

    for (final chunk in _chunked(stale)) {
      await (delete(tracksTable)..where((tbl) => tbl.id.isIn(chunk))).go();
    }
  }

  Future<void> updateTrack(Track track) async {
    await update(tracksTable).replace(_trackToCompanion(track));
  }

  Future<void> updateTrackCacheStatus(
    String trackId,
    bool isCached,
    String? cachePath,
  ) async {
    // A null cachePath means "this track is no longer on disk", so it has to
    // be written as SQL NULL — Value.absentIfNull would skip the column and
    // leave the stale path behind.
    await (update(tracksTable)..where((tbl) => tbl.id.equals(trackId))).write(
      TracksTableCompanion(
        isCached: Value(isCached),
        cachePath: Value(cachePath),
      ),
    );
  }

  Future<void> deleteTrack(String id) async {
    await (delete(tracksTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteTracksByServerId(String serverId) async {
    await (delete(
      tracksTable,
    )..where((tbl) => tbl.serverId.equals(serverId))).go();
  }

  // Album operations
  Future<List<Album>> getAllAlbums() async {
    final data = await select(albumsTable).get();
    return data.map(_albumFromData).toList();
  }

  Future<List<Album>> getAlbumsByServerId(String serverId) async {
    final data = await (select(
      albumsTable,
    )..where((tbl) => tbl.serverId.equals(serverId))).get();
    return data.map(_albumFromData).toList();
  }

  Future<List<Album>> getAlbumsByArtistId(String artistId) async {
    final data = await (select(
      albumsTable,
    )..where((tbl) => tbl.artistId.equals(artistId))).get();
    return data.map(_albumFromData).toList();
  }

  Future<Album?> getAlbumById(String id) async {
    final data = await (select(
      albumsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return data != null ? _albumFromData(data) : null;
  }

  Future<void> insertAlbum(Album album) async {
    await into(albumsTable).insert(_albumToCompanion(album));
  }

  Future<void> insertAlbums(List<Album> albums) async {
    await batch((batch) {
      batch.insertAll(albumsTable, albums.map(_albumToCompanion));
    });
  }

  Future<void> upsertAlbums(List<Album> albums) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        albumsTable,
        albums.map(_albumToCompanion).toList(),
      );
    });
  }

  Future<void> deleteStaleAlbums(String serverId, Set<String> keepIds) async {
    final existing =
        await (selectOnly(albumsTable)
              ..addColumns([albumsTable.id])
              ..where(albumsTable.serverId.equals(serverId)))
            .map((row) => row.read(albumsTable.id)!)
            .get();

    final stale = existing.where((id) => !keepIds.contains(id)).toList();
    if (stale.isEmpty) return;

    for (final chunk in _chunked(stale)) {
      await (delete(albumsTable)..where((tbl) => tbl.id.isIn(chunk))).go();
    }
  }

  Future<void> updateAlbum(Album album) async {
    await update(albumsTable).replace(_albumToCompanion(album));
  }

  Future<void> deleteAlbum(String id) async {
    await (delete(albumsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteAlbumsByServerId(String serverId) async {
    await (delete(
      albumsTable,
    )..where((tbl) => tbl.serverId.equals(serverId))).go();
  }

  // Artist operations
  Future<List<Artist>> getAllArtists() async {
    final data = await select(artistsTable).get();
    return data.map(_artistFromData).toList();
  }

  Future<List<Artist>> getArtistsByServerId(String serverId) async {
    final data = await (select(
      artistsTable,
    )..where((tbl) => tbl.serverId.equals(serverId))).get();
    return data.map(_artistFromData).toList();
  }

  Future<Artist?> getArtistById(String id) async {
    final data = await (select(
      artistsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return data != null ? _artistFromData(data) : null;
  }

  Future<void> insertArtist(Artist artist) async {
    await into(artistsTable).insert(_artistToCompanion(artist));
  }

  Future<void> insertArtists(List<Artist> artists) async {
    await batch((batch) {
      batch.insertAll(artistsTable, artists.map(_artistToCompanion));
    });
  }

  Future<void> upsertArtists(List<Artist> artists) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        artistsTable,
        artists.map(_artistToCompanion).toList(),
      );
    });
  }

  Future<void> deleteStaleArtists(String serverId, Set<String> keepIds) async {
    final existing =
        await (selectOnly(artistsTable)
              ..addColumns([artistsTable.id])
              ..where(artistsTable.serverId.equals(serverId)))
            .map((row) => row.read(artistsTable.id)!)
            .get();

    final stale = existing.where((id) => !keepIds.contains(id)).toList();
    if (stale.isEmpty) return;

    for (final chunk in _chunked(stale)) {
      await (delete(artistsTable)..where((tbl) => tbl.id.isIn(chunk))).go();
    }
  }

  /// Splits [ids] into chunks that stay under SQLite's bound-variable limit.
  static Iterable<List<String>> _chunked(
    List<String> ids, {
    int size = 500,
  }) sync* {
    for (var i = 0; i < ids.length; i += size) {
      yield ids.sublist(i, i + size > ids.length ? ids.length : i + size);
    }
  }

  Future<void> updateArtist(Artist artist) async {
    await update(artistsTable).replace(_artistToCompanion(artist));
  }

  Future<void> deleteArtist(String id) async {
    await (delete(artistsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteArtistsByServerId(String serverId) async {
    await (delete(
      artistsTable,
    )..where((tbl) => tbl.serverId.equals(serverId))).go();
  }

  // Search operations
  /// Cap on how many rows a search returns.
  ///
  /// A substring LIKE cannot use an index, so every search is a full table
  /// scan; without a limit, a one-letter query materializes the whole library
  /// on the UI isolate.
  static const int defaultSearchLimit = 200;

  Future<List<Track>> searchTracks(
    String query, {
    int limit = defaultSearchLimit,
  }) async {
    final normalizedQuery = '%${query.toLowerCase()}%';
    final data =
        await (select(tracksTable)
              ..where(
                (tbl) =>
                    tbl.title.lower().like(normalizedQuery) |
                    tbl.artist.lower().like(normalizedQuery) |
                    tbl.album.lower().like(normalizedQuery),
              )
              ..limit(limit))
            .get();
    return data.map(_trackFromData).toList();
  }

  Future<List<Album>> searchAlbums(
    String query, {
    int limit = defaultSearchLimit,
  }) async {
    final normalizedQuery = '%${query.toLowerCase()}%';
    final data =
        await (select(albumsTable)
              ..where(
                (tbl) =>
                    tbl.title.lower().like(normalizedQuery) |
                    tbl.artist.lower().like(normalizedQuery),
              )
              ..limit(limit))
            .get();
    return data.map(_albumFromData).toList();
  }

  Future<List<Artist>> searchArtists(
    String query, {
    int limit = defaultSearchLimit,
  }) async {
    final normalizedQuery = '%${query.toLowerCase()}%';
    final data =
        await (select(artistsTable)
              ..where((tbl) => tbl.name.lower().like(normalizedQuery))
              ..limit(limit))
            .get();
    return data.map(_artistFromData).toList();
  }

  // Watch for changes
  Stream<List<Track>> watchAllTracks() {
    return select(
      tracksTable,
    ).watch().map((data) => data.map(_trackFromData).toList());
  }

  Stream<List<Album>> watchAllAlbums() {
    return select(
      albumsTable,
    ).watch().map((data) => data.map(_albumFromData).toList());
  }

  Stream<List<Artist>> watchAllArtists() {
    return select(
      artistsTable,
    ).watch().map((data) => data.map(_artistFromData).toList());
  }
}
