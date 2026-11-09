import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/repositories/server_repository.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/services/subsonic_models.dart';
import 'package:omnisonic/features/playback/data/datasources/playback_tracking_service.dart';

import '../../helpers/entity_factories.dart';

/// Records every write instead of talking to a server, and answers
/// `getPlayQueue` from canned per-server JSON.
class _RecordingApiClient extends SubsonicApiClient {
  final scrobbles = <({String serverId, String id, bool submission})>[];
  final savedQueues =
      <({String serverId, List<String> ids, String? current, int? position})>[];
  final playQueues = <String, Map<String, dynamic>>{};

  static SubsonicResponse<PingResponse> get _ok => SubsonicResponse.fromJson({
    'subsonic-response': {'status': 'ok', 'version': '1.16.1'},
  }, (_) => const PingResponse());

  @override
  Future<SubsonicResponse<PingResponse>> scrobble(
    MusicServer server,
    String password,
    String trackId, {
    DateTime? time,
    bool submission = true,
  }) async {
    scrobbles.add((serverId: server.id, id: trackId, submission: submission));
    return _ok;
  }

  @override
  Future<SubsonicResponse<PingResponse>> savePlayQueue(
    MusicServer server,
    String password,
    List<String> trackIds, {
    String? current,
    int? position,
  }) async {
    savedQueues.add((
      serverId: server.id,
      ids: trackIds,
      current: current,
      position: position,
    ));
    return _ok;
  }

  @override
  Future<SubsonicResponse<PlayQueueResponse>> getPlayQueue(
    MusicServer server,
    String password,
  ) async {
    final json = playQueues[server.id];
    if (json == null) {
      // What Navidrome answers when nothing was ever saved.
      throw Exception('Error 70: no play queue found');
    }
    return SubsonicResponse.fromJson(
      json,
      (data) => PlayQueueResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}

class _FakeServerRepository implements ServerRepository {
  _FakeServerRepository(this.servers);

  final List<MusicServer> servers;

  @override
  Future<Result<List<MusicServer>>> getAllServers() async =>
      ResultHelper.success(servers);

  @override
  Future<Result<List<MusicServer>>> getOnlineServers() async =>
      ResultHelper.success(servers.where((s) => s.isAvailable).toList());

  @override
  Future<Result<MusicServer?>> getServerById(String serverId) async =>
      ResultHelper.success(servers.where((s) => s.id == serverId).firstOrNull);

  @override
  Future<Result<String?>> getCredentials(String serverId) async =>
      ResultHelper.success('secret-$serverId');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A Navidrome `getPlayQueue` payload.
Map<String, dynamic> _navidromePlayQueue({
  required List<String> ids,
  String? current,
  int? position,
  String? changed,
}) => {
  'subsonic-response': {
    'status': 'ok',
    'version': '1.16.1',
    'type': 'navidrome',
    'serverVersion': '0.53.3 (13af8ed4)',
    'openSubsonic': true,
    'playQueue': {
      'entry': [
        for (final id in ids)
          {
            'id': id,
            'parent': 'album-$id',
            'isDir': false,
            'title': 'Song $id',
            'album': 'Album',
            'artist': 'Artist',
            'duration': 215,
            'bitRate': 320,
            'suffix': 'mp3',
            'contentType': 'audio/mpeg',
            'isVideo': false,
            'type': 'music',
            'albumId': 'album-$id',
            'artistId': 'artist-1',
            'created': '2024-03-02T18:21:07.371405443Z',
          },
      ],
      'current': ?current,
      'position': ?position,
      'username': 'admin',
      'changed': ?changed,
      'changedBy': 'Omnisonic',
    },
  },
};

void main() {
  late _RecordingApiClient api;
  late PlaybackTrackingService service;

  final serverA = testServer(id: 'serverA', name: 'A');
  final serverB = testServer(id: 'serverB', name: 'B');

  setUp(() {
    api = _RecordingApiClient();
    service = PlaybackTrackingService(
      api,
      _FakeServerRepository([serverA, serverB]),
    );
  });

  tearDown(() => service.dispose());

  group('writes go to the track\'s own server', () {
    test('now playing and scrobble use the server of the track', () async {
      // serverA is listed first; the track lives on serverB.
      final track = testTrack(
        id: 'serverB_song_1',
        serverId: 'serverB',
        duration: const Duration(milliseconds: 100),
      );

      service.startTrackingTrack(track);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(api.scrobbles, [
        (serverId: 'serverB', id: 'song_1', submission: false),
        (serverId: 'serverB', id: 'song_1', submission: true),
      ]);
    });

    test('the queue is saved on the current track\'s server with only that '
        'server\'s tracks', () async {
      final queue = [
        testTrack(id: 'serverA_a1', serverId: 'serverA'),
        testTrack(id: 'serverB_b1', serverId: 'serverB'),
        testTrack(id: 'serverA_a2', serverId: 'serverA'),
        testTrack(id: 'serverB_b2', serverId: 'serverB'),
      ];

      await service.savePlayQueue(queue, 3, const Duration(seconds: 42));

      expect(api.savedQueues, hasLength(1));
      final saved = api.savedQueues.single;
      expect(saved.serverId, 'serverB');
      expect(saved.ids, ['b1', 'b2']);
      expect(saved.current, 'b2');
      expect(saved.position, 42000);
    });

    test('an unchanged queue is not saved twice', () async {
      final queue = testTracks(3, serverId: 'serverA');

      await service.savePlayQueue(queue, 1, const Duration(seconds: 10));
      await service.savePlayQueue(
        queue,
        1,
        const Duration(seconds: 10, milliseconds: 300),
      );
      await service.savePlayQueue(queue, 1, const Duration(seconds: 11));

      expect(api.savedQueues.map((q) => q.position), [10000, 11000]);
    });
  });

  group('queueToSave', () {
    test('keeps a bounded window that contains the current track', () {
      final queue = testTracks(1000, serverId: 'serverA');

      final window = PlaybackTrackingService.queueToSave(queue, 500);

      expect(window, hasLength(PlaybackTrackingService.maxSavedQueueLength));
      expect(window, contains(queue[500]));
      expect(window.first, queue[480]);
    });

    test('shifts the window back near the end of the queue', () {
      final queue = testTracks(1000, serverId: 'serverA');

      final window = PlaybackTrackingService.queueToSave(queue, 999);

      expect(window, hasLength(PlaybackTrackingService.maxSavedQueueLength));
      expect(window.last, queue[999]);
    });
  });

  group('scrobbling counts listening time only', () {
    test('a track loaded paused is not reported until it plays', () async {
      final track = testTrack(
        id: 'serverA_t1',
        serverId: 'serverA',
        duration: const Duration(milliseconds: 200),
      );

      service.startTrackingTrack(track, isPlaying: false);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(api.scrobbles, isEmpty);

      service.setPlaying(true);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      service.setPlaying(false);
      expect(api.scrobbles.map((s) => s.submission), [false]);

      // Paused well past the threshold: still not a play.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(api.scrobbles.map((s) => s.submission), [false]);

      service.setPlaying(true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(api.scrobbles.map((s) => s.submission), [false, true]);
    });
  });

  group('getPlayQueue', () {
    test('restores the most recently changed queue across servers', () async {
      api.playQueues['serverA'] = _navidromePlayQueue(
        ids: ['old1', 'old2'],
        current: 'old2',
        position: 1000,
        changed: '2024-05-01T10:00:00.123456789Z',
      );
      api.playQueues['serverB'] = _navidromePlayQueue(
        ids: ['new1', 'new2', 'new3'],
        current: 'new2',
        position: 42000,
        changed: '2024-05-02T09:30:00.5Z',
      );

      final state = await service.getPlayQueue();

      expect(state, isNotNull);
      expect(state!.serverId, 'serverB');
      expect(state.tracks.map((t) => t.id), [
        'serverB_new1',
        'serverB_new2',
        'serverB_new3',
      ]);
      expect(state.currentIndex, 1);
      expect(state.position, const Duration(seconds: 42));
    });

    test('a queue whose current track is gone starts from the top', () async {
      api.playQueues['serverA'] = _navidromePlayQueue(
        ids: ['s1', 's2'],
        current: 'missing',
        position: 30000,
        changed: '2024-05-01T10:00:00Z',
      );

      final state = await service.getPlayQueue();

      expect(state!.currentIndex, 0);
      expect(state.position, isNull);
    });

    test('returns null when no server has a saved queue', () async {
      expect(await service.getPlayQueue(), isNull);
    });
  });
}
