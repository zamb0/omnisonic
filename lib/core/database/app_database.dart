import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../entities/audio_quality.dart';
import '../entities/server_status.dart';
import 'tables.dart';
import 'daos/server_dao.dart';
import 'daos/music_dao.dart';
import 'daos/playlist_dao.dart';
import 'daos/cache_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ServersTable,
    TracksTable,
    AlbumsTable,
    ArtistsTable,
    PlaylistsTable,
    PlaylistTracksTable,
    DuplicateGroupsTable,
    DuplicateGroupMembersTable,
    CacheEntriesTable,
  ],
  daos: [ServerDao, MusicDao, PlaylistDao, CacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations
        if (from < 2) {
          // Migration for version 2: Remove license_valid column.
          // Recreates servers_table with the current schema and copies the
          // existing rows over, so configured servers survive the upgrade.
          // TableMigration is drift's documented path for dropping a column and
          // is still marked experimental upstream.
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(serversTable));
        }
        if (from < 3) {
          // Migration for version 3: Add isStarred column to tracks
          await m.addColumn(tracksTable, tracksTable.isStarred);
        }
      },
    );
  }

  // Server operations
  Future<List<ServerData>> getAllServers() => select(serversTable).get();

  Future<ServerData?> getServerById(String id) => (select(
    serversTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertServer(ServersTableCompanion server) =>
      into(serversTable).insert(server);

  Future<bool> updateServer(ServersTableCompanion server) =>
      update(serversTable).replace(server);

  Future<int> deleteServer(String id) =>
      (delete(serversTable)..where((tbl) => tbl.id.equals(id))).go();

  // Track operations
  Future<List<TrackData>> getAllTracks() => select(tracksTable).get();

  Future<List<TrackData>> getTracksByServerId(String serverId) => (select(
    tracksTable,
  )..where((tbl) => tbl.serverId.equals(serverId))).get();

  Future<TrackData?> getTrackById(String id) => (select(
    tracksTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertTrack(TracksTableCompanion track) =>
      into(tracksTable).insert(track);

  Future<bool> updateTrack(TracksTableCompanion track) =>
      update(tracksTable).replace(track);

  Future<int> deleteTrack(String id) =>
      (delete(tracksTable)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteTracksByServerId(String serverId) =>
      (delete(tracksTable)..where((tbl) => tbl.serverId.equals(serverId))).go();

  // Album operations
  Future<List<AlbumData>> getAllAlbums() => select(albumsTable).get();

  Future<List<AlbumData>> getAlbumsByServerId(String serverId) => (select(
    albumsTable,
  )..where((tbl) => tbl.serverId.equals(serverId))).get();

  Future<AlbumData?> getAlbumById(String id) => (select(
    albumsTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertAlbum(AlbumsTableCompanion album) =>
      into(albumsTable).insert(album);

  Future<bool> updateAlbum(AlbumsTableCompanion album) =>
      update(albumsTable).replace(album);

  Future<int> deleteAlbum(String id) =>
      (delete(albumsTable)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteAlbumsByServerId(String serverId) =>
      (delete(albumsTable)..where((tbl) => tbl.serverId.equals(serverId))).go();

  // Artist operations
  Future<List<ArtistData>> getAllArtists() => select(artistsTable).get();

  Future<List<ArtistData>> getArtistsByServerId(String serverId) => (select(
    artistsTable,
  )..where((tbl) => tbl.serverId.equals(serverId))).get();

  Future<ArtistData?> getArtistById(String id) => (select(
    artistsTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertArtist(ArtistsTableCompanion artist) =>
      into(artistsTable).insert(artist);

  Future<bool> updateArtist(ArtistsTableCompanion artist) =>
      update(artistsTable).replace(artist);

  Future<int> deleteArtist(String id) =>
      (delete(artistsTable)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deleteArtistsByServerId(String serverId) => (delete(
    artistsTable,
  )..where((tbl) => tbl.serverId.equals(serverId))).go();

  // Playlist operations
  Future<List<PlaylistData>> getAllPlaylists() => select(playlistsTable).get();

  Future<PlaylistData?> getPlaylistById(String id) => (select(
    playlistsTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertPlaylist(PlaylistsTableCompanion playlist) =>
      into(playlistsTable).insert(playlist);

  Future<bool> updatePlaylist(PlaylistsTableCompanion playlist) =>
      update(playlistsTable).replace(playlist);

  Future<int> deletePlaylist(String id) =>
      (delete(playlistsTable)..where((tbl) => tbl.id.equals(id))).go();

  // Playlist track operations
  Future<List<PlaylistTrackData>> getPlaylistTracks(String playlistId) =>
      (select(playlistTracksTable)
            ..where((tbl) => tbl.playlistId.equals(playlistId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.position)]))
          .get();

  Future<int> insertPlaylistTrack(PlaylistTracksTableCompanion playlistTrack) =>
      into(playlistTracksTable).insert(playlistTrack);

  Future<int> deletePlaylistTrack(String playlistId, String trackId) =>
      (delete(playlistTracksTable)..where(
            (tbl) =>
                tbl.playlistId.equals(playlistId) & tbl.trackId.equals(trackId),
          ))
          .go();

  Future<int> deleteAllPlaylistTracks(String playlistId) => (delete(
    playlistTracksTable,
  )..where((tbl) => tbl.playlistId.equals(playlistId))).go();

  // Duplicate group operations
  Future<List<DuplicateGroupData>> getAllDuplicateGroups() =>
      select(duplicateGroupsTable).get();

  Future<DuplicateGroupData?> getDuplicateGroupById(String id) => (select(
    duplicateGroupsTable,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertDuplicateGroup(DuplicateGroupsTableCompanion group) =>
      into(duplicateGroupsTable).insert(group);

  Future<int> deleteDuplicateGroup(String id) =>
      (delete(duplicateGroupsTable)..where((tbl) => tbl.id.equals(id))).go();

  // Duplicate group member operations
  Future<List<DuplicateGroupMemberData>> getDuplicateGroupMembers(
    String groupId,
  ) => (select(
    duplicateGroupMembersTable,
  )..where((tbl) => tbl.groupId.equals(groupId))).get();

  Future<int> insertDuplicateGroupMember(
    DuplicateGroupMembersTableCompanion member,
  ) => into(duplicateGroupMembersTable).insert(member);

  Future<int> deleteDuplicateGroupMembers(String groupId) => (delete(
    duplicateGroupMembersTable,
  )..where((tbl) => tbl.groupId.equals(groupId))).go();

  // Cache operations
  Future<List<CacheEntryData>> getAllCacheEntries() =>
      select(cacheEntriesTable).get();

  Future<CacheEntryData?> getCacheEntryByTrackId(String trackId) => (select(
    cacheEntriesTable,
  )..where((tbl) => tbl.trackId.equals(trackId))).getSingleOrNull();

  Future<int> insertCacheEntry(CacheEntriesTableCompanion entry) =>
      into(cacheEntriesTable).insert(entry);

  Future<bool> updateCacheEntry(CacheEntriesTableCompanion entry) =>
      update(cacheEntriesTable).replace(entry);

  Future<int> deleteCacheEntry(String trackId) => (delete(
    cacheEntriesTable,
  )..where((tbl) => tbl.trackId.equals(trackId))).go();

  // Search operations
  Future<List<TrackData>> searchTracks(String query) {
    final normalizedQuery = '%${query.toLowerCase()}%';
    return (select(tracksTable)..where(
          (tbl) =>
              tbl.title.lower().like(normalizedQuery) |
              tbl.artist.lower().like(normalizedQuery) |
              tbl.album.lower().like(normalizedQuery),
        ))
        .get();
  }

  Future<List<AlbumData>> searchAlbums(String query) {
    final normalizedQuery = '%${query.toLowerCase()}%';
    return (select(albumsTable)..where(
          (tbl) =>
              tbl.title.lower().like(normalizedQuery) |
              tbl.artist.lower().like(normalizedQuery),
        ))
        .get();
  }

  Future<List<ArtistData>> searchArtists(String query) {
    final normalizedQuery = '%${query.toLowerCase()}%';
    return (select(
      artistsTable,
    )..where((tbl) => tbl.name.lower().like(normalizedQuery))).get();
  }

  // Utility operations
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(cacheEntriesTable).go();
      await delete(duplicateGroupMembersTable).go();
      await delete(duplicateGroupsTable).go();
      await delete(playlistTracksTable).go();
      await delete(playlistsTable).go();
      await delete(tracksTable).go();
      await delete(albumsTable).go();
      await delete(artistsTable).go();
      await delete(serversTable).go();
    });
  }

  Future<void> clearServerData(String serverId) async {
    await transaction(() async {
      await deleteTracksByServerId(serverId);
      await deleteAlbumsByServerId(serverId);
      await deleteArtistsByServerId(serverId);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'omnisonic.db'));

    return NativeDatabase.createInBackground(file);
  });
}
