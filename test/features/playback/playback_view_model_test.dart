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
  late _FakeTrackingService tracking;
  late _FakeServerRepository servers;
  late AppDatabase database;
  late PlaybackViewModel viewModel;

  PlaybackViewModel buildViewModel() => PlaybackViewModel(
    repository,
    _UnusedPlayTrackUseCase(),
    tracking,
    apiClient,
    servers,
    _FakeAdaptiveStreamingService(),
    database,
  );

  setUp(() {
    repository = _FakePlaybackRepository();
    apiClient = _FakeApiClient();
    tracking = _FakeTrackingService();
    servers = _FakeServerRepository([
      testServer(id: 'server1', name: 'First'),
      testServer(id: 'server2', name: 'Second'),
    ]);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    viewModel = buildViewModel();
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.close();
    await servers.close();
    await database.close();
  });

  Future<void> emitTrack(Track track, {bool isPlaying = false}) async {
    repository.emitState(
      PlaybackState(
        isPlaying: isPlaying,
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

  test('a starred track stays starred when the player reports again', () async {
    final track = testTrack(id: 'server2_t1', serverId: 'server2');
    await emitTrack(track);

    await viewModel.toggleFavorite(viewModel.currentTrack!);
    expect(apiClient.starCalls, [('server2', 't1')]);
    expect(viewModel.currentTrack!.isStarred, isTrue);

    // The data source re-emits the Track it was loaded with, unstarred, on
    // every state update. The heart used to flip back right here.
    await emitTrack(track);
    expect(viewModel.currentTrack!.isStarred, isTrue);
    expect(viewModel.queue.single.isStarred, isTrue);
  });

  test('scrobble tracking follows play and pause', () async {
    final track = testTrack();

    await emitTrack(track);
    expect(tracking.events, ['track ${track.id} playing=false']);

    await emitTrack(track, isPlaying: true);
    await emitTrack(track);
    expect(tracking.events, [
      'track ${track.id} playing=false',
      'playing=true',
      'playing=false',
    ]);
  });

  test('the saved queue is restored once a server comes online', () async {
    viewModel.dispose();
    servers = _FakeServerRepository([
      testServer(id: 'server1', status: ServerStatus.offline),
    ]);
    tracking = _FakeTrackingService();
    viewModel = buildViewModel();
    await pumpEventQueue();

    // Nothing reachable at launch: the server is not asked yet...
    expect(tracking.playQueueRequests, 0);

    // ...but it is as soon as the monitor finds one online, and only once.
    servers.emit([testServer(id: 'server1')]);
    await pumpEventQueue();
    servers.emit([testServer(id: 'server1')]);
    await pumpEventQueue();
    expect(tracking.playQueueRequests, 1);
  });

  test('a restore does not replace what the user started meanwhile', () async {
    final saved = testTrack(id: 'server1_saved', title: 'Saved');
    final chosen = testTrack(id: 'server1_chosen', title: 'Chosen');
    final reply = Completer<PlayQueueState?>();

    viewModel.dispose();
    tracking = _FakeTrackingService(reply: reply.future);
    viewModel = buildViewModel();
    await pumpEventQueue();
    expect(tracking.playQueueRequests, 1);

    // The user picks a track while the server is still answering.
    await emitTrack(chosen, isPlaying: true);
    reply.complete(PlayQueueState(tracks: [saved], currentIndex: 0));
    await pumpEventQueue();

    expect(viewModel.currentTrack, chosen);
    expect(repository.queuesSet, isEmpty);
  });
}

class _FakePlaybackRepository implements PlaybackRepository {
  final _states = StreamController<PlaybackState>.broadcast();
  final seeks = <Duration>[];
  final queuesSet = <List<Track>>[];

  @override
  Future<Result<void>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
  }) async {
    queuesSet.add(tracks);
    return ResultHelper.success(null);
  }

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

  List<MusicServer> servers;
  final _updates = StreamController<List<MusicServer>>.broadcast();

  void emit(List<MusicServer> updated) {
    servers = updated;
    _updates.add(updated);
  }

  Future<void> close() => _updates.close();

  @override
  Stream<List<MusicServer>> observeServers() => _updates.stream;

  @override
  Future<Result<List<MusicServer>>> getAllServers() async =>
      ResultHelper.success(servers);

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
  _FakeTrackingService({this.reply});

  final Future<PlayQueueState?>? reply;
  final events = <String>[];
  var playQueueRequests = 0;

  @override
  Stream<Track> get onScrobbled => const Stream.empty();

  @override
  Future<PlayQueueState?> getPlayQueue() async {
    playQueueRequests++;
    return reply;
  }

  @override
  void startTrackingTrack(Track track, {bool isPlaying = true}) =>
      events.add('track ${track.id} playing=$isPlaying');

  @override
  void setPlaying(bool isPlaying) => events.add('playing=$isPlaying');

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
