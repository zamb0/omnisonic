import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/errors/errors.dart';

/// ViewModel for managing server connections and configuration
///
/// Handles:
/// - Server list management and status monitoring
/// - Adding, updating, and removing servers
/// - Connection testing and validation
/// - Server credentials management
@lazySingleton
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
  bool _isSaving = false;
  bool _isSyncingAll = false;
  String? _errorMessage;
  String? _actionError;
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

  /// Why the server list could not be loaded — a page-level state.
  String? get errorMessage => _errorMessage;

  /// Why the last add, save, remove, test or sync failed. Transient: shown
  /// inline by the dialog that caused it, or as a snackbar, then cleared.
  String? get actionError => _actionError;

  /// An add or save is in progress.
  bool get isSaving => _isSaving;

  /// A manual sync of every server is in progress.
  bool get isSyncingAll => _isSyncingAll;
  ServerConnectionResult? get lastConnectionTest => _lastConnectionTest;
  bool get hasServers => _servers.isNotEmpty;
  bool get hasOnlineServers => onlineServers.isNotEmpty;
  int get serverCount => _servers.length;
  int get onlineServerCount => onlineServers.length;
  int get offlineServerCount => offlineServers.length;

  /// The name a server gets when the user leaves Name empty: its host.
  static String defaultServerName(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? url : host;
  }

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
        AppLog.error('Server stream error: $error');
        _setError("Couldn't load your servers. Pull down to try again.");
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
        (failure) =>
            _setError(describeFailure(failure, action: 'load servers')),
        (servers) {
          _servers = servers;
          success = true;
        },
      );
    } catch (e) {
      AppLog.error('Loading servers failed: $e');
      _setError(describeUnexpected(action: 'load your servers'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  /// Adds a new server
  /// Adds a new server after testing the connection.
  ///
  /// Does not touch [isLoading]: that flag is the server *list* loading, and
  /// setting it here turned the list behind the Add dialog into a skeleton.
  /// On failure, [actionError] says why, for the dialog to show inline.
  Future<bool> addServer({
    required String name,
    required String url,
    required String username,
    required String password,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    try {
      final connection = await _test(
        url: url,
        username: username,
        password: password,
      );
      if (connection == null) return false;

      final server = MusicServer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty
            ? (connection.serverInfo?.serverName ?? defaultServerName(url))
            : name,
        url: url,
        username: username,
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        apiVersion: connection.serverInfo?.apiVersion,
        serverVersion: connection.serverInfo?.version,
      );

      final added = await _serverRepository.addServer(server);
      if (added.isLeft()) {
        _actionError = describeFailure(
          added.fold((f) => f, (_) => throw StateError('unreachable')),
          action: 'add the server',
        );
        return false;
      }

      final stored = await _serverRepository.storeCredentials(
        server.id,
        password,
      );
      if (stored.isLeft()) {
        // Without its password the server is unusable; keep things
        // consistent rather than leaving a half-added entry.
        await _serverRepository.removeServer(server.id);
        _actionError =
            "Couldn't store the password securely, so the server wasn't "
            'added. Try again.';
        return false;
      }

      AppLog.info('Starting automatic sync for new server');
      _triggerAutoSync(server.id);
      return true;
    } catch (e) {
      AppLog.error('Adding a server failed: $e');
      _actionError = describeUnexpected(action: 'add the server');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Tests a connection and turns a failure into [actionError]; null when
  /// the server cannot be reached or refuses the credentials.
  Future<ServerConnectionResult?> _test({
    required String url,
    required String username,
    required String password,
  }) async {
    final result = await _serverRepository.testConnectionWithCredentials(
      url: url,
      username: username,
      password: password,
    );
    return result.fold(
      (failure) {
        _actionError = describeFailure(
          failure,
          action: 'connect to the server',
        );
        return null;
      },
      (connection) {
        if (connection.isSuccessful) return connection;
        _actionError =
            "Couldn't connect to the server: "
            '${connection.errorMessage ?? 'check the URL and credentials.'}';
        return null;
      },
    );
  }

  /// Updates an existing server
  /// Saves changes to [server].
  ///
  /// When the URL, the username or the password changes, the connection is
  /// tested first — they used to be saved untested — using [newPassword] or
  /// the stored one. A new password is stored only once the test passes, so
  /// changing it no longer means deleting and re-adding the server (and
  /// losing its cache and sync state).
  Future<bool> updateServer(MusicServer server, {String? newPassword}) async {
    if (_isSaving) return false;
    _isSaving = true;
    _actionError = null;
    _setServerLoading(server.id, true);

    try {
      final previous = getServerById(server.id);
      final password = newPassword?.isNotEmpty == true ? newPassword : null;
      final needsTest =
          password != null ||
          previous == null ||
          previous.url != server.url ||
          previous.username != server.username;

      if (needsTest) {
        final testPassword =
            password ??
            (await _serverRepository.getCredentials(
              server.id,
            )).fold((_) => null, (stored) => stored);
        if (testPassword == null) {
          _actionError =
              "Couldn't read this server's saved password. Enter it again to "
              'save.';
          return false;
        }
        final connection = await _test(
          url: server.url,
          username: server.username,
          password: testPassword,
        );
        if (connection == null) return false;
      }

      final result = await _serverRepository.updateServer(server);
      if (result.isLeft()) {
        _actionError = describeFailure(
          result.fold((f) => f, (_) => throw StateError('unreachable')),
          action: 'save the server',
        );
        return false;
      }
      if (password != null) {
        final stored = await _serverRepository.storeCredentials(
          server.id,
          password,
        );
        if (stored.isLeft()) {
          _actionError =
              "The server was saved, but the new password couldn't be "
              'stored. Try again.';
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLog.error('Updating a server failed: $e');
      _actionError = describeUnexpected(action: 'save the server');
      return false;
    } finally {
      _isSaving = false;
      _setServerLoading(server.id, false);
    }
  }

  /// Removes a server
  /// Removes a server and its stored password.
  Future<bool> removeServer(String serverId) async {
    _setServerLoading(serverId, true);
    _actionError = null;

    try {
      await _serverRepository.removeCredentials(serverId);
      final result = await _serverRepository.removeServer(serverId);
      return result.fold<bool>((failure) {
        _actionError = describeFailure(failure, action: 'remove the server');
        return false;
      }, (_) => true);
    } catch (e) {
      AppLog.error('Removing a server failed: $e');
      _actionError = describeUnexpected(action: 'remove the server');
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
        _setError(describeFailure(failure, action: 'test the connection'));
        return null;
      }, (connectionResult) => connectionResult);

      // A passing test is the user's way out of a stale error badge; it used
      // to report "reachable" and leave the server marked error.
      if (_lastConnectionTest?.isSuccessful == true &&
          server.status != ServerStatus.online) {
        await _serverRepository.updateServerStatus(
          server.id,
          ServerStatus.online,
        );
      }

      return _lastConnectionTest;
    } catch (e) {
      AppLog.error('Connection test failed: $e');
      _setError(describeUnexpected(action: 'test the connection'));
      return null;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  /// Tests connection with credentials
  /// Tests a connection with credentials that are not saved yet.
  ///
  /// The result (or [actionError], on failure) is for the dialog to show
  /// inline; it no longer becomes the page's error.
  Future<ServerConnectionResult?> testConnectionWithCredentials({
    required String url,
    required String username,
    required String password,
  }) async {
    if (_isTestingConnection) return null;

    _isTestingConnection = true;
    _lastConnectionTest = null;
    _actionError = null;
    notifyListeners();

    try {
      _lastConnectionTest = await _test(
        url: url,
        username: username,
        password: password,
      );
      return _lastConnectionTest;
    } catch (e) {
      AppLog.error('Connection test failed: $e');
      _actionError = describeUnexpected(action: 'test the connection');
      return null;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  /// Gets a server by ID
  MusicServer? getServerById(String serverId) {
    for (final server in _servers) {
      if (server.id == serverId) return server;
    }
    return null;
  }

  /// The display name of [serverId], or the id itself when the server is
  /// unknown (removed, or not loaded yet).
  String serverNameFor(String serverId) =>
      getServerById(serverId)?.name ?? serverId;

  /// Checks if a server is currently loading
  bool isServerLoading(String serverId) {
    return _serverLoadingStates[serverId] ?? false;
  }

  /// Updates server status manually
  Future<void> updateServerStatus(String serverId, ServerStatus status) async {
    final result = await _serverRepository.updateServerStatus(serverId, status);
    result.fold(
      (failure) =>
          _setError(describeFailure(failure, action: 'update server status')),
      (_) => AppLog.debug('Server status updated to $status'),
    );
  }

  /// Updates server last sync time
  Future<void> updateLastSync(String serverId, DateTime lastSync) async {
    final result = await _serverRepository.updateLastSync(serverId, lastSync);
    result.fold(
      (failure) =>
          _setError(describeFailure(failure, action: 'update last sync')),
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
  /// Syncs every server, user-initiated. Completes with whether it worked;
  /// [isSyncingAll] is true meanwhile.
  ///
  /// It used to return at once and report only to the log, so the page
  /// showed "Syncing…" for two seconds and then nothing, success or not.
  Future<bool> syncAllServers() async {
    if (_isSyncingAll) return false;
    _isSyncingAll = true;
    notifyListeners();
    try {
      AppLog.info('Manual sync from all servers');
      await _recheckUnavailableServers();
      final result = await _syncMusicCollectionUseCase(
        SyncMusicCollectionParams(serverId: null, forceRefresh: true),
      );
      return result.fold<bool>(
        (failure) {
          AppLog.warn('Manual sync failed: ${failure.message}');
          _actionError = describeFailure(failure, action: 'sync your servers');
          return false;
        },
        (collection) {
          AppLog.info(
            'Manual sync completed: ${collection.tracks.length} tracks, '
            '${collection.albumCount} albums',
          );
          return true;
        },
      );
    } catch (e) {
      AppLog.warn('Manual sync error: $e');
      _actionError = describeUnexpected(action: 'sync your servers');
      return false;
    } finally {
      _isSyncingAll = false;
      notifyListeners();
    }
  }

  /// Re-tests every server not marked online and marks the ones that answer.
  ///
  /// The sync only reads online servers, so a server whose status was stale
  /// made Retry fail forever with "No online servers available".
  Future<void> _recheckUnavailableServers() async {
    final unavailable = _servers.where((s) => s.status != ServerStatus.online);
    await Future.wait([
      for (final server in unavailable)
        _serverRepository.testConnection(server).then((result) async {
          if (result.valueOrNull?.isSuccessful == true) {
            await _serverRepository.updateServerStatus(
              server.id,
              ServerStatus.online,
            );
          }
        }),
    ]);
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

  /// Clears [actionError] once it has been shown.
  void clearActionError() {
    if (_actionError == null) return;
    _actionError = null;
    notifyListeners();
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
