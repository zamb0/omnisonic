import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import '../../entities/music_server.dart';
import '../../entities/server_status.dart';

part 'server_dao.g.dart';

@DriftAccessor(tables: [ServersTable])
class ServerDao extends DatabaseAccessor<AppDatabase> with _$ServerDaoMixin {
  ServerDao(super.db);

  // Convert between entity and database models
  MusicServer _fromData(ServerData data) {
    return MusicServer(
      id: data.id,
      name: data.name,
      url: data.url,
      username: data.username,
      status: data.status,
      createdAt: data.createdAt,
      lastSync: data.lastSync,
      apiVersion: data.apiVersion,
      serverVersion: data.serverVersion,
      errorMessage: data.errorMessage,
    );
  }

  ServersTableCompanion _toCompanion(
    MusicServer server, {
    String? encryptedPassword,
  }) {
    return ServersTableCompanion(
      id: Value(server.id),
      name: Value(server.name),
      url: Value(server.url),
      username: Value(server.username),
      encryptedPassword: encryptedPassword != null
          ? Value(encryptedPassword)
          : const Value.absent(),
      status: Value(server.status),
      createdAt: Value(server.createdAt),
      lastSync: Value.absentIfNull(server.lastSync),
      apiVersion: Value.absentIfNull(server.apiVersion),
      serverVersion: Value.absentIfNull(server.serverVersion),
      errorMessage: Value.absentIfNull(server.errorMessage),
    );
  }

  // CRUD operations
  Future<List<MusicServer>> getAllServers() async {
    final data = await select(serversTable).get();
    return data.map(_fromData).toList();
  }

  Future<MusicServer?> getServerById(String id) async {
    final data = await (select(
      serversTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return data != null ? _fromData(data) : null;
  }

  Future<List<MusicServer>> getOnlineServers() async {
    final data = await (select(
      serversTable,
    )..where((tbl) => tbl.status.equals(ServerStatus.online.name))).get();
    return data.map(_fromData).toList();
  }

  Future<void> insertServer(
    MusicServer server,
    String encryptedPassword,
  ) async {
    await into(
      serversTable,
    ).insert(_toCompanion(server, encryptedPassword: encryptedPassword));
  }

  Future<void> updateServer(
    MusicServer server, {
    String? encryptedPassword,
  }) async {
    await (update(serversTable)..where((tbl) => tbl.id.equals(server.id)))
        .write(_toCompanion(server, encryptedPassword: encryptedPassword));
  }

  Future<void> updateServerStatus(
    String serverId,
    ServerStatus status, {
    String? errorMessage,
  }) async {
    await (update(serversTable)..where((tbl) => tbl.id.equals(serverId))).write(
      ServersTableCompanion(
        status: Value(status),
        errorMessage: Value.absentIfNull(errorMessage),
      ),
    );
  }

  Future<void> updateServerLastSync(String serverId, DateTime lastSync) async {
    await (update(serversTable)..where((tbl) => tbl.id.equals(serverId))).write(
      ServersTableCompanion(lastSync: Value(lastSync)),
    );
  }

  Future<void> deleteServer(String id) async {
    await (delete(serversTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Watch for changes
  Stream<List<MusicServer>> watchAllServers() {
    return select(
      serversTable,
    ).watch().map((data) => data.map(_fromData).toList());
  }

  Stream<MusicServer?> watchServerById(String id) {
    return (select(serversTable)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull()
        .map((data) => data != null ? _fromData(data) : null);
  }
}
