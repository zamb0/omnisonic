import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_log.dart';
import '../entities/music_server.dart';
import '../entities/server_status.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../utils/password_encryption.dart';
import '../database/app_database.dart';
import 'subsonic_api_client.dart';

/// Service for managing server connections, authentication, and credential storage
class ServerConnectionService {
  final SubsonicApiClient _apiClient;
  final FlutterSecureStorage? _secureStorage;
  final AppDatabase _database;
  final Map<String, String> _passwordCache = {};
  final Map<String, Timer> _connectionTimers = {};

  // Flag to track if secure storage is available
  bool _secureStorageAvailable = true;

  static const String _passwordPrefix = 'server_password_';
  static const Duration _connectionTestInterval = Duration(minutes: 5);

  ServerConnectionService({
    SubsonicApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
    required AppDatabase database,
  }) : _apiClient = apiClient ?? SubsonicApiClient(),
       _secureStorage = secureStorage ?? _createSecureStorage(),
       _database = database;

  /// Creates secure storage with fallback for development
  static FlutterSecureStorage? _createSecureStorage() {
    try {
      return const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
        lOptions: LinuxOptions(),
        wOptions: WindowsOptions(),
        mOptions: MacOsOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
          synchronizable: false,
        ),
      );
    } catch (e) {
      AppLog.warn('Secure storage not available: $e');
      return null;
    }
  }

  /// Tests connection to a server and validates credentials
  Future<Result<MusicServer>> testConnection(
    MusicServer server,
    String password,
  ) async {
    try {
      // Validate server URL format
      if (!server.isValid) {
        return ResultHelper.failure(
          ValidationFailure('Invalid server configuration'),
        );
      }

      // Test connection with ping
      final response = await _apiClient.ping(server, password);

      if (!response.isSuccess) {
        final error = response.error;
        if (error != null) {
          return ResultHelper.failure(_mapSubsonicError(error));
        } else {
          return ResultHelper.failure(ServerFailure('Unknown server error'));
        }
      }

      // Extract server information from response
      final serverInfo = response.subsonicResponse;
      final updatedServer = server.copyWith(
        status: ServerStatus.online,
        lastSync: DateTime.now(),
        apiVersion: serverInfo.version,
        serverVersion: serverInfo.serverVersion,
        errorMessage: null,
      );

      return ResultHelper.success(updatedServer);
    } catch (e) {
      final failure = _mapException(e);
      return ResultHelper.failure(failure);
    }
  }

  /// Stores encrypted password for a server
  Future<Result<void>> storeServerPassword(
    String serverId,
    String password,
  ) async {
    AppLog.info('Storing password for server: $serverId');

    // Always cache in memory first
    _passwordCache[serverId] = password;

    // Try secure storage first (most secure)
    if (_secureStorage != null && _secureStorageAvailable) {
      try {
        await _secureStorage.write(
          key: '$_passwordPrefix$serverId',
          value: password,
        );

        AppLog.info('Password stored in secure storage');
        return ResultHelper.success(null);
      } catch (e) {
        AppLog.warn('Secure storage write failed: $e');
        _secureStorageAvailable = false;

        // Don't return failure yet, try database fallback
        AppLog.info('Falling back to database storage');
      }
    }

    // Fallback to encrypted database storage
    try {
      final encryptedPassword = PasswordEncryption.encryptPassword(password);

      // Update the server record with encrypted password
      final server = await _database.getServerById(serverId);
      if (server != null) {
        await _database.updateServer(
          server
              .copyWith(encryptedPassword: encryptedPassword)
              .toCompanion(false),
        );
        AppLog.info('Password stored in encrypted database');

        // Verify by reading it back immediately
        final verifyServer = await _database.getServerById(serverId);
        if (verifyServer != null && verifyServer.encryptedPassword.isNotEmpty) {
          try {
            final testDecrypt = PasswordEncryption.decryptPassword(
              verifyServer.encryptedPassword,
            );
            if (testDecrypt != password) {
              AppLog.warn(
                'Password verification failed after database storage',
              );
            }
          } catch (e) {
            AppLog.warn('Password verification failed: $e');
          }
        }

        return ResultHelper.success(null);
      } else {
        AppLog.warn(
          'Server not found in database for password storage: $serverId',
        );
        return ResultHelper.failure(
          DatabaseFailure('Server not found for password storage'),
        );
      }
    } catch (e) {
      AppLog.error('Database password storage failed: $e');
      return ResultHelper.failure(
        CacheFailure('Failed to store password: ${e.toString()}'),
      );
    }
  }

  /// Retrieves stored password for a server
  Future<Result<String>> getServerPassword(String serverId) async {
    AppLog.info('Retrieving password for server: $serverId');

    // Check memory cache first
    if (_passwordCache.containsKey(serverId)) {
      AppLog.debug('Password found in memory cache');
      return ResultHelper.success(_passwordCache[serverId]!);
    }

    // Try secure storage if available
    if (_secureStorage != null && _secureStorageAvailable) {
      try {
        final password = await _secureStorage.read(
          key: '$_passwordPrefix$serverId',
        );

        if (password != null) {
          AppLog.info('Password retrieved from secure storage');
          // Cache in memory
          _passwordCache[serverId] = password;
          return ResultHelper.success(password);
        } else {
          AppLog.warn(
            'No password found in secure storage for server: $serverId',
          );
        }
      } catch (e) {
        AppLog.warn('Failed to retrieve from secure storage: $e');
        _secureStorageAvailable = false;
      }
    } else if (_secureStorage == null) {
      AppLog.warn('Secure storage not available');
    } else {
      AppLog.warn('Secure storage disabled due to previous errors');
    }

    // Fallback to encrypted database storage
    try {
      AppLog.info('Falling back to database password storage');
      final server = await _database.getServerById(serverId);

      if (server != null && server.encryptedPassword.isNotEmpty) {
        final decryptedPassword = PasswordEncryption.decryptPassword(
          server.encryptedPassword,
        );
        AppLog.info('Password retrieved from encrypted database');

        // Cache in memory
        _passwordCache[serverId] = decryptedPassword;
        return ResultHelper.success(decryptedPassword);
      } else {
        AppLog.warn(
          'No encrypted password found in database for server: $serverId',
        );
      }
    } catch (e) {
      AppLog.error('Failed to retrieve password from database: $e');
    }

    AppLog.warn('No stored password found for server: $serverId');
    return ResultHelper.failure(
      AuthenticationFailure('No stored password found for server $serverId'),
    );
  }

  /// Removes stored password for a server
  Future<Result<void>> removeServerPassword(String serverId) async {
    try {
      // Remove from secure storage
      if (_secureStorage != null) {
        await _secureStorage.delete(key: '$_passwordPrefix$serverId');
      }

      // Remove from memory cache
      _passwordCache.remove(serverId);

      // Remove from database
      final server = await _database.getServerById(serverId);
      if (server != null) {
        await _database.updateServer(
          server.copyWith(encryptedPassword: '').toCompanion(false),
        );
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to remove server password: $e'),
      );
    }
  }

  /// Validates server configuration and credentials
  Future<Result<MusicServer>> validateServer(
    MusicServer server,
    String password,
  ) async {
    // First validate the server configuration
    if (!server.isValid) {
      return ResultHelper.failure(
        ValidationFailure('Invalid server configuration'),
      );
    }

    // Test the connection
    final connectionResult = await testConnection(server, password);

    if (connectionResult.isFailure) {
      return connectionResult;
    }

    // Store the password if connection is successful
    final storeResult = await storeServerPassword(server.id, password);
    if (storeResult.isFailure) {
      return ResultHelper.failure(storeResult.failureOrNull!);
    }

    return connectionResult;
  }

  /// Starts monitoring connection status for a server
  void startConnectionMonitoring(String serverId) {
    // Cancel existing timer if any
    _connectionTimers[serverId]?.cancel();

    // Start periodic connection testing
    _connectionTimers[serverId] = Timer.periodic(
      _connectionTestInterval,
      (timer) => _testServerConnection(serverId),
    );
  }

  /// Stops monitoring connection status for a server
  void stopConnectionMonitoring(String serverId) {
    _connectionTimers[serverId]?.cancel();
    _connectionTimers.remove(serverId);
  }

  /// Tests server connection in background
  Future<void> _testServerConnection(String serverId) async {
    try {
      final passwordResult = await getServerPassword(serverId);
      if (passwordResult.isFailure) {
        return; // Can't test without password
      }

      // This would need to be integrated with a server repository
      // to get the current server instance and update its status
      // For now, this is a placeholder for the monitoring logic
    } catch (e) {
      // Log error but don't throw - this is background monitoring
    }
  }

  /// Maps Subsonic API errors to domain failures
  Failure _mapSubsonicError(dynamic error) {
    if (error.code == 40) {
      return AuthenticationFailure('Invalid username or password');
    } else if (error.code == 50) {
      return AuthenticationFailure('User not authorized for operation');
    } else if (error.code == 60) {
      return ServerFailure('Trial period expired');
    } else if (error.code == 70) {
      return ServerFailure('Requested data not found');
    } else {
      return ServerFailure('Server error: ${error.message}');
    }
  }

  /// Maps exceptions to domain failures
  Failure _mapException(dynamic exception) {
    if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception.code);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message, exception.code);
    } else if (exception is ServerException) {
      return ServerFailure(exception.message, exception.code);
    } else if (exception is SubsonicApiException) {
      return ServerFailure(exception.message, exception.code);
    } else {
      return UnknownFailure('Unexpected error: $exception');
    }
  }

  /// Checks if secure storage is available and working
  Future<Result<bool>> checkSecureStorageAvailability() async {
    if (_secureStorage == null) {
      return ResultHelper.failure(
        CacheFailure('Secure storage not initialized'),
      );
    }

    try {
      // Test write and read
      const testKey = 'omnisonic_test_key';
      const testValue = 'test_value';

      await _secureStorage.write(key: testKey, value: testValue);
      final readValue = await _secureStorage.read(key: testKey);
      await _secureStorage.delete(key: testKey);

      if (readValue == testValue) {
        _secureStorageAvailable = true;
        return ResultHelper.success(true);
      } else {
        _secureStorageAvailable = false;
        return ResultHelper.failure(
          CacheFailure('Secure storage test failed: read/write mismatch'),
        );
      }
    } catch (e) {
      _secureStorageAvailable = false;
      return ResultHelper.failure(
        CacheFailure('Secure storage test failed: ${e.toString()}'),
      );
    }
  }

  /// Gets diagnostic information about secure storage
  Map<String, dynamic> getSecureStorageDiagnostics() {
    return {
      'initialized': _secureStorage != null,
      'available': _secureStorageAvailable,
      'cached_passwords': _passwordCache.length,
      'database_fallback': true,
      'encryption_test': PasswordEncryption.testEncryption(),
      'platform_support': {
        'android': true,
        'ios': true,
        'macos': true,
        'windows': true,
        'linux': true,
      },
    };
  }

  /// Clears all cached passwords (useful for logout)
  void clearPasswordCache() {
    _passwordCache.clear();
  }

  /// Disposes resources
  void dispose() {
    for (final timer in _connectionTimers.values) {
      timer.cancel();
    }
    _connectionTimers.clear();
    _passwordCache.clear();
  }
}
