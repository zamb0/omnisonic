import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';

/// The pairwise pass `detectDuplicates` replaced, kept here as the oracle:
/// same greedy grouping, every pair compared, with the duration tolerance
/// applied explicitly.
Map<String, List<Track>> referenceDetectDuplicates(
  DeduplicationEngine engine,
  List<Track> tracks, {
  double threshold = 0.85,
  int maxDurationDifferenceSeconds = 10,
}) {
  final groups = <String, List<Track>>{};
  final processed = <String>{};
  var groupId = 0;

  for (var i = 0; i < tracks.length; i++) {
    final current = tracks[i];
    if (processed.contains(current.id)) continue;

    final duplicates = <Track>[current];
    processed.add(current.id);

    for (var j = i + 1; j < tracks.length; j++) {
      final candidate = tracks[j];
      if (processed.contains(candidate.id)) continue;

      final durationDelta =
          (current.duration.inSeconds - candidate.duration.inSeconds).abs();
      if (durationDelta > maxDurationDifferenceSeconds) continue;

      if (engine.calculateSimilarityScore(current, candidate) >= threshold) {
        duplicates.add(candidate);
        processed.add(candidate.id);
      }
    }

    if (duplicates.length > 1) {
      groups['duplicate_group_${groupId++}'] = duplicates;
    }
  }

  return groups;
}

/// Builds a library where roughly every third track is a near-copy of an
/// earlier one, with the kind of metadata drift real servers produce.
List<Track> buildLibrary(int count, {int seed = 7}) {
  final random = Random(seed);
  const titles = [
    'Paranoid Android',
    'The Less I Know The Better',
    'Teardrop',
    'Bohemian Rhapsody',
    'Everything In Its Right Place',
    'Midnight City',
    'Blue Monday',
    'Digital Love',
  ];
  const artists = ['Radiohead', 'Tame Impala', 'Massive Attack', 'Queen'];
  const albums = ['OK Computer', 'Currents', 'Mezzanine', 'A Night At The Opera'];

  final tracks = <Track>[];
  for (var i = 0; i < count; i++) {
    final copyOf = tracks.isNotEmpty && i % 3 == 0
        ? tracks[random.nextInt(tracks.length)]
        : null;

    if (copyOf != null) {
      tracks.add(
        Track(
          id: 'server${i % 3}_$i',
          title: '${copyOf.title} ',
          artist: copyOf.artist.toLowerCase(),
          album: '${copyOf.album}!',
          duration: copyOf.duration + Duration(seconds: random.nextInt(9) - 4),
          serverId: 'server${i % 3}',
          streamUrl: 'http://example.com/$i',
          quality: AudioQuality.values[random.nextInt(AudioQuality.values.length)],
          lastModified: DateTime(2026),
        ),
      );
    } else {
      tracks.add(
        Track(
          id: 'server${i % 3}_$i',
          title: titles[random.nextInt(titles.length)],
          artist: artists[random.nextInt(artists.length)],
          album: albums[random.nextInt(albums.length)],
          duration: Duration(seconds: 90 + random.nextInt(300)),
          serverId: 'server${i % 3}',
          streamUrl: 'http://example.com/$i',
          quality: AudioQuality.values[random.nextInt(AudioQuality.values.length)],
          lastModified: DateTime(2026),
        ),
      );
    }
  }
  return tracks;
}

void main() {
  late DeduplicationEngine engine;

  setUp(() => engine = DeduplicationEngine());

  test('duration bucketing produces the same groups as a full pairwise pass', () {
    for (final seed in [1, 2, 3, 4, 5]) {
      final tracks = buildLibrary(300, seed: seed);

      final actual = engine.detectDuplicates(tracks);
      final expected = referenceDetectDuplicates(engine, tracks);

      String describe(Map<String, List<Track>> groups) => groups.entries
          .map((e) => '${e.key}: ${e.value.map((t) => t.id).join(",")}')
          .join('\n');

      expect(describe(actual), describe(expected), reason: 'seed $seed');
    }
  });

  test('tracks further apart than the duration tolerance are not duplicates', () {
    final base = Track(
      id: 'a_1',
      title: 'Teardrop',
      artist: 'Massive Attack',
      album: 'Mezzanine',
      duration: const Duration(minutes: 5),
      serverId: 'a',
      streamUrl: 'http://example.com/1',
      quality: AudioQuality.high,
      lastModified: DateTime(2026),
    );
    final longEdit = Track(
      id: 'b_1',
      title: 'Teardrop',
      artist: 'Massive Attack',
      album: 'Mezzanine',
      duration: const Duration(minutes: 9),
      serverId: 'b',
      streamUrl: 'http://example.com/2',
      quality: AudioQuality.high,
      lastModified: DateTime(2026),
    );

    expect(engine.detectDuplicates([base, longEdit]), isEmpty);
  });

  test('selectRepresentativeTrack does not reorder the caller list', () {
    final tracks = buildLibrary(6, seed: 11);
    final order = tracks.map((t) => t.id).toList();

    engine.selectRepresentativeTrack(tracks);

    expect(tracks.map((t) => t.id).toList(), order);
  });

  test('detects duplicates in a 5000-track library quickly', () {
    final tracks = buildLibrary(5000);

    final stopwatch = Stopwatch()..start();
    final groups = engine.detectDuplicates(tracks);
    stopwatch.stop();

    expect(groups, isNotEmpty);
    // The pairwise version needs ~12.5M comparisons here; bucketing keeps this
    // well under a second, so a generous ceiling still catches a regression to
    // quadratic behaviour.
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason: 'took ${stopwatch.elapsedMilliseconds}ms',
    );
  });
}
