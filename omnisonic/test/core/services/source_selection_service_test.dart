import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:omnisonic/core/services/source_selection_service.dart';
import 'package:omnisonic/core/repositories/server_repository.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/errors/result.dart';

import 'source_selection_service_test.mocks.dart';

@GenerateMocks([ServerRepository])
void main() {
  group('SourceSelectionService', () {
    late SourceSelectionService service;
    late MockServerRepository mockServerRepository;

    setUp(() {
      mockServerRepository = MockServerRepository();
      service = SourceSelectionService(serverRepository: mockServerRepository);
    });

    test('should select best quality track from available sources', () async {
      // Arrange
      final lowQualityTrack = Track(
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

      final highQualityTrack = Track(
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

      final server1 = MusicServer(
        id: 'server1',
        name: 'Server 1',
        url: 'http://server1',
        username: 'user1',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      final server2 = MusicServer(
        id: 'server2',
        name: 'Server 2',
        url: 'http://server2',
        username: 'user2',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      when(mockServerRepository.getServerById('server1'))
          .thenAnswer((_) async => ResultHelper.success(server1));
      when(mockServerRepository.getServerById('server2'))
          .thenAnswer((_) async => ResultHelper.success(server2));

      final duplicateTracks = [lowQualityTrack, highQualityTrack];

      // Act
      final result = await service.selectBestSource(duplicateTracks);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, equals('2')); // Should select lossless quality
      expect(result.valueOrNull?.quality, equals(AudioQuality.lossless));
    });

    test('should prefer cached tracks over non-cached', () async {
      // Arrange
      final nonCachedTrack = Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://server1/stream/1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
        isCached: false,
      );

      final cachedTrack = Track(
        id: '2',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server2',
        streamUrl: 'http://server2/stream/2',
        quality: AudioQuality.high, // Same quality
        lastModified: DateTime.now(),
        isCached: true,
        cachePath: '/cache/track2.mp3',
      );

      final server1 = MusicServer(
        id: 'server1',
        name: 'Server 1',
        url: 'http://server1',
        username: 'user1',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      final server2 = MusicServer(
        id: 'server2',
        name: 'Server 2',
        url: 'http://server2',
        username: 'user2',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      when(mockServerRepository.getServerById('server1'))
          .thenAnswer((_) async => ResultHelper.success(server1));
      when(mockServerRepository.getServerById('server2'))
          .thenAnswer((_) async => ResultHelper.success(server2));

      final duplicateTracks = [nonCachedTrack, cachedTrack];

      // Act
      final result = await service.selectBestSource(duplicateTracks);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, equals('2')); // Should select cached track
      expect(result.valueOrNull?.isCached, isTrue);
    });

    test('should return failure when no sources are available', () async {
      // Arrange
      final track = Track(
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

      final server = MusicServer(
        id: 'server1',
        name: 'Server 1',
        url: 'http://server1',
        username: 'user1',
        status: ServerStatus.offline, // Server is offline
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      when(mockServerRepository.getServerById('server1'))
          .thenAnswer((_) async => ResultHelper.success(server));

      final duplicateTracks = [track];

      // Act
      final result = await service.selectBestSource(duplicateTracks);

      // Assert
      expect(result.isFailure, isTrue);
    });

    test('should provide fallback source when primary fails', () async {
      // Arrange
      final primaryTrack = Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server1',
        streamUrl: 'http://server1/stream/1',
        quality: AudioQuality.lossless,
        lastModified: DateTime.now(),
      );

      final fallbackTrack = Track(
        id: '2',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        serverId: 'server2',
        streamUrl: 'http://server2/stream/2',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final server2 = MusicServer(
        id: 'server2',
        name: 'Server 2',
        url: 'http://server2',
        username: 'user2',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      when(mockServerRepository.getServerById('server2'))
          .thenAnswer((_) async => ResultHelper.success(server2));

      final duplicateTracks = [primaryTrack, fallbackTrack];

      // Act
      final result = await service.selectFallbackSource(duplicateTracks, '1');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, equals('2')); // Should select fallback
    });
  });
}