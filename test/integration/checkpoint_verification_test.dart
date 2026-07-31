import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/core/services/source_selection_service.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/errors/failures.dart';

/// Checkpoint verification test for core business logic
///
/// This test verifies that all core components are properly integrated
/// and can work together without compilation errors.
void main() {
  group('Checkpoint Verification', () {
    late GetIt getIt;

    setUpAll(() async {
      getIt = GetIt.instance;
      await configureDependencies();
    });

    tearDownAll(() async {
      await getIt.reset();
    });

    test('should verify dependency injection is working', () {
      // Verify that all core repositories can be resolved
      expect(() => getIt<MusicRepository>(), returnsNormally);
      expect(() => getIt<ServerRepository>(), returnsNormally);
      expect(() => getIt<PlaybackRepository>(), returnsNormally);
      expect(() => getIt<PlaylistRepository>(), returnsNormally);
    });

    test('should verify core services are available', () {
      // Verify that core services can be resolved
      expect(() => getIt<DeduplicationEngine>(), returnsNormally);
      expect(() => getIt<SourceSelectionService>(), returnsNormally);
    });

    test('should verify entities can be created', () {
      // Test Track entity creation
      final track = Track(
        id: 'test-track-1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3, seconds: 30),
        serverId: 'test-server',
        streamUrl: 'https://example.com/stream/test-track-1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      expect(track.id, equals('test-track-1'));
      expect(track.title, equals('Test Song'));
      expect(track.isValid, isTrue);

      // Test MusicServer entity creation
      final server = MusicServer(
        id: 'test-server-1',
        name: 'Test Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
      );

      expect(server.id, equals('test-server-1'));
      expect(server.name, equals('Test Server'));
      expect(server.isValid, isTrue);
      expect(server.isAvailable, isTrue);

      // Test Album entity creation
      final album = Album(
        id: 'test-album-1',
        title: 'Test Album',
        artist: 'Test Artist',
        serverId: 'test-server',
        lastModified: DateTime.now(),
        year: 2023,
        trackCount: 10,
        duration: Duration(minutes: 45),
      );

      expect(album.id, equals('test-album-1'));
      expect(album.title, equals('Test Album'));

      // Test Artist entity creation
      final artist = Artist(
        id: 'test-artist-1',
        name: 'Test Artist',
        serverId: 'test-server',
        lastModified: DateTime.now(),
        albumCount: 5,
      );

      expect(artist.id, equals('test-artist-1'));
      expect(artist.name, equals('Test Artist'));

      // Test Playlist entity creation
      final playlist = Playlist(
        id: 'test-playlist-1',
        name: 'Test Playlist',
        trackIds: ['track-1', 'track-2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(playlist.id, equals('test-playlist-1'));
      expect(playlist.name, equals('Test Playlist'));
      expect(playlist.trackCount, equals(2));
    });

    test('should verify deduplication engine functionality', () {
      final deduplicationEngine = getIt<DeduplicationEngine>();

      // Create test tracks with similar metadata
      final track1 = Track(
        id: 'track-1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3, seconds: 30),
        serverId: 'server-1',
        streamUrl: 'https://server1.com/stream/track-1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final track2 = Track(
        id: 'track-2',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3, seconds: 30),
        serverId: 'server-2',
        streamUrl: 'https://server2.com/stream/track-2',
        quality: AudioQuality.medium,
        lastModified: DateTime.now(),
      );

      // Test duplicate detection
      final tracks = [track1, track2];
      final duplicateGroups = deduplicationEngine.detectDuplicates(tracks);
      expect(duplicateGroups, isA<Map<String, List<Track>>>());
    });

    test('should verify repository interfaces are properly defined', () async {
      final musicRepository = getIt<MusicRepository>();
      final serverRepository = getIt<ServerRepository>();
      final playbackRepository = getIt<PlaybackRepository>();
      final playlistRepository = getIt<PlaylistRepository>();

      // Test that repository methods exist and return proper types
      expect(musicRepository.getAllTracks, isA<Function>());
      expect(musicRepository.getAllAlbums, isA<Function>());
      expect(musicRepository.getAllArtists, isA<Function>());

      expect(serverRepository.getAllServers, isA<Function>());
      expect(serverRepository.addServer, isA<Function>());
      expect(serverRepository.removeServer, isA<Function>());

      expect(playbackRepository.play, isA<Function>());
      expect(playbackRepository.pause, isA<Function>());
      expect(playbackRepository.stop, isA<Function>());

      expect(playlistRepository.getAllPlaylists, isA<Function>());
      expect(playlistRepository.createPlaylist, isA<Function>());
      expect(playlistRepository.deletePlaylist, isA<Function>());
    });

    test('should verify error handling types are working', () {
      // Test Result type functionality
      final successResult = ResultHelper.success('test value');
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isFailure, isFalse);
      expect(successResult.valueOrNull, equals('test value'));

      final failureResult = ResultHelper.failure<String>(
        UnknownFailure('test error'),
      );
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.isFailure, isTrue);
      expect(failureResult.valueOrNull, isNull);
      expect(failureResult.failureOrNull, isA<UnknownFailure>());
    });
  });
}
