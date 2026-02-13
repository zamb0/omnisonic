import 'dart:async';
import '../entities/music_server.dart';
import '../entities/server_status.dart';
import '../errors/result.dart';
import 'server_connection_service.dart';

/// Service for monitoring server connection status
class ServerStatusMonitor {
  final ServerConnectionService _connectionService;
  final Map<String, StreamController<MusicServer>> _statusControllers = {};
  final Map<String, Timer> _monitoringTimers = {};
  
  static const Duration _monitorInterval = Duration(minutes: 2);

  ServerStatusMonitor({
    required ServerConnectionService connectionService,
  }) : _connectionService = connectionService;

  /// Starts monitoring a server's connection status
  Stream<MusicServer> monitorServer(MusicServer server) {
    // Create or get existing controller
    if (!_statusControllers.containsKey(server.id)) {
      _statusControllers[server.id] = StreamController<MusicServer>.broadcast();
    }

    final controller = _statusControllers[server.id]!;

    // Start monitoring if not already started
    if (!_monitoringTimers.containsKey(server.id)) {
      _startMonitoring(server);
    }

    return controller.stream;
  }

  /// Stops monitoring a server
  void stopMonitoring(String serverId) {
    _monitoringTimers[serverId]?.cancel();
    _monitoringTimers.remove(serverId);
    
    _statusControllers[serverId]?.close();
    _statusControllers.remove(serverId);
  }

  /// Manually tests a server connection and updates status
  Future<MusicServer> testServerStatus(MusicServer server) async {
    final passwordResult = await _connectionService.getServerPassword(server.id);
    
    if (passwordResult.isFailure) {
      return server.copyWith(
        status: ServerStatus.error,
        errorMessage: 'No stored credentials',
      );
    }

    final testResult = await _connectionService.testConnection(
      server,
      passwordResult.valueOrNull!,
    );

    if (testResult.isSuccess) {
      return testResult.valueOrNull!;
    } else {
      return server.copyWith(
        status: ServerStatus.error,
        errorMessage: testResult.failureOrNull?.message ?? 'Connection failed',
      );
    }
  }

  /// Starts periodic monitoring for a server
  void _startMonitoring(MusicServer server) {
    // Initial status check
    _checkServerStatus(server);

    // Set up periodic monitoring
    _monitoringTimers[server.id] = Timer.periodic(
      _monitorInterval,
      (_) => _checkServerStatus(server),
    );
  }

  /// Checks server status and emits updates
  Future<void> _checkServerStatus(MusicServer server) async {
    final controller = _statusControllers[server.id];
    if (controller == null || controller.isClosed) {
      return;
    }

    try {
      final updatedServer = await testServerStatus(server);
      controller.add(updatedServer);
    } catch (e) {
      final errorServer = server.copyWith(
        status: ServerStatus.error,
        errorMessage: 'Monitoring error: $e',
      );
      controller.add(errorServer);
    }
  }

  /// Gets current status for all monitored servers
  Map<String, ServerStatus> getCurrentStatuses() {
    final statuses = <String, ServerStatus>{};
    
    for (final serverId in _monitoringTimers.keys) {
      // This would need integration with a repository to get current status
      // For now, return offline status
      statuses[serverId] = ServerStatus.offline;
    }
    
    return statuses;
  }

  /// Disposes all monitoring resources
  void dispose() {
    for (final timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _monitoringTimers.clear();

    for (final controller in _statusControllers.values) {
      controller.close();
    }
    _statusControllers.clear();
  }
}