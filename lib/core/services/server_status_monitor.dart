import 'dart:async';
import 'dart:math';

import '../entities/music_server.dart';
import '../entities/server_status.dart';
import '../errors/result.dart';
import 'server_connection_service.dart';

/// Periodically re-tests every known server so the rest of the app can tell
/// which copies of a duplicated track are actually reachable.
///
/// Source selection depends on this: without live statuses it would happily
/// pick a track from a server that is down.
class ServerStatusMonitor {
  ServerStatusMonitor({required ServerConnectionService connectionService})
    : _connectionService = connectionService;

  final ServerConnectionService _connectionService;

  /// The latest known record for each monitored server. Kept mutable so a
  /// scheduled check always tests the current URL and credentials rather than
  /// the snapshot captured when monitoring started.
  final Map<String, MusicServer> _monitoredServers = {};
  final Map<String, ServerStatus> _latestStatuses = {};
  final Map<String, int> _consecutiveFailures = {};
  final Map<String, Timer> _monitoringTimers = {};

  /// One number per monitoring session. A check or timer callback that
  /// outlives a stop (and maybe a restart) of its server sees a different
  /// generation and gives up, instead of starting a second schedule.
  final Map<String, int> _generations = {};
  int _nextGeneration = 0;

  final _statusUpdates = StreamController<MusicServer>.broadcast();
  final _random = Random();

  static const Duration _monitorInterval = Duration(minutes: 2);
  static const Duration _maxInterval = Duration(minutes: 16);

  /// Emits a server every time its status has been re-tested.
  Stream<MusicServer> get statusUpdates => _statusUpdates.stream;

  /// Starts monitoring [server], or refreshes the record if it is already
  /// being monitored.
  void startMonitoring(MusicServer server) {
    final alreadyMonitored = _monitoredServers.containsKey(server.id);
    _monitoredServers[server.id] = server;

    if (alreadyMonitored) return;

    final generation = ++_nextGeneration;
    _generations[server.id] = generation;

    // Check straight away, then settle into the periodic schedule.
    unawaited(_checkServerStatus(server.id, generation));
    _scheduleNextCheck(server.id, generation);
  }

  /// Starts monitoring a server's connection status, returning the updates
  /// for that server only.
  Stream<MusicServer> monitorServer(MusicServer server) {
    startMonitoring(server);
    return statusUpdates.where((updated) => updated.id == server.id);
  }

  /// Stops monitoring a server.
  void stopMonitoring(String serverId) {
    _monitoringTimers.remove(serverId)?.cancel();
    _generations.remove(serverId);
    _monitoredServers.remove(serverId);
    _latestStatuses.remove(serverId);
    _consecutiveFailures.remove(serverId);
  }

  /// Stops monitoring every server.
  void stopAllMonitoring() {
    for (final serverId in _monitoredServers.keys.toList()) {
      stopMonitoring(serverId);
    }
  }

  /// Manually tests a server connection and returns it with an updated status.
  Future<MusicServer> testServerStatus(MusicServer server) async {
    final passwordResult = await _connectionService.getServerPassword(
      server.id,
    );

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

  /// The last observed status of [serverId], or null if it has never been
  /// checked.
  ServerStatus? statusFor(String serverId) => _latestStatuses[serverId];

  /// The last observed status of every monitored server.
  Map<String, ServerStatus> getCurrentStatuses() =>
      Map.unmodifiable(_latestStatuses);

  /// Schedules the next check for [serverId].
  ///
  /// Servers that keep failing are backed off exponentially up to
  /// [_maxInterval], and every delay carries up to 20% jitter so N servers do
  /// not wake up in lockstep.
  void _scheduleNextCheck(String serverId, int generation) {
    final failures = _consecutiveFailures[serverId] ?? 0;
    final backoffFactor = 1 << min(failures, 3);
    var delayMs = _monitorInterval.inMilliseconds * backoffFactor;
    delayMs = min(delayMs, _maxInterval.inMilliseconds);
    delayMs += _random.nextInt((delayMs * 0.2).round() + 1);

    _monitoringTimers[serverId] = Timer(
      Duration(milliseconds: delayMs),
      () async {
        await _checkServerStatus(serverId, generation);
        // Only reschedule if this monitoring session is still the live one.
        if (_generations[serverId] == generation) {
          _scheduleNextCheck(serverId, generation);
        }
      },
    );
  }

  /// Checks a server's status and emits the update.
  Future<void> _checkServerStatus(String serverId, int generation) async {
    final server = _monitoredServers[serverId];
    if (server == null ||
        _generations[serverId] != generation ||
        _statusUpdates.isClosed) {
      return;
    }

    MusicServer updated;
    try {
      updated = await testServerStatus(server);
    } catch (e) {
      updated = server.copyWith(
        status: ServerStatus.error,
        errorMessage: 'Monitoring error: $e',
      );
    }

    // Monitoring may have been stopped while the request was in flight.
    if (_generations[serverId] != generation || _statusUpdates.isClosed) {
      return;
    }

    // The server was edited while the request was in flight: this result
    // describes the old URL or credentials, and storing `updated` would put
    // them back. Test the current record instead.
    if (!identical(_monitoredServers[serverId], server)) {
      return _checkServerStatus(serverId, generation);
    }

    _monitoredServers[serverId] = updated;
    _latestStatuses[serverId] = updated.status;
    _consecutiveFailures[serverId] = updated.status == ServerStatus.online
        ? 0
        : (_consecutiveFailures[serverId] ?? 0) + 1;

    _statusUpdates.add(updated);
  }

  /// Disposes all monitoring resources.
  void dispose() {
    stopAllMonitoring();
    _statusUpdates.close();
  }
}
