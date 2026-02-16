// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_dao.dart';

// ignore_for_file: type=lint
mixin _$MusicDaoMixin on DatabaseAccessor<AppDatabase> {
  $ServersTableTable get serversTable => attachedDatabase.serversTable;
  $TracksTableTable get tracksTable => attachedDatabase.tracksTable;
  $AlbumsTableTable get albumsTable => attachedDatabase.albumsTable;
  $ArtistsTableTable get artistsTable => attachedDatabase.artistsTable;
  MusicDaoManager get managers => MusicDaoManager(this);
}

class MusicDaoManager {
  final _$MusicDaoMixin _db;
  MusicDaoManager(this._db);
  $$ServersTableTableTableManager get serversTable =>
      $$ServersTableTableTableManager(_db.attachedDatabase, _db.serversTable);
  $$TracksTableTableTableManager get tracksTable =>
      $$TracksTableTableTableManager(_db.attachedDatabase, _db.tracksTable);
  $$AlbumsTableTableTableManager get albumsTable =>
      $$AlbumsTableTableTableManager(_db.attachedDatabase, _db.albumsTable);
  $$ArtistsTableTableTableManager get artistsTable =>
      $$ArtistsTableTableTableManager(_db.attachedDatabase, _db.artistsTable);
}
