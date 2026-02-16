// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_dao.dart';

// ignore_for_file: type=lint
mixin _$CacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $ServersTableTable get serversTable => attachedDatabase.serversTable;
  $TracksTableTable get tracksTable => attachedDatabase.tracksTable;
  $CacheEntriesTableTable get cacheEntriesTable =>
      attachedDatabase.cacheEntriesTable;
  CacheDaoManager get managers => CacheDaoManager(this);
}

class CacheDaoManager {
  final _$CacheDaoMixin _db;
  CacheDaoManager(this._db);
  $$ServersTableTableTableManager get serversTable =>
      $$ServersTableTableTableManager(_db.attachedDatabase, _db.serversTable);
  $$TracksTableTableTableManager get tracksTable =>
      $$TracksTableTableTableManager(_db.attachedDatabase, _db.tracksTable);
  $$CacheEntriesTableTableTableManager get cacheEntriesTable =>
      $$CacheEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.cacheEntriesTable,
      );
}
