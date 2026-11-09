import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/playback_repository.dart';
import 'package:omnisonic/core/repositories/server_repository.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/services/subsonic_models.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/features/playback/data/datasources/adaptive_streaming_service.dart';
import 'package:omnisonic/features/playback/data/datasources/playback_tracking_service.dart';
import 'package:omnisonic/features/playback/presentation/viewmodels/playback_view_model.dart';

import '../../helpers/entity_factories.dart';

void main() {
  late _FakePlaybackRepository repository;
  late _FakeApiClient apiClient;
  late AppDatabase database;
  late PlaybackViewModel viewModel;

  setUp(() {
    repository = _FakePlaybackRepository();
    apiClient = _FakeApiClient();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    viewModel = PlaybackViewModel(
      repository,
      _UnusedPlayTrackUseCase(),
      _FakeTrackingService(),
      apiClient,
      _FakeServerRepository([
        testServer(id: 'server1', name: 'First'),
        testServer(id: 'server2', name: 'Second'),
      ]),
      _FakeAdaptiveStreamingService(),
      database,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.close();
    await database.close();
  });

  Future<void> emitTrack(Track track) async {
    repository.emitState(
      PlaybackState(
        isPlaying: false,
        currentTrack: track,
        position: Duration.zero,
        duration: track.duration,
        queue: [track],
        currentIndex: 0,
        repeatMode: RepeatMode.none,
        shuffleEnabled: false,
        volume: 1,
      ),
    );
    await pumpEventQueue();
  }

  test('seeking moves the position before the player confirms it', () async {
    await emitTrack(testTrack());

    // The scrubbers fall back to this position as soon as a drag ends. It
    // used to stay at the pre-seek value until the player reported back,
    // so the thumb snapped back to where the drag began.
    final seeking = viewModel.seek(const Duration(seconds: 90));
    expect(viewModel.position, const Duration(seconds: 90));

    await seeking;
    expect(repository.seeks, [const Duration(seconds: 90)]);
  });
}

class _FakePlaybackRepository implements PlaybackRepository {
  final _states = StreamController<PlaybackState>.broadcast();
  final seeks = <Duration>[];

  void emitState(PlaybackState state) => _states.add(state);

  Future<void> close() => _states.close();

  @override
  Stream<PlaybackState> observePlaybackState() => _states.stream;

  @override
  Stream<Duration> observePosition() => const Stream.empty();

  @override
  Stream<List<Track>> observeQueue() => const Stream.empty();

  @override
  Future<Result<PlaybackState>> getCurrentState() async =>
      ResultHelper.failure(const CacheFailure('nothing playing'));

  @override
  Future<Result<void>> seek(Duration position) async {
    seeks.add(position);
    return ResultHelper.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeServerRepository implements ServerRepository {
  _FakeServerRepository(this.servers);

  final List<MusicServer> servers;

  @override
  Future<Result<MusicServer?>> getServerById(String serverId) async =>
      ResultHelper.success(servers.where((s) => s.id == serverId).firstOrNull);

  @override
  Future<Result<List<MusicServer>>> getOnlineServers() async =>
      ResultHelper.success(servers);

  @override
  Future<Result<String?>> getCredentials(String serverId) async =>
      ResultHelper.success('secret');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeApiClient implements SubsonicApiClient {
  final starCalls = <(String, String?)>[];

  static const _ok = SubsonicResponse<PingResponse>(
    subsonicResponse: SubsonicResponseData(status: 'ok', version: '1.16.1'),
  );

  @override
  Future<SubsonicResponse<PingResponse>> star(
    MusicServer server,
    String password, {
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    starCalls.add((server.id, id));
    return _ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTrackingService implements PlaybackTrackingService {
  @override
  Stream<Track> get onScrobbled => const Stream.empty();

  @override
  Future<PlayQueueState?> getPlayQueue() async => null;

  @override
  void startTrackingTrack(Track track) {}

  @override
  void startPeriodicQueueSave(
    Future<List<Track>> Function() getQueue,
    Future<int> Function() getCurrentIndex,
    Future<Duration> Function() getPosition,
  ) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdaptiveStreamingService implements AdaptiveStreamingService {
  @override
  AudioQuality get currentRecommendedQuality => AudioQuality.high;

  @override
  Stream<AudioQuality> observeRecommendedQuality() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedPlayTrackUseCase implements PlayTrackUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
