import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';

void main() {
  group('DeduplicationEngine', () {
    late DeduplicationEngine engine;

    setUp(() {
      engine = DeduplicationEngine();
    });

    test('should detect duplicate tracks with identical metadata', () {
      // Arrange
      final track1 = Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://server1/stream/1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final track2 = Track(
        id: '2',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 32), // Slightly different
        serverId: 'server2',
        streamUrl: 'http://server2/stream/2',
        quality: AudioQuality.lossless,
        lastModified: DateTime.now(),
      );

      final tracks = [track1, track2];

      // Act
      final duplicateGroups = engine.detectDuplicates(tracks);

      // Assert
      expect(duplicateGroups.length, equals(1));
      expect(duplicateGroups.values.first.length, equals(2));
    });

    test('should calculate similarity score correctly', () {
      // Arrange
      final track1 = Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://server1/stream/1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final track2 = Track(
        id: '2',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server2',
        streamUrl: 'http://server2/stream/2',
        quality: AudioQuality.lossless,
        lastModified: DateTime.now(),
      );

      // Act
      final similarity = engine.calculateSimilarityScore(track1, track2);

      // Assert
      expect(similarity, greaterThan(0.9)); // Should be very similar
    });

    test('should select representative track with highest quality', () {
      // Arrange
      final track1 = Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://server1/stream/1',
        quality: AudioQuality.medium,
        lastModified: DateTime.now(),
      );

      final track2 = Track(
        id: '2',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server2',
        streamUrl: 'http://server2/stream/2',
        quality: AudioQuality.lossless,
        lastModified: DateTime.now(),
      );

      final duplicates = [track1, track2];

      // Act
      final representative = engine.selectRepresentativeTrack(duplicates);

      // Assert
      expect(
        representative.id,
        equals('2'),
      ); // Should select the lossless quality track
      expect(representative.quality, equals(AudioQuality.lossless));
    });

    test('should not detect duplicates for different songs', () {
      // Arrange
      final track1 = Track(
        id: '1',
        title: 'Song One',
        artist: 'Artist One',
        album: 'Album One',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://server1/stream/1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final track2 = Track(
        id: '2',
        title: 'Song Two',
        artist: 'Artist Two',
        album: 'Album Two',
        duration: const Duration(minutes: 4, seconds: 15),
        serverId: 'server2',
        streamUrl: 'http://server2/stream/2',
        quality: AudioQuality.lossless,
        lastModified: DateTime.now(),
      );

      final tracks = [track1, track2];

      // Act
      final duplicateGroups = engine.detectDuplicates(tracks);

      // Assert
      expect(duplicateGroups.length, equals(0));
    });
  });
}
