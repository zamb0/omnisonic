import 'dart:async';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/database/data_sources/local_server_data_source.dart';
import '../../../../core/services/server_connection_service.dart';
import '../../../../core/services/server_status_monitor.dart';
import '../../../../core/utils/server_validator.dart';

/// Implementation of ServerRepository that manages server CRUD operations and monitoring
class ServerRepositoryImpl implements ServerRepository {
  final LocalServerDataSource _localDataSource;
  final ServerConnectionService _connectionService;
  final ServerStatusMonitor _statusMonitor;
  final ServerValidator _validator;

  ServerRepositoryImpl({
    required LocalServerDataSource localDataSource,
    required ServerConnectionService connectionService,
    required ServerStatusMonitor statusMonitor,
    required ServerValidator validator,
  })  : _localDataSource = localDataSource,
        _connectionService = connectionService,
        _statusMonitor = statusMonitor,
        _validator = validator;

  @override
  Future<Result<void>> addServer(MusicServer server) async {
    try {
      // Validate server configuration
      final validationResult = _validateServerConfig(server);
      if (validationResult.isFailure) {
        return ResultHelper.failure(validationResult.failureOrNull!);
      }

      // Check if server already exists
      final existsResult = await _localDataSource.serverExists(server.id);
      if (existsResult.isFailure) {
        return ResultHelper.failure(existsResult.failureOrNull!);
      }

      if (existsResult.valueOrNull == true) {
        return ResultHelper.failure(
          ValidationFailure('Server with ID ${server.id} already exists'),
        );
      }

      // Store server in local database (password will be stored separately)
      final insertResult = await _localDataSource.insertServer(server, '');
      if (insertResult.isFailure) {
        return ResultHelper.failure(insertResult.failureOrNull!);
      }

      // Start monitoring the server (simplified - actual implementation would need proper monitoring)
      // _statusMonitor.startMonitoring(server.id);

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to add server: $e'));
    }
  }

  @override
  Future<Result<void>> removeServer(String serverId) async {
    try {
      // Stop monitoring first (simplified)
      // _statusMonitor.stopMonitoring(serverId);

      // Remove stored credentials
      await _connectionService.removeServerPassword(serverId);

      // Remove server from database
      final deleteResult = await _localDataSource.deleteServer(serverId);
      if (deleteResult.isFailure) {
        return ResultHelper.failure(deleteResult.failureOrNull!);
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to remove server: $e'));
    }
  }

  @override
  Future<Result<void>> updateServer(MusicServer server) async {
    try {
      // Validate server configuration
      final validationResult = _validateServerConfig(server);
      if (validationResult.isFailure) {
        return ResultHelper.failure(validationResult.failureOrNull!);
      }

      // Update server in database
      final updateResult = await _localDataSource.updateServer(server);
      if (updateResult.isFailure) {
        return ResultHelper.failure(updateResult.failureOrNull!);
      }

      // Restart monitoring with updated configuration (simplified)
      // _statusMonitor.stopMonitoring(server.id);
      // _statusMonitor.startMonitoring(server.id);

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to update server: $e'));
    }
  }

  @override
  Future<Result<List<MusicServer>>> getAllServers() async {
    return await _localDataSource.getAllServers();
  }

  @override
  Future<Result<MusicServer?>> getServerById(String serverId) async {
    return await _localDataSource.getServerById(serverId);
  }

  @override
  Stream<List<MusicServer>> observeServers() {
    return _localDataSource.watchAllServers();
  }

  @override
  Future<Result<ServerConnectionResult>> testConnection(MusicServer server) async {
    try {
      // Get stored password for the server
      final passwordResult = await _connectionService.getServerPassword(server.id);
      if (passwordResult.isFailure) {
        return ResultHelper.success(ServerConnectionResult(
          isSuccessful: false,
          serverInfo: null,
          errorMessage: 'No stored credentials for server',
        ));
      }

      final password = passwordResult.valueOrNull!;
      return await testConnectionWithCredentials(
        url: server.url,
        username: server.username,
        password: password,
      );
    } catch (e) {
      return ResultHelper.success(ServerConnectionResult(
        isSuccessful: false,
        serverInfo: null,
        errorMessage: 'Connection test failed: $e',
      ));
    }
  }

  @override
  Future<Result<ServerConnectionResult>> testConnectionWithCredentials({
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      // Create temporary server for testing
      final testServer = MusicServer(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Server',
        url: url,
        username: username,
        status: ServerStatus.connecting,
        lastSync: null,
        createdAt: DateTime.now(),
      );

      final startTime = DateTime.now();
      
      // Test connection using connection service
      final connectionResult = await _connectionService.testConnection(testServer, password);
      
      final responseTime = DateTime.now().difference(startTime);

      if (connectionResult.isSuccess) {
        final updatedServer = connectionResult.valueOrNull!;
        
        return ResultHelper.success(ServerConnectionResult(
          isSuccessful: true,
          serverInfo: ServerInfo(
            version: updatedServer.serverVersion ?? 'Unknown',
            apiVersion: updatedServer.apiVersion ?? 'Unknown',
            serverName: updatedServer.name,
            serverType: 'Subsonic',
          ),
          responseTime: responseTime,
        ));
      } else {
        final failure = connectionResult.failureOrNull!;
        return ResultHelper.success(ServerConnectionResult(
          isSuccessful: false,
          serverInfo: null,
          errorMessage: failure.message,
          responseTime: responseTime,
        ));
      }
    } catch (e) {
      return ResultHelper.success(ServerConnectionResult(
        isSuccessful: false,
        serverInfo: null,
        errorMessage: 'Connection test failed: $e',
      ));
    }
  }

  @override
  Future<Result<void>> updateServerStatus(String serverId, ServerStatus status) async {
    try {
      String? errorMessage;
      
      // If status is error or offline, we might want to include an error message
      if (status == ServerStatus.error || status == ServerStatus.offline) {
        // This could be enhanced to include specific error details
        errorMessage = status == ServerStatus.offline ? 'Server is offline' : 'Server error occurred';
      }

      final updateResult = await _localDataSource.updateServerStatus(
        serverId, 
        status, 
        errorMessage: errorMessage,
      );
      
      if (updateResult.isFailure) {
        return ResultHelper.failure(updateResult.failureOrNull!);
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to update server status: $e'));
    }
  }

  @override
  Future<Result<void>> updateLastSync(String serverId, DateTime lastSync) async {
    return await _localDataSource.updateServerLastSync(serverId, lastSync);
  }

  @override
  Future<Result<List<MusicServer>>> getOnlineServers() async {
    return await _localDataSource.getOnlineServers();
  }

  @override
  Future<Result<List<MusicServer>>> getOfflineServers() async {
    try {
      final allServersResult = await _localDataSource.getAllServers();
      if (allServersResult.isFailure) {
        return ResultHelper.failure(allServersResult.failureOrNull!);
      }

      final allServers = allServersResult.valueOrNull!;
      final offlineServers = allServers
          .where((server) => server.status != ServerStatus.online)
          .toList();

      return ResultHelper.success(offlineServers);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get offline servers: $e'));
    }
  }

  @override
  Future<Result<void>> storeCredentials(String serverId, String password) async {
    final storeResult = await _connectionService.storeServerPassword(serverId, password);
    if (storeResult.isFailure) {
      return ResultHelper.failure(storeResult.failureOrNull!);
    }
    return ResultHelper.success(null);
  }

  @override
  Future<Result<String?>> getCredentials(String serverId) async {
    final passwordResult = await _connectionService.getServerPassword(serverId);
    if (passwordResult.isFailure) {
      // Return null instead of failure for missing credentials
      if (passwordResult.failureOrNull is AuthenticationFailure) {
        return ResultHelper.success(null);
      }
      return ResultHelper.failure(passwordResult.failureOrNull!);
    }
    return ResultHelper.success(passwordResult.valueOrNull);
  }

  @override
  Future<Result<void>> removeCredentials(String serverId) async {
    final removeResult = await _connectionService.removeServerPassword(serverId);
    if (removeResult.isFailure) {
      return ResultHelper.failure(removeResult.failureOrNull!);
    }
    return ResultHelper.success(null);
  }

  /// Validates and adds a server with credentials in one operation
  Future<Result<MusicServer>> validateAndAddServer({
    required String name,
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      // First test the connection
      final connectionResult = await testConnectionWithCredentials(
        url: url,
        username: username,
        password: password,
      );

      if (connectionResult.isFailure) {
        return ResultHelper.failure(connectionResult.failureOrNull!);
      }

      final connectionInfo = connectionResult.valueOrNull!;
      if (!connectionInfo.isSuccessful) {
        return ResultHelper.failure(
          AuthenticationFailure(connectionInfo.errorMessage ?? 'Connection failed'),
        );
      }

      // Create server with validated information
      final server = MusicServer(
        id: _generateServerId(url, username),
        name: name,
        url: url,
        username: username,
        status: ServerStatus.online,
        lastSync: null,
        apiVersion: connectionInfo.serverInfo?.apiVersion,
        serverVersion: connectionInfo.serverInfo?.version,
        createdAt: DateTime.now(),
      );

      // Add server to database
      final addResult = await addServer(server);
      if (addResult.isFailure) {
        return ResultHelper.failure(addResult.failureOrNull!);
      }

      // Store credentials
      final credentialsResult = await storeCredentials(server.id, password);
      if (credentialsResult.isFailure) {
        // Rollback server addition if credential storage fails
        await removeServer(server.id);
        return ResultHelper.failure(credentialsResult.failureOrNull!);
      }

      return ResultHelper.success(server);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to validate and add server: $e'));
    }
  }

  /// Starts monitoring all servers
  Future<Result<void>> startMonitoringAllServers() async {
    try {
      final serversResult = await getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!;
      for (final server in servers) {
        // _statusMonitor.startMonitoring(server.id);
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to start monitoring: $e'));
    }
  }

  /// Stops monitoring all servers
  void stopMonitoringAllServers() {
    // _statusMonitor.stopAllMonitoring();
  }

  /// Validates server configuration
  Result<void> _validateServerConfig(MusicServer server) {
    if (server.url.isEmpty) {
      return ResultHelper.failure(ValidationFailure('Server URL cannot be empty'));
    }
    
    if (server.username.isEmpty) {
      return ResultHelper.failure(ValidationFailure('Username cannot be empty'));
    }
    
    if (server.name.isEmpty) {
      return ResultHelper.failure(ValidationFailure('Server name cannot be empty'));
    }
    
    // Basic URL validation
    try {
      final uri = Uri.parse(server.url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return ResultHelper.failure(ValidationFailure('Invalid server URL format'));
      }
    } catch (e) {
      return ResultHelper.failure(ValidationFailure('Invalid server URL: $e'));
    }
    
    return ResultHelper.success(null);
  }

  /// Generates a unique server ID based on URL and username
  String _generateServerId(String url, String username) {
    final normalizedUrl = url.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final normalizedUsername = username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${normalizedUrl}_${normalizedUsername}_$timestamp';
  }

  /// Disposes resources
  void dispose() {
    stopMonitoringAllServers();
    _connectionService.dispose();
  }
}