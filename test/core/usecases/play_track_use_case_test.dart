import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/usecases/play_track_use_case.dart';

import '../../helpers/entity_factories.dart';

/// Playing a track that also lives on another server.
void main() {
  final original = testTrack(id: 'down_t1', serverId: 'down');
  final copy = testTrack(id: 'up_t9', serverId: 'up');
  final other = testTrack(id: 'down_t2', serverId: 'down');

  late _FakePlayback playback;
  late _FakeMusic music;
  late PlayTrackUseCase useCase;

  setUp(() {
    playback = _FakePlayback(unreachable: {'down'});
    music = _FakeMusic();
    useCase = PlayTrackUseCase(
      playback,
      music,
      _FakeServers([
        testServer(id: 'down', status: ServerStatus.online),
        testServer(id: 'up'),
      ]),
    );
  });

  test('the chosen copy is what the queue loads and plays', () async {
    music.best = copy;

    final result = await useCase(
      PlayTrackParams(track: original, queue: [original, other]),
    );

    expect(result.isSuccess, isTrue);
    // Not the requested copy, whose server does not answer: setting the
    // queue with it there failed before any fallback was tried.
    expect(playback.queues.single.first, copy);
    expect(playback.played, [copy]);
  });

  test('a queue that cannot load falls back to another copy', () async {
    // Source selection still believes the requested copy is fine.
    music.best = original;
    music.fallback = copy;

    final result = await useCase(
      PlayTrackParams(track: original, queue: [original, other]),
    );

    expect(result.isSuccess, isTrue);
    expect(playback.queues.last.first, copy);
    expect(playback.played, [copy]);
  });
}

class _FakePlayback implements PlaybackRepository {
  _FakePlayback({required this.unreachable});

  /// Servers whose tracks fail to load.
  final Set<String> unreachable;
  final queues = <List<Track>>[];
  final played = <Track>[];

  @override
  Future<Result<void>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
  }) async {
    queues.add(List.of(tracks));
    // Setting a queue loads its current track.
    if (unreachable.contains(tracks[startIndex].serverId)) {
      return ResultHelper.failure(const PlaybackFailure('unreachable'));
    }
    return ResultHelper.success(null);
  }

  @override
  Future<Result<void>> play(Track track) async {
    if (unreachable.contains(track.serverId)) {
      return ResultHelper.failure(const PlaybackFailure('unreachable'));
    }
    played.add(track);
    return ResultHelper.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMusic implements MusicRepository {
  Track? best;
  Track? fallback;

  @override
  Future<Result<Track>> getBestSourceForTrack(String trackId) async =>
      best == null
      ? ResultHelper.failure(const DataFailure('none'))
      : ResultHelper.success(best!);

  @override
  Future<Result<Track>> getFallbackSource(
    String originalTrackId,
    String failedTrackId,
  ) async => fallback == null
      ? ResultHelper.failure(const DataFailure('none'))
      : ResultHelper.success(fallback!);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeServers implements ServerRepository {
  _FakeServers(this.servers);

  final List<MusicServer> servers;

  @override
  Future<Result<MusicServer?>> getServerById(String serverId) async =>
      ResultHelper.success(servers.where((s) => s.id == serverId).firstOrNull);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
