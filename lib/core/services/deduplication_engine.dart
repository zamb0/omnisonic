import 'dart:math';
import '../entities/track.dart';

/// Service responsible for detecting and managing duplicate tracks across servers
class DeduplicationEngine {
  static const double _duplicateThreshold = 0.85;
  static const int _maxDurationDifferenceSeconds = 10;

  /// Groups tracks by similarity and returns duplicate groups
  /// Each group contains tracks that are considered duplicates
  ///
  /// Only tracks whose durations are within [_maxDurationDifferenceSeconds]
  /// of each other are compared, which is what makes this tractable: a naive
  /// pass compares every pair, so a 20k-track library costs 2×10⁸ Jaro-Winkler
  /// computations. Bucketing by duration first turns that into a handful of
  /// comparisons per track without changing which pairs can qualify — the
  /// duration tolerance is a precondition for being a duplicate, not just a
  /// 10% weight.
  Map<String, List<Track>> detectDuplicates(List<Track> tracks) {
    final duplicateGroups = <String, List<Track>>{};
    final processed = <String>{};
    var groupId = 0;

    // Normalized metadata is reused across every comparison a track takes
    // part in, instead of being recomputed (four strings, four regexes) on
    // each one.
    final normalized = [
      for (final track in tracks) _NormalizedTrack.of(track),
    ];

    // Candidate index buckets, keyed by duration / tolerance. Two tracks
    // within the tolerance are always in the same or an adjacent bucket.
    final buckets = <int, List<int>>{};
    for (var i = 0; i < tracks.length; i++) {
      buckets.putIfAbsent(_durationBucket(tracks[i]), () => []).add(i);
    }

    for (var i = 0; i < tracks.length; i++) {
      final currentTrack = tracks[i];
      if (processed.contains(currentTrack.id)) continue;

      final duplicates = <Track>[currentTrack];
      processed.add(currentTrack.id);

      final bucket = _durationBucket(currentTrack);
      final candidates = <int>[
        ...?buckets[bucket - 1],
        ...?buckets[bucket],
        ...?buckets[bucket + 1],
      ]..sort();

      for (final j in candidates) {
        if (j <= i) continue;

        final candidateTrack = tracks[j];
        if (processed.contains(candidateTrack.id)) continue;

        // Adjacent buckets can still be up to twice the tolerance apart, and
        // the tolerance is a precondition rather than a weight: two tracks
        // with identical metadata but a four-minute difference are a radio
        // edit and an extended mix, not duplicates.
        final durationDelta =
            (currentTrack.duration.inSeconds -
                    candidateTrack.duration.inSeconds)
                .abs();
        if (durationDelta > _maxDurationDifferenceSeconds) continue;

        final similarity = _similarityOf(normalized[i], normalized[j]);
        if (similarity >= _duplicateThreshold) {
          duplicates.add(candidateTrack);
          processed.add(candidateTrack.id);
        }
      }

      // Only create group if there are actual duplicates (more than 1 track)
      if (duplicates.length > 1) {
        final groupKey = 'duplicate_group_${groupId++}';
        duplicateGroups[groupKey] = duplicates;
      }
    }

    return duplicateGroups;
  }

  static int _durationBucket(Track track) =>
      track.duration.inSeconds ~/ _maxDurationDifferenceSeconds;

  /// Calculates similarity score between two tracks
  /// Returns a value between 0.0 and 1.0, where 1.0 means identical
  double calculateSimilarityScore(Track track1, Track track2) =>
      _similarityOf(_NormalizedTrack.of(track1), _NormalizedTrack.of(track2));

  double _similarityOf(_NormalizedTrack a, _NormalizedTrack b) {
    // Don't compare tracks from the same server with same ID
    if (a.serverId == b.serverId && a.id == b.id) {
      return 0.0;
    }

    double score = 0.0;

    // Title similarity (40% weight)
    score += _calculateStringSimilarity(a.title, b.title) * 0.4;

    // Artist similarity (30% weight)
    score += _calculateStringSimilarity(a.artist, b.artist) * 0.3;

    // Album similarity (20% weight)
    score += _calculateStringSimilarity(a.album, b.album) * 0.2;

    // Duration similarity (10% weight)
    score += _calculateDurationSimilarity(a.duration, b.duration) * 0.1;

    return score;
  }

  /// Selects the best representative track from a group of duplicates
  /// Based on audio quality, server availability, and other factors
  Track selectRepresentativeTrack(List<Track> duplicates) {
    if (duplicates.isEmpty) {
      throw ArgumentError('Cannot select representative from empty list');
    }

    if (duplicates.length == 1) {
      return duplicates.first;
    }

    // Sort a copy: the caller's list is usually a group held in a cache, and
    // reordering it in place would reorder that cache as a side effect.
    final ranked = List<Track>.of(duplicates);

    // Sort by quality (highest first), then by server availability
    ranked.sort((a, b) {
      // First, compare by audio quality
      final qualityComparison = b.quality.qualityScore.compareTo(
        a.quality.qualityScore,
      );
      if (qualityComparison != 0) return qualityComparison;

      // If quality is the same, prefer cached tracks
      if (a.isCached && !b.isCached) return -1;
      if (!a.isCached && b.isCached) return 1;

      // If both cached or both not cached, prefer by file size (larger is better)
      final sizeA = a.fileSize ?? 0;
      final sizeB = b.fileSize ?? 0;
      return sizeB.compareTo(sizeA);
    });

    return ranked.first;
  }

  // Compiled once; these used to be rebuilt on every normalization, of which
  // there are four per track comparison.
  static final RegExp _specialCharacters = RegExp(r'[^\w\s]');
  static final RegExp _repeatedWhitespace = RegExp(r'\s+');

  /// Normalizes a string for comparison by removing special characters,
  /// converting to lowercase, and trimming whitespace
  static String _normalizeString(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(_specialCharacters, '') // Remove special characters
        .replaceAll(_repeatedWhitespace, ' '); // Normalize whitespace
  }

  /// Calculates string similarity using Jaro-Winkler algorithm
  /// with fuzzy matching for slight variations in metadata
  double _calculateStringSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    // Use Jaro-Winkler similarity for better fuzzy matching
    return _jaroWinklerSimilarity(str1, str2);
  }

  /// Implements Jaro-Winkler similarity algorithm
  double _jaroWinklerSimilarity(String str1, String str2) {
    final jaroSimilarity = _jaroSimilarity(str1, str2);

    if (jaroSimilarity < 0.7) return jaroSimilarity;

    // Calculate common prefix length (up to 4 characters)
    int prefixLength = 0;
    final maxPrefix = min(4, min(str1.length, str2.length));

    for (int i = 0; i < maxPrefix; i++) {
      if (str1[i] == str2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    // Jaro-Winkler similarity with prefix scaling factor of 0.1
    return jaroSimilarity + (0.1 * prefixLength * (1 - jaroSimilarity));
  }

  /// Implements Jaro similarity algorithm
  double _jaroSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final matchWindow = (max(str1.length, str2.length) / 2).floor() - 1;
    if (matchWindow < 0) return 0.0;

    final str1Matches = List.filled(str1.length, false);
    final str2Matches = List.filled(str2.length, false);

    int matches = 0;
    int transpositions = 0;

    // Find matches
    for (int i = 0; i < str1.length; i++) {
      final start = max(0, i - matchWindow);
      final end = min(i + matchWindow + 1, str2.length);

      for (int j = start; j < end; j++) {
        if (str2Matches[j] || str1[i] != str2[j]) continue;

        str1Matches[i] = true;
        str2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // Count transpositions
    int k = 0;
    for (int i = 0; i < str1.length; i++) {
      if (!str1Matches[i]) continue;

      while (!str2Matches[k]) {
        k++;
      }

      if (str1[i] != str2[k]) transpositions++;
      k++;
    }

    final jaro =
        (matches / str1.length +
            matches / str2.length +
            (matches - transpositions / 2) / matches) /
        3;

    return jaro;
  }

  /// Calculates duration similarity between two tracks
  double _calculateDurationSimilarity(Duration duration1, Duration duration2) {
    final diffSeconds = (duration1.inSeconds - duration2.inSeconds).abs();

    if (diffSeconds == 0) return 1.0;
    if (diffSeconds > _maxDurationDifferenceSeconds) return 0.0;

    // Linear decay from 1.0 to 0.0 over the max difference
    return 1.0 - (diffSeconds / _maxDurationDifferenceSeconds);
  }

  /// Groups tracks by their normalized metadata for faster duplicate detection
  Map<String, List<Track>> groupTracksByMetadata(List<Track> tracks) {
    final groups = <String, List<Track>>{};

    for (final track in tracks) {
      final key = _generateMetadataKey(track);
      groups.putIfAbsent(key, () => []).add(track);
    }

    return groups;
  }

  /// Generates a normalized metadata key for grouping similar tracks
  static String _generateMetadataKey(Track track) {
    final normalizedTitle = _normalizeString(track.title);
    final normalizedArtist = _normalizeString(track.artist);
    final durationMinutes = (track.duration.inSeconds / 60).round();

    return '${normalizedTitle}_${normalizedArtist}_${durationMinutes}min';
  }
}

/// A track with its comparison fields normalized once up front.
class _NormalizedTrack {
  const _NormalizedTrack({
    required this.id,
    required this.serverId,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
  });

  factory _NormalizedTrack.of(Track track) => _NormalizedTrack(
    id: track.id,
    serverId: track.serverId,
    title: DeduplicationEngine._normalizeString(track.title),
    artist: DeduplicationEngine._normalizeString(track.artist),
    album: DeduplicationEngine._normalizeString(track.album),
    duration: track.duration,
  );

  final String id;
  final String serverId;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
}
