import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/database/data_sources/local_server_data_source.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/services/server_connection_service.dart';
import 'package:omnisonic/core/services/server_status_monitor.dart';
import 'package:omnisonic/features/servers/data/repositories/server_repository_impl.dart';

/// Stores passwords in memory and reports every server reachable.
class _FakeConnectionService implements ServerConnectionService {
  final passwords = <String, String>{};

  @override
  Future<Result<void>> storeServerPassword(
    String serverId,
    String password,
  ) async {
    passwords[serverId] = password;
    return ResultHelper.success(null);
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records which servers monitoring was started for, and whether their
/// password was already stored at that moment.
class _RecordingMonitor extends ServerStatusMonitor {
  _RecordingMonitor(this._connection) : super(connectionService: _connection);

  final _FakeConnectionService _connection;
  final started = <({String id, bool hadPassword})>[];

  @override
  void startMonitoring(MusicServer server) {
    started.add((
      id: server.id,
      hadPassword: _connection.passwords.containsKey(server.id),
    ));
  }
}

/// Regression for #65: addServer started the monitor, whose immediate check
/// ran before the password was stored, failed with "No stored credentials"
/// and marked every new server as error.
void main() {
  late AppDatabase database;
  late _FakeConnectionService connection;
  late _RecordingMonitor monitor;
  late ServerRepositoryImpl repository;

  final server = MusicServer(
    id: 'server1',
    name: 'Home',
    url: 'http://music.example.com',
    username: 'user',
    status: ServerStatus.online,
    createdAt: DateTime(2026),
  );

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    connection = _FakeConnectionService();
    monitor = _RecordingMonitor(connection);
    repository = ServerRepositoryImpl(
      localDataSource: LocalServerDataSource(database),
      connectionService: connection,
      statusMonitor: monitor,
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.close();
  });

  test('a new server is monitored only once its password is stored', () async {
    await repository.addServer(server);
    expect(monitor.started, isEmpty);

    await repository.storeCredentials(server.id, 'secret');

    expect(monitor.started, [(id: server.id, hadPassword: true)]);
  });
}
