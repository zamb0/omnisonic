import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/repositories/server_repository.dart';
import 'package:omnisonic/core/services/device_identity.dart';
import 'package:omnisonic/features/playback/data/datasources/handoff_service.dart';
import 'package:omnisonic/features/playback/data/datasources/playback_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/entity_factories.dart';

/// Moving playback between devices through the server's saved play queue.
void main() {
  late _FakeTracking tracking;
  late DeviceIdentity identity;
  late HandoffService handoff;
  late List<HandoffEvent> events;
  final now = DateTime.utc(2026, 11, 9, 12);
  final queue = testTracks(3);
  var playing = queue[1];

  const otherDevice = 'Omnisonic (MacBook · 99aa00)';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'handoff_device_id': 'abc123ffffffffffffffffffffffffff',
      'handoff_device_name': 'Pixel',
    });
    identity = DeviceIdentity();
    await identity.load();
    tracking = _FakeTracking();
    handoff = HandoffService(
      tracking,
      _Servers([testServer(id: 'server1')]),
      identity,
      clock: () => now,
      pauseSettle: const Duration(milliseconds: 20),
    );
    playing = queue[1];
    handoff.attach(
      () => (
        queue: queue,
        index: queue.indexOf(playing),
        position: Duration.zero,
      ),
    );
    events = [];
    handoff.events.listen(events.add);
  });

  tearDown(() => handoff.dispose());

  /// The server's queue, saved by [by] at [at].
  void serverHas(String? by, DateTime at) {
    tracking.queues['server1'] = PlayQueueState(
      tracks: queue,
      currentIndex: 2,
      position: const Duration(seconds: 30),
      serverId: 'server1',
      changed: at,
      changedBy: by,
    );
  }

  test('the client name carries the device name and its tag', () {
    expect(identity.clientName, 'Omnisonic (Pixel · abc123)');
    expect(identity.isThisDevice('Omnisonic (Renamed · abc123)'), isTrue);
    expect(identity.isThisDevice(otherDevice), isFalse);
    expect(DeviceIdentity.parseClient('Feishin'), (name: 'Feishin', tag: null));
  });

  test('starting to play claims playback with a forced save', () async {
    await handoff.localPlaybackStarted();

    expect(tracking.saves, [(index: 1, force: true)]);
    expect(handoff.isActive, isTrue);
  });

  test('a newer save by another device stops this one', () async {
    await handoff.localPlaybackStarted();
    serverHas(identity.clientName, now);
    await handoff.refresh(); // sees its own save: the baseline

    serverHas(otherDevice, now.add(const Duration(seconds: 3)));
    await handoff.refresh();

    expect(events.single, isA<PlaybackTakenOver>());
    expect((events.single as PlaybackTakenOver).deviceName, 'MacBook');
    expect(handoff.isActive, isFalse);
    expect(handoff.remoteSession!.deviceName, 'MacBook');
  });

  test('another app saving its queue is not a takeover', () async {
    await handoff.localPlaybackStarted();
    serverHas(identity.clientName, now);
    await handoff.refresh();

    // Feishin and others save while paused too.
    serverHas('Feishin', now.add(const Duration(seconds: 3)));
    await handoff.refresh();

    expect(events, isEmpty);
    expect(handoff.isActive, isTrue);
  });

  test('a device that only restored the queue never saves it', () async {
    serverHas(otherDevice, now);

    await handoff.saveIfActive();
    handoff.localStateChanged();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(tracking.saves, isEmpty);
  });

  test('pausing saves only after making sure nobody took over', () async {
    await handoff.localPlaybackStarted();
    serverHas(identity.clientName, now);
    await handoff.refresh();
    tracking.saves.clear();

    serverHas(otherDevice, now.add(const Duration(seconds: 2)));
    await handoff.localPlaybackPaused();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    // Saving now would have buried the other device's takeover.
    expect(tracking.saves, isEmpty);
    expect(handoff.isActive, isFalse);
  });

  test('a track change is not a new takeover', () async {
    await handoff.localPlaybackStarted();
    tracking.saves.clear();

    // The player stops for a moment between two tracks.
    await handoff.localPlaybackPaused();
    playing = queue[2];
    await handoff.localPlaybackStarted();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(tracking.saves, [(index: 2, force: true)]);
  });

  group('remote session', () {
    test('shows what another device is playing, and where', () async {
      serverHas(otherDevice, now.subtract(const Duration(seconds: 10)));

      await handoff.refresh();

      final remote = handoff.remoteSession!;
      expect(remote.deviceName, 'MacBook');
      expect(remote.currentTrack, queue[2]);
      expect(remote.isLikelyPlaying(now), isTrue);
      expect(remote.estimatedPosition(now), const Duration(seconds: 40));
    });

    test('a stale save is not "playing"', () async {
      serverHas(otherDevice, now.subtract(const Duration(minutes: 5)));

      await handoff.refresh();

      final remote = handoff.remoteSession!;
      expect(remote.isLikelyPlaying(now), isFalse);
      expect(remote.estimatedPosition(now), const Duration(seconds: 30));
    });

    test('this device\'s own save is no remote session', () async {
      serverHas(identity.clientName, now);

      await handoff.refresh();

      expect(handoff.remoteSession, isNull);
    });
  });
}

class _FakeTracking implements PlaybackTrackingService {
  final queues = <String, PlayQueueState>{};
  final saves = <({int index, bool force})>[];

  @override
  Future<bool> savePlayQueue(
    List<Track> queue,
    int currentIndex,
    Duration position, {
    bool force = false,
  }) async {
    saves.add((index: currentIndex, force: force));
    return true;
  }

  @override
  Future<PlayQueueState?> getPlayQueueFrom(String serverId) async =>
      queues[serverId];

  @override
  Future<PlayQueueState?> getPlayQueue() async =>
      queues.values.isEmpty ? null : queues.values.first;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servers implements ServerRepository {
  _Servers(this.servers);

  final List<MusicServer> servers;

  @override
  Future<Result<List<MusicServer>>> getAllServers() async =>
      ResultHelper.success(servers);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
