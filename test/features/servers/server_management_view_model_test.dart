import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/features/servers/presentation/viewmodels/server_management_view_model.dart';

/// An in-memory server list whose connection tests always pass.
class _FakeServerRepository implements ServerRepository {
  final servers = <MusicServer>[];
  final _changes = StreamController<List<MusicServer>>.broadcast();

  void _emit() => _changes.add(List.of(servers));

  @override
  Stream<List<MusicServer>> observeServers() => _changes.stream;

  @override
  Future<Result<List<MusicServer>>> getAllServers() async =>
      ResultHelper.success(List.of(servers));

  @override
  Future<Result<void>> startMonitoringAllServers() async =>
      ResultHelper.success(null);

  @override
  Future<Result<ServerConnectionResult>> testConnectionWithCredentials({
    required String url,
    required String username,
    required String password,
  }) async => ResultHelper.success(
    ServerConnectionResult(
      isSuccessful: true,
      serverInfo: const ServerInfo(version: '0.64.2', apiVersion: '1.16.1'),
    ),
  );

  @override
  Future<Result<ServerConnectionResult>> testConnection(
    MusicServer server,
  ) async => ResultHelper.success(
    ServerConnectionResult(isSuccessful: true, serverInfo: null),
  );

  @override
  Future<Result<void>> addServer(MusicServer server) async {
    servers.add(server);
    _emit();
    return ResultHelper.success(null);
  }

  @override
  Future<Result<void>> storeCredentials(
    String serverId,
    String password,
  ) async => ResultHelper.success(null);

  @override
  Future<Result<void>> updateServerStatus(
    String serverId,
    ServerStatus status,
  ) async {
    final i = servers.indexWhere((s) => s.id == serverId);
    servers[i] = servers[i].copyWith(status: status);
    _emit();
    return ResultHelper.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records whether every server was online when the sync ran.
class _FakeSyncUseCase implements SyncMusicCollectionUseCase {
  _FakeSyncUseCase(this._repository);

  final _FakeServerRepository _repository;
  final onlineAtSync = <bool>[];

  @override
  Future<Result<UnifiedCollection>> call(
    SyncMusicCollectionParams params,
  ) async {
    onlineAtSync.add(
      _repository.servers.every((s) => s.status == ServerStatus.online),
    );
    return ResultHelper.failure(ServerFailure('not under test'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Regressions for #65.
void main() {
  late _FakeServerRepository repository;
  late _FakeSyncUseCase sync;
  late ServerManagementViewModel viewModel;

  MusicServer stuck() => MusicServer(
    id: 'server1',
    name: 'Home',
    url: 'http://music.example.com',
    username: 'user',
    status: ServerStatus.error,
    createdAt: DateTime(2026),
  );

  setUp(() async {
    repository = _FakeServerRepository();
    sync = _FakeSyncUseCase(repository);
    viewModel = ServerManagementViewModel(repository, sync);
    await pumpEventQueue();
  });

  tearDown(() => viewModel.dispose());

  test('an unnamed server is named after its host', () async {
    await viewModel.addServer(
      name: '',
      url: 'http://music.example.com:4533',
      username: 'user',
      password: 'secret',
    );

    expect(repository.servers.single.name, 'music.example.com');
  });

  test('a passing connection test clears a stale error status', () async {
    repository.servers.add(stuck());

    await viewModel.testConnection(repository.servers.single);

    expect(repository.servers.single.status, ServerStatus.online);
  });

  test('a manual sync re-checks servers that are not online', () async {
    repository.servers.add(stuck());
    repository._emit();
    await pumpEventQueue();

    await viewModel.syncAllServers();

    expect(sync.onlineAtSync, [true]);
  });
}
