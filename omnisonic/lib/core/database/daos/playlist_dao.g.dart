// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaylistDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTableTable get playlistsTable => attachedDatabase.playlistsTable;
  $ServersTableTable get serversTable => attachedDatabase.serversTable;
  $TracksTableTable get tracksTable => attachedDatabase.tracksTable;
  $PlaylistTracksTableTable get playlistTracksTable =>
      attachedDatabase.playlistTracksTable;
  PlaylistDaoManager get managers => PlaylistDaoManager(this);
}

class PlaylistDaoManager {
  final _$PlaylistDaoMixin _db;
  PlaylistDaoManager(this._db);
  $$PlaylistsTableTableTableManager get playlistsTable =>
      $$PlaylistsTableTableTableManager(
        _db.attachedDatabase,
        _db.playlistsTable,
      );
  $$ServersTableTableTableManager get serversTable =>
      $$ServersTableTableTableManager(_db.attachedDatabase, _db.serversTable);
  $$TracksTableTableTableManager get tracksTable =>
      $$TracksTableTableTableManager(_db.attachedDatabase, _db.tracksTable);
  $$PlaylistTracksTableTableTableManager get playlistTracksTable =>
      $$PlaylistTracksTableTableTableManager(
        _db.attachedDatabase,
        _db.playlistTracksTable,
      );
}
