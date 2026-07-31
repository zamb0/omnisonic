import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

import '../entities/entities.dart';
import '../errors/errors.dart';

/// Offline mode detection and management service
class OfflineModeService {
  OfflineModeService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _offlineModeController = BehaviorSubject<bool>.seeded(false);
  final _connectivityController = BehaviorSubject<ConnectivityResult>();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitialized = false;

  /// Current offline mode status
  bool get isOffline => _offlineModeController.value;

  /// Stream of offline mode changes
  Stream<bool> get offlineModeStream =>
      _offlineModeController.stream.distinct();

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream.distinct();

  /// Initializes the offline mode service
  Future<Result<void>> initialize() async {
    if (_isInitialized) {
      return ResultHelper.success(null);
    }

    try {
      // Check initial connectivity
      final initialConnectivity = await _connectivity.checkConnectivity();
      final isInitiallyOffline = _isConnectivityOffline(initialConnectivity);

      _offlineModeController.add(isInitiallyOffline);
      _connectivityController.add(initialConnectivity.first);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final result = results.isNotEmpty
              ? results.first
              : ConnectivityResult.none;
          final isOffline = _isConnectivityOffline(results);

          _connectivityController.add(result);
          _offlineModeController.add(isOffline);
        },
        onError: (error) {
          // On error, assume offline
          _offlineModeController.add(true);
          _connectivityController.add(ConnectivityResult.none);
        },
      );

      _isInitialized = true;
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to initialize offline mode service: $e'),
      );
    }
  }

  /// Manually sets offline mode (for testing or user preference)
  void setOfflineMode(bool isOffline) {
    _offlineModeController.add(isOffline);
  }

  /// Forces a connectivity check
  Future<Result<bool>> checkConnectivity() async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      final isOffline = _isConnectivityOffline(connectivity);

      _offlineModeController.add(isOffline);
      _connectivityController.add(connectivity.first);

      return ResultHelper.success(isOffline);
    } catch (e) {
      return ResultHelper.failure(
        NetworkFailure('Failed to check connectivity: $e'),
      );
    }
  }

  /// Gets current connectivity type
  Future<Result<ConnectivityResult>> getCurrentConnectivity() async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      return ResultHelper.success(connectivity.first);
    } catch (e) {
      return ResultHelper.failure(
        NetworkFailure('Failed to get connectivity: $e'),
      );
    }
  }

  /// Checks if current connection is metered (mobile data)
  bool get isMeteredConnection {
    final current = _connectivityController.valueOrNull;
    return current == ConnectivityResult.mobile;
  }

  /// Checks if current connection is WiFi
  bool get isWiFiConnection {
    final current = _connectivityController.valueOrNull;
    return current == ConnectivityResult.wifi;
  }

  /// Checks if device has any network connection
  bool get hasNetworkConnection {
    final current = _connectivityController.valueOrNull;
    return current != null && current != ConnectivityResult.none;
  }

  /// Determines if connectivity results indicate offline status
  bool _isConnectivityOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;

    // Consider offline if all results are 'none'
    return results.every((result) => result == ConnectivityResult.none);
  }

  /// Waits for network connection to be restored
  Future<Result<void>> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      if (!isOffline) {
        return ResultHelper.success(null);
      }

      final completer = Completer<void>();
      late StreamSubscription subscription;

      // Set up timeout
      final timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError(TimeoutException('Connection timeout'));
        }
      });

      // Listen for connection restoration
      subscription = offlineModeStream.listen((isOffline) {
        if (!isOffline && !completer.isCompleted) {
          timeoutTimer.cancel();
          subscription.cancel();
          completer.complete();
        }
      });

      await completer.future;
      return ResultHelper.success(null);
    } catch (e) {
      if (e is TimeoutException) {
        return ResultHelper.failure(NetworkFailure('Connection timeout'));
      }
      return ResultHelper.failure(
        UnknownFailure('Failed to wait for connection: $e'),
      );
    }
  }

  /// Gets network quality indicator (simplified)
  NetworkQuality get networkQuality {
    if (isOffline) return NetworkQuality.none;

    final connectivity = _connectivityController.valueOrNull;
    switch (connectivity) {
      case ConnectivityResult.wifi:
        return NetworkQuality.good;
      case ConnectivityResult.mobile:
        return NetworkQuality
            .fair; // Could be enhanced with actual speed testing
      case ConnectivityResult.ethernet:
        return NetworkQuality.excellent;
      default:
        return NetworkQuality.none;
    }
  }

  /// Disposes the service
  void dispose() {
    _connectivitySubscription?.cancel();
    _offlineModeController.close();
    _connectivityController.close();
  }
}

/// Network quality levels
enum NetworkQuality { none, poor, fair, good, excellent }

/// Extension for network quality
extension NetworkQualityExtension on NetworkQuality {
  /// Gets a human-readable description
  String get description {
    switch (this) {
      case NetworkQuality.none:
        return 'No Connection';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.excellent:
        return 'Excellent';
    }
  }

  /// Gets recommended streaming quality
  AudioQuality get recommendedStreamingQuality {
    switch (this) {
      case NetworkQuality.none:
        return AudioQuality.low;
      case NetworkQuality.poor:
        return AudioQuality.low;
      case NetworkQuality.fair:
        return AudioQuality.medium;
      case NetworkQuality.good:
        return AudioQuality.high;
      case NetworkQuality.excellent:
        return AudioQuality.lossless;
    }
  }

  /// Checks if quality is sufficient for streaming
  bool get canStream => this != NetworkQuality.none;
}
