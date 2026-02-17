import 'dart:math';
import '../entities/track.dart';

/// Service responsible for detecting and managing duplicate tracks across servers
class DeduplicationEngine {
  static const double _duplicateThreshold = 0.85;
  static const int _maxDurationDifferenceSeconds = 10;

  /// Groups tracks by similarity and returns duplicate groups
  /// Each group contains tracks that are considered duplicates
  Map<String, List<Track>> detectDuplicates(List<Track> tracks) {
    final duplicateGroups = <String, List<Track>>{};
    final processedTracks = <String>{};
    var groupId = 0;

    for (int i = 0; i < tracks.length; i++) {
      final currentTrack = tracks[i];
      
      // Skip if already processed
      if (processedTracks.contains(currentTrack.id)) continue;

      final duplicates = <Track>[currentTrack];
      processedTracks.add(currentTrack.id);

      // Find similar tracks
      for (int j = i + 1; j < tracks.length; j++) {
        final candidateTrack = tracks[j];
        
        // Skip if already processed
        if (processedTracks.contains(candidateTrack.id)) continue;

        final similarity = calculateSimilarityScore(currentTrack, candidateTrack);
        
        if (similarity >= _duplicateThreshold) {
          duplicates.add(candidateTrack);
          processedTracks.add(candidateTrack.id);
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

  /// Calculates similarity score between two tracks
  /// Returns a value between 0.0 and 1.0, where 1.0 means identical
  double calculateSimilarityScore(Track track1, Track track2) {
    // Don't compare tracks from the same server with same ID
    if (track1.serverId == track2.serverId && track1.id == track2.id) {
      return 0.0;
    }

    double score = 0.0;

    // Title similarity (40% weight)
    final titleSimilarity = _calculateStringSimilarity(
      _normalizeString(track1.title),
      _normalizeString(track2.title),
    );
    score += titleSimilarity * 0.4;

    // Artist similarity (30% weight)
    final artistSimilarity = _calculateStringSimilarity(
      _normalizeString(track1.artist),
      _normalizeString(track2.artist),
    );
    score += artistSimilarity * 0.3;

    // Album similarity (20% weight)
    final albumSimilarity = _calculateStringSimilarity(
      _normalizeString(track1.album),
      _normalizeString(track2.album),
    );
    score += albumSimilarity * 0.2;

    // Duration similarity (10% weight)
    final durationSimilarity = _calculateDurationSimilarity(
      track1.duration,
      track2.duration,
    );
    score += durationSimilarity * 0.1;

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

    // Sort by quality (highest first), then by server availability
    duplicates.sort((a, b) {
      // First, compare by audio quality
      final qualityComparison = b.quality.qualityScore.compareTo(a.quality.qualityScore);
      if (qualityComparison != 0) return qualityComparison;

      // If quality is the same, prefer cached tracks
      if (a.isCached && !b.isCached) return -1;
      if (!a.isCached && b.isCached) return 1;

      // If both cached or both not cached, prefer by file size (larger is better)
      final sizeA = a.fileSize ?? 0;
      final sizeB = b.fileSize ?? 0;
      return sizeB.compareTo(sizeA);
    });

    return duplicates.first;
  }

  /// Normalizes a string for comparison by removing special characters,
  /// converting to lowercase, and trimming whitespace
  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
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

    final jaro = (matches / str1.length + 
                  matches / str2.length + 
                  (matches - transpositions / 2) / matches) / 3;

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
  String _generateMetadataKey(Track track) {
    final normalizedTitle = _normalizeString(track.title);
    final normalizedArtist = _normalizeString(track.artist);
    final durationMinutes = (track.duration.inSeconds / 60).round();
    
    return '${normalizedTitle}_${normalizedArtist}_${durationMinutes}min';
  }
}