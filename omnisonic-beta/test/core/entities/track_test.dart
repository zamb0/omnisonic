import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';

void main() {
  group('Track Entity', () {
    test('should create track with required fields', () {
      final track = Track(
        id: 'track1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://example.com/stream/track1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      expect(track.id, 'track1');
      expect(track.title, 'Test Song');
      expect(track.artist, 'Test Artist');
      expect(track.album, 'Test Album');
      expect(track.duration, const Duration(minutes: 3, seconds: 30));
      expect(track.serverId, 'server1');
      expect(track.streamUrl, 'http://example.com/stream/track1');
      expect(track.quality, AudioQuality.high);
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final track1 = Track(
        id: 'track1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://example.com/stream/track1',
        quality: AudioQuality.high,
        lastModified: now,
      );

      final track2 = Track(
        id: 'track1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://example.com/stream/track1',
        quality: AudioQuality.high,
        lastModified: now,
      );

      expect(track1, equals(track2));
      expect(track1.hashCode, equals(track2.hashCode));
    });

    test('should have different hash codes for different tracks', () {
      final now = DateTime.now();
      final track1 = Track(
        id: 'track1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://example.com/stream/track1',
        quality: AudioQuality.high,
        lastModified: now,
      );

      final track2 = Track(
        id: 'track2',
        title: 'Different Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://example.com/stream/track2',
        quality: AudioQuality.high,
        lastModified: now,
      );

      expect(track1, isNot(equals(track2)));
      expect(track1.hashCode, isNot(equals(track2.hashCode)));
    });
  });
}