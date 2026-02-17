import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/errors/failures.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/core/services/source_selection_service.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/usecases/usecases.dart';

/// Simple integration test for core business logic without Flutter dependencies
/// 
/// This test verifies that the core components work together properly
/// and that Checkpoint 10 requirements are met.
void main() {
  group('Core Business Logic - Checkpoint 10 Verification', () {
    test('should verify all core entities can be created', () {
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
      final deduplicationEngine = DeduplicationEngine();
      
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
      expect(duplicateGroups.isNotEmpty, isTrue);
    });

    test('should verify error handling types are working', () {
      // Test Result type functionality
      final successResult = ResultHelper.success('test value');
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isFailure, isFalse);
      expect(successResult.valueOrNull, equals('test value'));

      final failureResult = ResultHelper.failure<String>(UnknownFailure('test error'));
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.isFailure, isTrue);
      expect(failureResult.valueOrNull, isNull);
      expect(failureResult.failureOrNull, isA<UnknownFailure>());
    });

    test('should verify use case parameter classes work correctly', () {
      // Test SyncMusicCollectionParams
      final syncParams = SyncMusicCollectionParams(
        serverId: 'test-server',
        forceRefresh: true,
      );
      expect(syncParams.serverId, equals('test-server'));
      expect(syncParams.forceRefresh, isTrue);

      // Test SearchMusicParams
      final searchParams = SearchMusicParams(
        query: 'test query',
        searchTypes: [SearchType.tracks, SearchType.albums],
        genre: 'Rock',
        year: 2023,
        maxResults: 10,
      );
      expect(searchParams.query, equals('test query'));
      expect(searchParams.searchTypes.length, equals(2));
      expect(searchParams.genre, equals('Rock'));
      expect(searchParams.year, equals(2023));
      expect(searchParams.maxResults, equals(10));

      // Test PlayTrackParams
      final track = Track(
        id: 'test-track',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3),
        serverId: 'test-server',
        streamUrl: 'https://example.com/stream',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final playParams = PlayTrackParams(
        track: track,
        useBestSource: true,
        allowFallback: true,
      );
      expect(playParams.track.id, equals('test-track'));
      expect(playParams.useBestSource, isTrue);
      expect(playParams.allowFallback, isTrue);

      // Test ManagePlaylistParams
      final playlistParams = ManagePlaylistParams(
        operation: PlaylistOperation.create,
        name: 'Test Playlist',
        description: 'A test playlist',
        isPublic: false,
      );
      expect(playlistParams.operation, equals(PlaylistOperation.create));
      expect(playlistParams.name, equals('Test Playlist'));
      expect(playlistParams.description, equals('A test playlist'));
      expect(playlistParams.isPublic, isFalse);
    });

    test('should verify search results functionality', () {
      final track = Track(
        id: 'test-track',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3),
        serverId: 'test-server',
        streamUrl: 'https://example.com/stream',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
      );

      final album = Album(
        id: 'test-album',
        title: 'Test Album',
        artist: 'Test Artist',
        serverId: 'test-server',
        lastModified: DateTime.now(),
        year: 2023,
        trackCount: 10,
        duration: Duration(minutes: 45),
      );

      final artist = Artist(
        id: 'test-artist',
        name: 'Test Artist',
        serverId: 'test-server',
        lastModified: DateTime.now(),
        albumCount: 5,
      );

      // Test SearchResults
      final searchResults = SearchResults(
        query: 'test',
        tracks: [track],
        albums: [album],
        artists: [artist],
        totalResults: 3,
        searchTime: DateTime.now(),
      );

      expect(searchResults.query, equals('test'));
      expect(searchResults.totalResults, equals(3));
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.hasTracks, isTrue);
      expect(searchResults.hasAlbums, isTrue);
      expect(searchResults.hasArtists, isTrue);

      // Test empty SearchResults
      const emptyResults = SearchResults.empty();
      expect(emptyResults.isEmpty, isTrue);
      expect(emptyResults.totalResults, equals(0));
      expect(emptyResults.hasTracks, isFalse);
      expect(emptyResults.hasAlbums, isFalse);
      expect(emptyResults.hasArtists, isFalse);
    });

    test('should verify playlist operation result functionality', () {
      final playlist = Playlist(
        id: 'test-playlist',
        name: 'Test Playlist',
        trackIds: ['track-1', 'track-2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test successful operation result
      const successResult = PlaylistOperationResult.success(
        message: 'Operation successful',
      );
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isFailure, isFalse);
      expect(successResult.message, equals('Operation successful'));

      // Test successful operation result with playlist
      final successWithPlaylist = PlaylistOperationResult.success(
        playlist: playlist,
        message: 'Playlist created successfully',
      );
      expect(successWithPlaylist.isSuccess, isTrue);
      expect(successWithPlaylist.playlist, isNotNull);
      expect(successWithPlaylist.playlist!.id, equals('test-playlist'));

      // Test failure operation result
      const failureResult = PlaylistOperationResult.failure(
        message: 'Operation failed',
      );
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.isFailure, isTrue);
      expect(failureResult.message, equals('Operation failed'));
      expect(failureResult.playlist, isNull);
    });
  });
}