import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/services/subsonic_models.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/features/playback/data/datasources/adaptive_streaming_service.dart';
import 'package:omnisonic/features/playback/data/datasources/playback_tracking_service.dart';
import 'package:omnisonic/features/playback/presentation/viewmodels/playback_view_model.dart';

import '../../helpers/entity_factories.dart';

/// Regression for #53 point 1: the player heart must star the track on the
/// server it belongs to, flip immediately, and roll back on failure.
void main() {
  late _FakeApiClient api;
  late _FakeServerRepository servers;
  late AppDatabase db;
  late PlaybackViewModel vm;

  final first = testServer(id: 'alpha', name: 'Alpha');
  final second = testServer(id: 'beta', name: 'Beta');
  final track = testTrack(id: 'beta_song_42', serverId: 'beta');

  setUp(() async {
    api = _FakeApiClient();
    servers = _FakeServerRepository([first, second]);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    vm = PlaybackViewModel(
      _FakePlaybackRepository(track),
      _FakePlayTrackUseCase(),
      _FakeTrackingService(),
      api,
      servers,
      _FakeAdaptiveStreaming(),
      db,
    );
    // Let _loadCurrentState seed the current track.
    await pumpEventQueue();
  });

  tearDown(() async {
    vm.dispose();
    await db.close();
  });

  test('stars on the track\'s own server with its Subsonic id', () async {
    await vm.toggleFavorite(vm.currentTrack!);

    expect(api.calls, hasLength(1));
    expect(api.calls.single.server.id, 'beta');
    expect(api.calls.single.id, 'song_42');
    expect(api.calls.single.star, isTrue);
    expect(vm.currentTrack!.isStarred, isTrue);
    expect(vm.errorMessage, isNull);
  });

  test('flips optimistically and ignores a second tap while pending', () async {
    final gate = Completer<void>();
    api.gate = gate;

    final pending = vm.toggleFavorite(vm.currentTrack!);
    await pumpEventQueue();
    expect(vm.currentTrack!.isStarred, isTrue);
    expect(vm.isFavoritePending(track.id), isTrue);

    await vm.toggleFavorite(vm.currentTrack!);
    gate.complete();
    await pending;

    expect(api.calls, hasLength(1));
    expect(vm.isFavoritePending(track.id), isFalse);
    expect(vm.currentTrack!.isStarred, isTrue);
  });

  test('rolls back and reports when the server refuses', () async {
    api.succeed = false;

    await vm.toggleFavorite(vm.currentTrack!);

    expect(vm.currentTrack!.isStarred, isFalse);
    expect(vm.queue.single.isStarred, isFalse);
    expect(vm.errorMessage, contains('Beta'));
    expect(vm.isFavoritePending(track.id), isFalse);
  });
}

class _StarCall {
  _StarCall(this.server, this.id, this.star);
  final MusicServer server;
  final String? id;
  final bool star;
}

class _FakeApiClient extends Fake implements SubsonicApiClient {
  final calls = <_StarCall>[];
  bool succeed = true;
  Completer<void>? gate;

  Future<SubsonicResponse<PingResponse>> _respond() async {
    if (gate != null) await gate!.future;
    return SubsonicResponse(
      subsonicResponse: SubsonicResponseData(
        status: succeed ? 'ok' : 'failed',
        version: '1.16.1',
        error: succeed ? null : const SubsonicError(code: 0, message: 'no'),
      ),
    );
  }

  @override
  Future<SubsonicResponse<PingResponse>> star(
    MusicServer server,
    String password, {
    String? id,
    String? albumId,
    String? artistId,
  }) {
    calls.add(_StarCall(server, id, true));
    return _respond();
  }

  @override
  Future<SubsonicResponse<PingResponse>> unstar(
    MusicServer server,
    String password, {
    String? id,
    String? albumId,
    String? artistId,
  }) {
    calls.add(_StarCall(server, id, false));
    return _respond();
  }
}

class _FakeServerRepository extends Fake implements ServerRepository {
  _FakeServerRepository(this.servers);
  final List<MusicServer> servers;

  @override
  Future<Result<List<MusicServer>>> getOnlineServers() async =>
      ResultHelper.success(servers);

  @override
  Future<Result<MusicServer?>> getServerById(String serverId) async =>
      ResultHelper.success(servers.where((s) => s.id == serverId).firstOrNull);

  @override
  Future<Result<String?>> getCredentials(String serverId) async =>
      ResultHelper.success('secret');
}

class _FakePlaybackRepository extends Fake implements PlaybackRepository {
  _FakePlaybackRepository(this.track);
  final Track track;

  @override
  Stream<PlaybackState> observePlaybackState() => const Stream.empty();

  @override
  Stream<Duration> observePosition() => const Stream.empty();

  @override
  Stream<List<Track>> observeQueue() => const Stream.empty();

  @override
  Future<Result<PlaybackState>> getCurrentState() async => ResultHelper.success(
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
}

class _FakePlayTrackUseCase extends Fake implements PlayTrackUseCase {}

class _FakeTrackingService extends Fake implements PlaybackTrackingService {
  @override
  Stream<Track> get onScrobbled => const Stream.empty();

  @override
  Future<PlayQueueState?> getPlayQueue() async => null;

  @override
  void dispose() {}
}

class _FakeAdaptiveStreaming extends Fake implements AdaptiveStreamingService {
  @override
  AudioQuality get currentRecommendedQuality => AudioQuality.ultra;

  @override
  Stream<AudioQuality> observeRecommendedQuality() => const Stream.empty();
}
