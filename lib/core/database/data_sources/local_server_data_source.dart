import '../app_database.dart';
import '../../entities/music_server.dart';
import '../../entities/server_status.dart';
import '../../errors/result.dart';
import '../../errors/failures.dart';

/// Local data source for server operations
class LocalServerDataSource {
  const LocalServerDataSource(this._database);

  final AppDatabase _database;

  /// Get all servers from local database
  Future<Result<List<MusicServer>>> getAllServers() async {
    try {
      final servers = await _database.serverDao.getAllServers();
      return ResultHelper.success(servers);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get servers: $e'));
    }
  }

  /// Get server by ID from local database
  Future<Result<MusicServer?>> getServerById(String id) async {
    try {
      final server = await _database.serverDao.getServerById(id);
      return ResultHelper.success(server);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get server: $e'));
    }
  }

  /// Get all online servers
  Future<Result<List<MusicServer>>> getOnlineServers() async {
    try {
      final servers = await _database.serverDao.getOnlineServers();
      return ResultHelper.success(servers);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to get online servers: $e'),
      );
    }
  }

  /// Insert server into local database
  Future<Result<void>> insertServer(
    MusicServer server,
    String encryptedPassword,
  ) async {
    try {
      await _database.serverDao.insertServer(server, encryptedPassword);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to insert server: $e'),
      );
    }
  }

  /// Update server in local database
  Future<Result<void>> updateServer(
    MusicServer server, {
    String? encryptedPassword,
  }) async {
    try {
      await _database.serverDao.updateServer(
        server,
        encryptedPassword: encryptedPassword,
      );
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update server: $e'),
      );
    }
  }

  /// Update server status
  Future<Result<void>> updateServerStatus(
    String serverId,
    ServerStatus status, {
    String? errorMessage,
  }) async {
    try {
      await _database.serverDao.updateServerStatus(
        serverId,
        status,
        errorMessage: errorMessage,
      );
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update server status: $e'),
      );
    }
  }

  /// Update server last sync time
  Future<Result<void>> updateServerLastSync(
    String serverId,
    DateTime lastSync,
  ) async {
    try {
      await _database.serverDao.updateServerLastSync(serverId, lastSync);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to update server last sync: $e'),
      );
    }
  }

  /// Delete server from local database
  Future<Result<void>> deleteServer(String id) async {
    try {
      await _database.serverDao.deleteServer(id);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to delete server: $e'),
      );
    }
  }

  /// Watch all servers for changes
  Stream<List<MusicServer>> watchAllServers() {
    return _database.serverDao.watchAllServers();
  }

  /// Watch specific server for changes
  Stream<MusicServer?> watchServerById(String id) {
    return _database.serverDao.watchServerById(id);
  }

  /// Check if server exists
  Future<Result<bool>> serverExists(String id) async {
    try {
      final server = await _database.serverDao.getServerById(id);
      return ResultHelper.success(server != null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to check server existence: $e'),
      );
    }
  }

  /// Clear all server data (for testing/reset purposes)
  Future<Result<void>> clearAllServers() async {
    try {
      final servers = await _database.serverDao.getAllServers();
      for (final server in servers) {
        await _database.serverDao.deleteServer(server.id);
      }
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure('Failed to clear servers: $e'),
      );
    }
  }
}
