import '../entities/entities.dart';
import '../errors/result.dart';

/// Repository interface for server management operations
abstract class ServerRepository {
  /// Adds a new music server
  Future<Result<void>> addServer(MusicServer server);
  
  /// Removes a server by ID
  Future<Result<void>> removeServer(String serverId);
  
  /// Updates an existing server
  Future<Result<void>> updateServer(MusicServer server);
  
  /// Gets all configured servers
  Future<Result<List<MusicServer>>> getAllServers();
  
  /// Gets a server by ID
  Future<Result<MusicServer?>> getServerById(String serverId);
  
  /// Observes changes to the server list
  Stream<List<MusicServer>> observeServers();
  
  /// Tests connection to a server
  Future<Result<ServerConnectionResult>> testConnection(MusicServer server);
  
  /// Tests connection using server credentials
  Future<Result<ServerConnectionResult>> testConnectionWithCredentials({
    required String url,
    required String username,
    required String password,
  });
  
  /// Updates server status
  Future<Result<void>> updateServerStatus(String serverId, ServerStatus status);
  
  /// Updates server last sync time
  Future<Result<void>> updateLastSync(String serverId, DateTime lastSync);
  
  /// Gets all online servers
  Future<Result<List<MusicServer>>> getOnlineServers();
  
  /// Gets all offline servers
  Future<Result<List<MusicServer>>> getOfflineServers();
  
  /// Stores encrypted credentials for a server
  Future<Result<void>> storeCredentials(String serverId, String password);
  
  /// Retrieves encrypted credentials for a server
  Future<Result<String?>> getCredentials(String serverId);
  
  /// Removes stored credentials for a server
  Future<Result<void>> removeCredentials(String serverId);
}

/// Result of a server connection test
class ServerConnectionResult {
  const ServerConnectionResult({
    required this.isSuccessful,
    required this.serverInfo,
    this.errorMessage,
    this.responseTime,
  });

  final bool isSuccessful;
  final ServerInfo? serverInfo;
  final String? errorMessage;
  final Duration? responseTime;

  bool get hasError => !isSuccessful;
}

/// Information about a Subsonic server
class ServerInfo {
  const ServerInfo({
    required this.version,
    required this.apiVersion,
    required this.licenseValid,
    this.serverName,
    this.serverType,
  });

  final String version;
  final String apiVersion;
  final bool licenseValid;
  final String? serverName;
  final String? serverType;
}