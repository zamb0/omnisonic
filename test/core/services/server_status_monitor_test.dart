import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/services/server_connection_service.dart';
import 'package:omnisonic/core/services/server_status_monitor.dart';

/// Records every connection test and lets the test decide when each answers.
class _FakeConnectionService implements ServerConnectionService {
  final tested = <MusicServer>[];
  final pending = <Completer<void>>[];

  /// When false, each test waits until its completer in [pending] completes.
  bool answerImmediately = true;

  @override
  Future<Result<String>> getServerPassword(String serverId) async =>
      ResultHelper.success('password');

  @override
  Future<Result<MusicServer>> testConnection(
    MusicServer server,
    String password,
  ) async {
    tested.add(server);
    if (!answerImmediately) {
      final gate = Completer<void>();
      pending.add(gate);
      await gate.future;
    }
    return ResultHelper.success(server.copyWith(status: ServerStatus.online));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final server = MusicServer(
    id: 'server1',
    name: 'Server',
    url: 'http://old.example.com',
    username: 'user',
    status: ServerStatus.offline,
    createdAt: DateTime(2026),
  );

  testWidgets('an edit during a check is not overwritten by its result', (
    tester,
  ) async {
    final connection = _FakeConnectionService()..answerImmediately = false;
    final monitor = ServerStatusMonitor(connectionService: connection);

    monitor.startMonitoring(server);
    await tester.pump();
    expect(connection.tested.single.url, 'http://old.example.com');

    final edited = server.copyWith(url: 'http://new.example.com');
    monitor.startMonitoring(edited);
    connection.pending.single.complete();
    await tester.pump();

    // The stale result is discarded and the edited record is tested instead.
    expect(connection.tested.last.url, 'http://new.example.com');

    connection.pending.last.complete();
    await tester.pump();
    monitor.dispose();
  });

  testWidgets('a restart during a check leaves a single schedule', (
    tester,
  ) async {
    final connection = _FakeConnectionService();
    final monitor = ServerStatusMonitor(connectionService: connection);

    monitor.startMonitoring(server);
    await tester.pump();

    // Let the first scheduled check start, and keep it in flight.
    connection.answerImmediately = false;
    await tester.pump(const Duration(minutes: 3));
    expect(connection.pending, hasLength(1));

    monitor.stopMonitoring(server.id);
    connection.answerImmediately = true;
    monitor.startMonitoring(server);
    await tester.pump();

    connection.pending.single.complete();
    await tester.pump();

    final before = connection.tested.length;
    await tester.pump(const Duration(minutes: 3));
    expect(connection.tested.length - before, 1);

    monitor.dispose();
  });
}
