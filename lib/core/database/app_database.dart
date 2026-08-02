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
  int get schemaVersion => 4;

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
        if (from < 4) {
          // Migration for version 4: indexes on every foreign key and on the
          // columns the cache eviction queries order by.
          //
          // The music tables are dropped and recreated rather than indexed in
          // place: enabling foreign keys (see beforeOpen) would otherwise trip
          // over rows orphaned while the pragma was off. Servers are kept, so
          // the app re-syncs its library once on first launch after the update
          // and the user does not have to re-enter any credentials.
          await m.deleteTable(cacheEntriesTable.actualTableName);
          await m.deleteTable(duplicateGroupMembersTable.actualTableName);
          await m.deleteTable(duplicateGroupsTable.actualTableName);
          await m.deleteTable(playlistTracksTable.actualTableName);
          await m.deleteTable(playlistsTable.actualTableName);
          await m.deleteTable(tracksTable.actualTableName);
          await m.deleteTable(albumsTable.actualTableName);
          await m.deleteTable(artistsTable.actualTableName);

          await m.createTable(artistsTable);
          await m.createTable(albumsTable);
          await m.createTable(tracksTable);
          await m.createTable(playlistsTable);
          await m.createTable(playlistTracksTable);
          await m.createTable(duplicateGroupsTable);
          await m.createTable(duplicateGroupMembersTable);
          await m.createTable(cacheEntriesTable);

          for (final index in allSchemaEntities.whereType<Index>()) {
            await m.create(index);
          }

          // Clear the last sync marker so the next launch performs a full sync.
          await customStatement('UPDATE servers_table SET last_sync = NULL');
        }
      },
      beforeOpen: (details) async {
        // Drift leaves foreign keys off by default, which silently disables
        // every onDelete: cascade declared in tables.dart.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Utility operations
  //
  // Everything else goes through the DAOs (ServerDao, MusicDao, PlaylistDao,
  // CacheDao); this class only keeps the operations that span all of them.
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
      await musicDao.deleteTracksByServerId(serverId);
      await musicDao.deleteAlbumsByServerId(serverId);
      await musicDao.deleteArtistsByServerId(serverId);
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
