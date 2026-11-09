import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/playback_repository.dart'
    show PlaybackState, RepeatMode;
import 'package:omnisonic/features/playback/data/datasources/adaptive_streaming_service.dart';
import 'package:omnisonic/features/playback/data/datasources/audio_player_data_source.dart';
import 'package:omnisonic/features/playback/data/datasources/platform_audio_player.dart';

import '../../helpers/entity_factories.dart';

/// The queue logic of the audio data source, against a player that only
/// records what it was asked to load.
void main() {
  late _FakePlayer player;
  late AudioPlayerDataSource source;
  late List<PlaybackState> states;

  setUp(() {
    player = _FakePlayer();
    source = AudioPlayerDataSource(
      adaptiveStreamingService: _FakeAdaptiveStreaming(),
      audioPlayer: player,
    );
    states = [];
    source.observePlaybackState().listen(states.add);
  });

  tearDown(() => source.dispose());

  List<String> ids(List<Track> tracks) => [for (final t in tracks) t.id];

  test('shuffle plays every track once, then stops', () async {
    final queue = testTracks(8);
    await source.setQueue(queue);
    await source.play(queue.first);
    await source.setShuffleMode(true);

    final shuffled = source.getCurrentQueue();
    expect(shuffled.first, queue.first);
    expect(shuffled.toSet(), queue.toSet());

    for (var i = 0; i < queue.length - 1; i++) {
      await player.finish();
    }
    expect(player.loaded.toSet(), {for (final t in queue) '/stream/${t.id}'});
    expect(player.loaded, hasLength(queue.length));

    // The last one ends the queue: with repeat off, shuffle stops too.
    await player.finish();
    expect(source.getCurrentTrack(), isNull);
  });

  test(
    'turning shuffle off restores the order around the current track',
    () async {
      final queue = testTracks(6);
      await source.setQueue(queue, startIndex: 2);
      await source.setShuffleMode(true);
      await source.skipToNext();
      final current = source.getCurrentTrack()!;

      await source.setShuffleMode(false);

      expect(ids(source.getCurrentQueue()), ids(queue));
      expect(source.getCurrentState().currentIndex, queue.indexOf(current));
    },
  );

  test('a track that fails to load is skipped, not the end', () async {
    final queue = [
      testTrack(id: 'server1_a', title: 'A'),
      testTrack(id: 'server1_bad', title: 'Broken'),
      testTrack(id: 'server1_c', title: 'C'),
    ];
    player.failing.add('/stream/${queue[1].id}');
    await source.setQueue(queue);
    await source.play(queue.first);

    await player.finish();

    expect(source.getCurrentTrack()!.id, 'server1_c');
    expect(player.playing, isTrue);
    expect(states.map((s) => s.error).whereType<String>(), [
      'Skipped "Broken": it could not be played.',
    ]);
  });

  test('when nothing left can play, playback stops and says so', () async {
    final queue = [
      testTrack(id: 'server1_a'),
      testTrack(id: 'server1_x'),
      testTrack(id: 'server1_y'),
    ];
    player.failing.addAll([for (final t in queue.skip(1)) '/stream/${t.id}']);
    await source.setQueue(queue);
    await source.play(queue.first);

    await player.finish();

    expect(source.getCurrentTrack(), isNull);
    expect(
      states.last.error ?? states.map((s) => s.error).whereType<String>().last,
      "Couldn't play any of the remaining tracks.",
    );
  });

  test('removing the only track empties the queue cleanly', () async {
    await source.setQueue([testTrack()]);

    final result = await source.removeFromQueue(0);
    await pumpEventQueue();

    expect(result.isSuccess, isTrue);
    expect(source.getCurrentQueue(), isEmpty);
    expect(states.last.queue, isEmpty);
  });

  test('an empty queue can be set', () async {
    final result = await source.setQueue(const []);

    expect(result.isSuccess, isTrue);
    expect(source.getCurrentQueue(), isEmpty);
  });

  test('"play next" into an empty queue makes it the first track', () async {
    await source.insertInQueue(testTrack(), 0);

    final state = source.getCurrentState();
    expect(state.queue, hasLength(1));
    expect(state.currentIndex, 0);
  });

  test('repeat all wraps round to the first track', () async {
    final queue = testTracks(2);
    await source.setQueue(queue, startIndex: 1);
    await source.play(queue[1]);
    await source.setRepeatMode(RepeatMode.all);

    await player.finish();

    expect(source.getCurrentTrack(), queue.first);
  });
}

/// Loads by recording the URL; fails URLs in [failing]; [finish] ends the
/// current track the way the real players report it.
class _FakePlayer implements PlatformAudioPlayer {
  /// URL paths, i.e. `/stream/{trackId}` for the test tracks.
  final loaded = <String>[];
  final failing = <String>{};
  final _states = StreamController<PlayerState>.broadcast(sync: true);
  @override
  bool playing = false;

  Future<void> finish() async {
    _states.add(PlayerState.completed);
    // Let the data source's completion handling, and the state updates it
    // publishes, run to their end.
    await pumpEventQueue();
  }

  @override
  Future<void> setUrl(String url) async {
    // The data source adds quality parameters to the track's URL.
    final path = Uri.parse(url).path;
    if (failing.contains(path)) throw Exception('404 for $url');
    loaded.add(path);
  }

  @override
  Future<void> setFilePath(String path) => setUrl(path);

  @override
  Future<void> play() async => playing = true;

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> stop() async => playing = false;

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;

  @override
  Duration get position => Duration.zero;

  @override
  Duration? get duration => null;

  @override
  void dispose() => _states.close();
}

class _FakeAdaptiveStreaming implements AdaptiveStreamingService {
  @override
  Stream<AudioQuality> observeRecommendedQuality() => const Stream.empty();

  @override
  Future<Result<AudioQuality>> getOptimalQuality(Track track) async =>
      ResultHelper.success(track.quality);

  @override
  void reportBufferingStatus(bool isBuffering) {}

  @override
  void reportBufferLevel(int bufferPercentage) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
