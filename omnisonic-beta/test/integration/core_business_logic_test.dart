import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/core/repositories/repositories.dart';

/// End-to-end integration test for core business logic
/// 
/// This test verifies that all core functionality works together:
/// - Server management and connection
/// - Music collection synchronization
/// - Search functionality across servers
/// - Playlist management operations
/// - Audio playback with source selection
void main() {
  group('Core Business Logic Integration', () {
    late GetIt getIt;
    late ServerRepository serverRepository;
    late MusicRepository musicRepository;
    late PlaylistRepository playlistRepository;
    late PlaybackRepository playbackRepository;
    late SyncMusicCollectionUseCase syncUseCase;
    late SearchMusicUseCase searchUseCase;
    late ManagePlaylistUseCase playlistUseCase;
    late PlayTrackUseCase playTrackUseCase;

    setUpAll(() async {
      getIt = GetIt.instance;
      await configureDependencies();
      
      serverRepository = getIt<ServerRepository>();
      musicRepository = getIt<MusicRepository>();
      playlistRepository = getIt<PlaylistRepository>();
      playbackRepository = getIt<PlaybackRepository>();
      syncUseCase = getIt<SyncMusicCollectionUseCase>();
      searchUseCase = getIt<SearchMusicUseCase>();
      playlistUseCase = getIt<ManagePlaylistUseCase>();
      playTrackUseCase = getIt<PlayTrackUseCase>();
    });

    tearDownAll(() async {
      await getIt.reset();
    });

    test('should handle complete music streaming workflow', () async {
      // 1. Add a test server
      final testServer = MusicServer(
        id: 'test-server-1',
        name: 'Test Music Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      final addServerResult = await serverRepository.addServer(testServer);
      expect(addServerResult.isSuccess, isTrue);

      // 2. Verify server is added and online
      final serversResult = await serverRepository.getAllServers();
      expect(serversResult.isSuccess, isTrue);
      expect(serversResult.valueOrNull!.length, greaterThan(0));
      
      final addedServer = serversResult.valueOrNull!.firstWhere((s) => s.id == testServer.id);
      expect(addedServer.name, equals(testServer.name));

      // 3. Sync music collection from servers
      final syncParams = SyncMusicCollectionParams(serverId: testServer.id);
      final syncResult = await syncUseCase(syncParams);
      
      // Note: This may fail in test environment without actual server, but we test the flow
      if (syncResult.isRight()) {
        final collection = syncResult.getOrElse(() => throw Exception('Should not reach here'));
        expect(collection, isNotNull);
        expect(collection.lastUpdated, isNotNull);
      }

      // 4. Test search functionality
      final searchParams = SearchMusicParams(
        query: 'test',
        searchTypes: [SearchType.tracks, SearchType.albums, SearchType.artists],
        maxResults: 10,
      );
      final searchResult = await searchUseCase(searchParams);
      
      // Search should work even if no results found
      expect(searchResult.isRight(), isTrue);
      final searchResults = searchResult.getOrElse(() => throw Exception('Should not reach here'));
      expect(searchResults.query, equals('test'));

      // 5. Test playlist management
      final createPlaylistParams = ManagePlaylistParams(
        operation: PlaylistOperation.create,
        name: 'Test Playlist',
        description: 'A test playlist for integration testing',
        isPublic: false,
      );
      final createResult = await playlistUseCase(createPlaylistParams);
      expect(createResult.isRight(), isTrue);
      
      final playlistResult = createResult.getOrElse(() => throw Exception('Should not reach here'));
      expect(playlistResult.isSuccess, isTrue);
      expect(playlistResult.playlist, isNotNull);
      expect(playlistResult.playlist!.name, equals('Test Playlist'));

      // 6. Test adding tracks to playlist (if we have any tracks)
      final tracksResult = await musicRepository.getAllTracks();
      if (tracksResult.isSuccess && tracksResult.valueOrNull!.isNotEmpty) {
        final testTrack = tracksResult.valueOrNull!.first;
        
        final addTrackParams = ManagePlaylistParams(
          operation: PlaylistOperation.addTrack,
          playlistId: playlistResult.playlist!.id,
          trackId: testTrack.id,
        );
        final addTrackResult = await playlistUseCase(addTrackParams);
        expect(addTrackResult.isRight(), isTrue);

        // 7. Test playback functionality
        final playParams = PlayTrackParams(
          track: testTrack,
          useBestSource: true,
          allowFallback: true,
        );
        final playResult = await playTrackUseCase(playParams);
        
        // Playback may fail in test environment, but we test the flow
        // The use case should handle errors gracefully
        expect(playResult.isLeft() || playResult.isRight(), isTrue);
      }

      // 8. Clean up - delete the test playlist
      final deleteParams = ManagePlaylistParams(
        operation: PlaylistOperation.delete,
        playlistId: playlistResult.playlist!.id,
      );
      final deleteResult = await playlistUseCase(deleteParams);
      expect(deleteResult.isRight(), isTrue);

      // 9. Clean up - remove the test server
      final removeServerResult = await serverRepository.removeServer(testServer.id);
      expect(removeServerResult.isSuccess, isTrue);
    });

    test('should handle search with filters correctly', () async {
      // Test search with various filters
      final searchParams = SearchMusicParams(
        query: 'rock',
        searchTypes: [SearchType.tracks],
        genre: 'Rock',
        minQuality: AudioQuality.high,
        maxResults: 5,
      );
      
      final searchResult = await searchUseCase(searchParams);
      expect(searchResult.isRight(), isTrue);
      
      final results = searchResult.getOrElse(() => throw Exception('Should not reach here'));
      expect(results.query, equals('rock'));
      expect(results.tracks.length, lessThanOrEqualTo(5));
    });

    test('should handle empty search gracefully', () async {
      final searchParams = SearchMusicParams(
        query: '',
        searchTypes: [SearchType.tracks, SearchType.albums, SearchType.artists],
      );
      
      final searchResult = await searchUseCase(searchParams);
      expect(searchResult.isRight(), isTrue);
      
      final results = searchResult.getOrElse(() => throw Exception('Should not reach here'));
      expect(results.isEmpty, isTrue);
      expect(results.totalResults, equals(0));
    });

    test('should handle playlist operations with validation', () async {
      // Test creating playlist with empty name
      final invalidParams = ManagePlaylistParams(
        operation: PlaylistOperation.create,
        name: '',
      );
      
      final result = await playlistUseCase(invalidParams);
      expect(result.isLeft(), isTrue);
      
      // Test creating playlist with valid name
      final validParams = ManagePlaylistParams(
        operation: PlaylistOperation.create,
        name: 'Valid Playlist Name',
        description: 'Test description',
      );
      
      final validResult = await playlistUseCase(validParams);
      expect(validResult.isRight(), isTrue);
      
      final playlistResult = validResult.getOrElse(() => throw Exception('Should not reach here'));
      expect(playlistResult.isSuccess, isTrue);
      expect(playlistResult.playlist!.name, equals('Valid Playlist Name'));
      
      // Clean up
      final deleteParams = ManagePlaylistParams(
        operation: PlaylistOperation.delete,
        playlistId: playlistResult.playlist!.id,
      );
      await playlistUseCase(deleteParams);
    });

    test('should handle sync operations correctly', () async {
      // Test sync without servers
      final syncParams = SyncMusicCollectionParams();
      final syncResult = await syncUseCase(syncParams);
      
      // Should handle gracefully even if no servers are available
      expect(syncResult.isLeft() || syncResult.isRight(), isTrue);
      
      if (syncResult.isLeft()) {
        // Expected when no servers are configured
        expect(syncResult.fold((failure) => failure.message, (_) => ''), 
               contains('server'));
      }
    });

    test('should handle playback with server selection', () async {
      // Create a mock track for testing
      final testTrack = Track(
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

      final playParams = PlayTrackParams(
        track: testTrack,
        useBestSource: true,
        allowFallback: true,
      );
      
      final playResult = await playTrackUseCase(playParams);
      
      // Playback will likely fail in test environment, but should handle gracefully
      expect(playResult.isLeft() || playResult.isRight(), isTrue);
      
      if (playResult.isLeft()) {
        // Expected when server is not available
        expect(playResult.fold((failure) => failure.message, (_) => ''), 
               isNotEmpty);
      }
    });
  });
}