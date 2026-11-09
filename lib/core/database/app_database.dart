import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../entities/audio_quality.dart';
import '../entities/server_status.dart';
import 'connection/connection.dart';
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
  AppDatabase() : super(openConnection());

  // Constructor for testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

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
          // Foreign keys are enforced from this version on (see beforeOpen),
          // so rows orphaned while the pragma was off are removed first.
          // Dropping the tables instead would also throw away the user's
          // playlists and the cache rows of their downloads, leaving the
          // downloaded files on disk with nothing pointing at them.
          await deleteForeignKeyOrphans();

          for (final index in allSchemaEntities.whereType<Index>()) {
            await m.create(index);
          }
        }
        if (from < 5) {
          // Migration for version 5: the user's star rating of each track.
          await m.addColumn(tracksTable, tracksTable.rating);
        }
      },
      beforeOpen: (details) async {
        // Drift leaves foreign keys off by default, which silently disables
        // every onDelete: cascade declared in tables.dart.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Deletes every row whose foreign key points at a row that no longer
  /// exists, parents before children so each pass sees the final parent set.
  ///
  /// Such rows could pile up while `PRAGMA foreign_keys` was off; with it on,
  /// they would make otherwise valid writes to those tables fail.
  @visibleForTesting
  Future<void> deleteForeignKeyOrphans() async {
    final servers = serversTable.actualTableName;
    final tracks = tracksTable.actualTableName;
    final playlists = playlistsTable.actualTableName;
    final groups = duplicateGroupsTable.actualTableName;

    for (final table in [
      tracksTable.actualTableName,
      albumsTable.actualTableName,
      artistsTable.actualTableName,
    ]) {
      await customStatement(
        'DELETE FROM $table WHERE server_id NOT IN (SELECT id FROM $servers)',
      );
    }
    await customStatement(
      'DELETE FROM ${playlistTracksTable.actualTableName} '
      'WHERE playlist_id NOT IN (SELECT id FROM $playlists) '
      'OR track_id NOT IN (SELECT id FROM $tracks)',
    );
    await customStatement(
      'DELETE FROM $groups '
      'WHERE representative_track_id NOT IN (SELECT id FROM $tracks)',
    );
    await customStatement(
      'DELETE FROM ${duplicateGroupMembersTable.actualTableName} '
      'WHERE group_id NOT IN (SELECT id FROM $groups) '
      'OR track_id NOT IN (SELECT id FROM $tracks)',
    );
    await customStatement(
      'DELETE FROM ${cacheEntriesTable.actualTableName} '
      'WHERE track_id NOT IN (SELECT id FROM $tracks)',
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
