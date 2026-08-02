import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/utils/app_log.dart';

/// ViewModel for managing server connections and configuration
///
/// Handles:
/// - Server list management and status monitoring
/// - Adding, updating, and removing servers
/// - Connection testing and validation
/// - Server credentials management
@injectable
class ServerManagementViewModel extends ChangeNotifier {
  ServerManagementViewModel(
    this._serverRepository,
    this._syncMusicCollectionUseCase,
  ) {
    _initialize();
  }

  final ServerRepository _serverRepository;
  final SyncMusicCollectionUseCase _syncMusicCollectionUseCase;

  StreamSubscription<List<MusicServer>>? _serversSubscription;

  // State
  List<MusicServer> _servers = [];
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _errorMessage;
  ServerConnectionResult? _lastConnectionTest;
  final Map<String, bool> _serverLoadingStates = {};

  // Getters
  List<MusicServer> get servers => _servers;
  List<MusicServer> get onlineServers =>
      _servers.where((s) => s.status == ServerStatus.online).toList();
  List<MusicServer> get offlineServers =>
      _servers.where((s) => s.status == ServerStatus.offline).toList();
  List<MusicServer> get connectingServers =>
      _servers.where((s) => s.status == ServerStatus.connecting).toList();
  List<MusicServer> get errorServers =>
      _servers.where((s) => s.status == ServerStatus.error).toList();
  bool get isLoading => _isLoading;
  bool get isTestingConnection => _isTestingConnection;
  String? get errorMessage => _errorMessage;
  ServerConnectionResult? get lastConnectionTest => _lastConnectionTest;
  bool get hasServers => _servers.isNotEmpty;
  bool get hasOnlineServers => onlineServers.isNotEmpty;
  int get serverCount => _servers.length;
  int get onlineServerCount => onlineServers.length;
  int get offlineServerCount => offlineServers.length;

  void _initialize() {
    _subscribeToServers();
    _loadServers();
    // Kicks off the periodic reachability checks; without them every server
    // keeps whatever status it had when it was added.
    _serverRepository.startMonitoringAllServers();
  }

  void _subscribeToServers() {
    _serversSubscription = _serverRepository.observeServers().listen(
      (servers) {
        _servers = servers;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load servers: $error');
      },
    );
  }

  Future<bool> _loadServers() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    var success = false;
    try {
      final result = await _serverRepository.getAllServers();
      result.fold(
        (failure) => _setError('Failed to load servers: ${failure.message}'),
        (servers) {
          _servers = servers;
          success = true;
        },
      );
    } catch (e) {
      _setError('Unexpected error loading servers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  /// Adds a new server
  Future<bool> addServer({
    required String name,
    required String url,
    required String username,
    required String password,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // First test the connection
      final testResult = await _serverRepository.testConnectionWithCredentials(
        url: url,
        username: username,
        password: password,
      );

      final connectionResult = testResult.fold((failure) {
        _setError('Connection test failed: ${failure.message}');
        return null;
      }, (result) => result);

      if (connectionResult == null || !connectionResult.isSuccessful) {
        _setError(
          'Connection failed: ${connectionResult?.errorMessage ?? 'Unknown error'}',
        );
        return false;
      }

      // Create the server entity
      final server = MusicServer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        username: username,
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        apiVersion: connectionResult.serverInfo?.apiVersion,
        serverVersion: connectionResult.serverInfo?.version,
      );

      // Add the server
      final addResult = await _serverRepository.addServer(server);
      final addSuccess = addResult.fold((failure) {
        _setError('Failed to add server: ${failure.message}');
        return false;
      }, (_) => true);

      if (!addSuccess) return false;

      // Store credentials
      final credentialsResult = await _serverRepository.storeCredentials(
        server.id,
        password,
      );
      final credentialsSuccess = credentialsResult.fold((failure) {
        // If credential storage fails, remove the server to maintain consistency
        _serverRepository.removeServer(server.id);
        _setError('Failed to store credentials securely: ${failure.message}');
        return false;
      }, (_) => true);

      if (!credentialsSuccess) {
        return false;
      }

      _clearError();

      // Automatically sync the music collection from the new server
      AppLog.info('Starting automatic sync for new server');
      _triggerAutoSync(server.id);

      return true;
    } catch (e) {
      _setError('Unexpected error adding server: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing server
  Future<bool> updateServer(MusicServer server) async {
    if (_isLoading) return false;

    _setServerLoading(server.id, true);
    _clearError();

    try {
      final result = await _serverRepository.updateServer(server);
      return result.fold((failure) {
        _setError('Failed to update server: ${failure.message}');
        return false;
      }, (_) => true);
    } catch (e) {
      _setError('Unexpected error updating server: $e');
      return false;
    } finally {
      _setServerLoading(server.id, false);
    }
  }

  /// Removes a server
  Future<bool> removeServer(String serverId) async {
    if (_isLoading) return false;

    _setServerLoading(serverId, true);
    _clearError();

    try {
      // Remove credentials first
      await _serverRepository.removeCredentials(serverId);

      // Remove the server
      final result = await _serverRepository.removeServer(serverId);
      return result.fold((failure) {
        _setError('Failed to remove server: ${failure.message}');
        return false;
      }, (_) => true);
    } catch (e) {
      _setError('Unexpected error removing server: $e');
      return false;
    } finally {
      _setServerLoading(serverId, false);
    }
  }

  /// Tests connection to a server
  Future<ServerConnectionResult?> testConnection(MusicServer server) async {
    if (_isTestingConnection) return null;

    _isTestingConnection = true;
    _lastConnectionTest = null;
    _clearError();
    notifyListeners();

    try {
      final result = await _serverRepository.testConnection(server);

      _lastConnectionTest = result.fold((failure) {
        _setError('Connection test failed: ${failure.message}');
        return null;
      }, (connectionResult) => connectionResult);

      return _lastConnectionTest;
    } catch (e) {
      _setError('Unexpected error testing connection: $e');
      return null;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  /// Tests connection with credentials
  Future<ServerConnectionResult?> testConnectionWithCredentials({
    required String url,
    required String username,
    required String password,
  }) async {
    if (_isTestingConnection) return null;

    _isTestingConnection = true;
    _lastConnectionTest = null;
    _clearError();
    notifyListeners();

    try {
      final result = await _serverRepository.testConnectionWithCredentials(
        url: url,
        username: username,
        password: password,
      );

      _lastConnectionTest = result.fold((failure) {
        _setError('Connection test failed: ${failure.message}');
        return null;
      }, (connectionResult) => connectionResult);

      return _lastConnectionTest;
    } catch (e) {
      _setError('Unexpected error testing connection: $e');
      return null;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  /// Gets a server by ID
  MusicServer? getServerById(String serverId) {
    try {
      return _servers.firstWhere((server) => server.id == serverId);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a server is currently loading
  bool isServerLoading(String serverId) {
    return _serverLoadingStates[serverId] ?? false;
  }

  /// Updates server status manually
  Future<void> updateServerStatus(String serverId, ServerStatus status) async {
    final result = await _serverRepository.updateServerStatus(serverId, status);
    result.fold(
      (failure) =>
          _setError('Failed to update server status: ${failure.message}'),
      (_) => AppLog.debug('Server status updated to $status'),
    );
  }

  /// Updates server last sync time
  Future<void> updateLastSync(String serverId, DateTime lastSync) async {
    final result = await _serverRepository.updateLastSync(serverId, lastSync);
    result.fold(
      (failure) => _setError('Failed to update last sync: ${failure.message}'),
      (_) => AppLog.debug('Server last sync updated'),
    );
  }

  /// Refreshes the server list. Returns whether the refresh succeeded, so
  /// callers can show a terminal success/error message with retry.
  Future<bool> refreshServers() async {
    return _loadServers();
  }

  /// Triggers automatic synchronization for a server (non-blocking)
  void _triggerAutoSync(String serverId) {
    // Run sync in background without blocking the UI
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        AppLog.info('Auto-syncing from server: $serverId');
        final params = SyncMusicCollectionParams(
          serverId: serverId,
          forceRefresh: false,
        );

        final result = await _syncMusicCollectionUseCase(params);
        result.fold(
          (failure) {
            AppLog.warn('Auto-sync failed: ${failure.message}');
            // Don't show error to user for background sync
          },
          (collection) {
            AppLog.info(
              'Auto-sync completed: ${collection.tracks.length} tracks, ${collection.albumCount} albums',
            );
          },
        );
      } catch (e) {
        AppLog.warn('Auto-sync error: $e');
      }
    });
  }

  /// Manually sync all servers (user-initiated)
  void syncAllServers() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        AppLog.info('Manual sync from all servers');
        final params = SyncMusicCollectionParams(
          serverId: null, // Sync from all servers
          forceRefresh: true, // Force refresh for manual sync
        );

        final result = await _syncMusicCollectionUseCase(params);
        result.fold(
          (failure) {
            AppLog.warn('Manual sync failed: ${failure.message}');
          },
          (collection) {
            AppLog.info(
              'Manual sync completed: ${collection.tracks.length} tracks, ${collection.albumCount} albums',
            );
          },
        );
      } catch (e) {
        AppLog.warn('Manual sync error: $e');
      }
    });
  }

  /// Gets server statistics
  Map<String, int> getServerStatistics() {
    return {
      'total': serverCount,
      'online': onlineServerCount,
      'offline': offlineServerCount,
      'connecting': connectingServers.length,
      'error': errorServers.length,
    };
  }

  void _setServerLoading(String serverId, bool loading) {
    _serverLoadingStates[serverId] = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clears the current error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Clears the last connection test result
  void clearConnectionTest() {
    _lastConnectionTest = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _serversSubscription?.cancel();
    super.dispose();
  }
}
