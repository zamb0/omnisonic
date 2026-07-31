// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_dao.dart';

// ignore_for_file: type=lint
mixin _$ServerDaoMixin on DatabaseAccessor<AppDatabase> {
  $ServersTableTable get serversTable => attachedDatabase.serversTable;
  ServerDaoManager get managers => ServerDaoManager(this);
}

class ServerDaoManager {
  final _$ServerDaoMixin _db;
  ServerDaoManager(this._db);
  $$ServersTableTableTableManager get serversTable =>
      $$ServersTableTableTableManager(_db.attachedDatabase, _db.serversTable);
}
