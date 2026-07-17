import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/entities/album.dart';
import 'package:omnisonic/core/entities/artist.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:drift/native.dart';

void main() {
  group('Core Data Layer Integration', () {
    late AppDatabase database;
    late SubsonicApiClient apiClient;

    setUp(() async {
      // Create in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
      apiClient = SubsonicApiClient();
    });

    tearDown(() async {
      await database.close();
    });

    test('should handle complete server and music data workflow', () async {
      // 1. Create and insert a server
      final server = MusicServer(
        id: 'test-server',
        name: 'Test Music Server',
        url: 'http://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      await database.serverDao.insertServer(server, 'guest');

      // 2. Verify server was inserted
      final retrievedServer = await database.serverDao.getServerById(
        'test-server',
      );
      expect(retrievedServer, isNotNull);
      expect(retrievedServer!.name, 'Test Music Server');

      // 3. Create and insert an artist
      final artist = Artist(
        id: 'artist1',
        name: 'Test Artist',
        serverId: 'test-server',
        lastModified: DateTime.now(),
        albumCount: 2,
      );

      await database.musicDao.insertArtist(artist);

      // 4. Create and insert an album
      final album = Album(
        id: 'album1',
        title: 'Test Album',
        artist: 'Test Artist',
        serverId: 'test-server',
        lastModified: DateTime.now(),
        artistId: 'artist1',
        year: 2023,
        trackCount: 3,
        duration: const Duration(minutes: 12),
      );

      await database.musicDao.insertAlbum(album);

      // 5. Create and insert tracks
      final tracks = [
        Track(
          id: 'track1',
          title: 'Song One',
          artist: 'Test Artist',
          album: 'Test Album',
          duration: const Duration(minutes: 4),
          serverId: 'test-server',
          streamUrl: 'http://demo.subsonic.org/rest/stream?id=track1',
          quality: AudioQuality.high,
          lastModified: DateTime.now(),
          albumId: 'album1',
          artistId: 'artist1',
          trackNumber: 1,
        ),
        Track(
          id: 'track2',
          title: 'Song Two',
          artist: 'Test Artist',
          album: 'Test Album',
          duration: const Duration(minutes: 4),
          serverId: 'test-server',
          streamUrl: 'http://demo.subsonic.org/rest/stream?id=track2',
          quality: AudioQuality.medium,
          lastModified: DateTime.now(),
          albumId: 'album1',
          artistId: 'artist1',
          trackNumber: 2,
        ),
      ];

      for (final track in tracks) {
        await database.musicDao.insertTrack(track);
      }

      // 6. Verify all data was inserted correctly
      final allServers = await database.serverDao.getAllServers();
      expect(allServers.length, 1);

      final allArtists = await database.musicDao.getAllArtists();
      expect(allArtists.length, 1);
      expect(allArtists.first.name, 'Test Artist');

      final allAlbums = await database.musicDao.getAllAlbums();
      expect(allAlbums.length, 1);
      expect(allAlbums.first.title, 'Test Album');

      final allTracks = await database.musicDao.getAllTracks();
      expect(allTracks.length, 2);
      expect(
        allTracks.map((t) => t.title),
        containsAll(['Song One', 'Song Two']),
      );

      // 7. Test API client URL generation
      final streamUrl = apiClient.getStreamUrl(server, 'guest', 'track1');
      expect(streamUrl, contains('http://demo.subsonic.org/rest/stream'));
      expect(streamUrl, contains('id=track1'));

      // 8. Test server status update
      final updatedServer = server.copyWith(status: ServerStatus.syncing);
      await database.serverDao.updateServer(updatedServer);

      final finalServer = await database.serverDao.getServerById('test-server');
      expect(finalServer!.status, ServerStatus.syncing);
    });

    test('should handle server connection validation', () async {
      final server = MusicServer(
        id: 'valid-server',
        name: 'Valid Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
      );

      // Test server validation
      expect(server.isValid, isTrue);
      expect(server.baseUrl, 'https://demo.subsonic.org');
      expect(server.apiUrl, 'https://demo.subsonic.org/rest');

      // Test invalid server
      final invalidServer = MusicServer(
        id: 'invalid-server',
        name: 'Invalid Server',
        url: 'not-a-url',
        username: 'guest',
        status: ServerStatus.error,
        createdAt: DateTime.now(),
      );

      expect(invalidServer.isValid, isFalse);
    });

    test('should handle music metadata relationships', () async {
      // Create related entities
      final artist = Artist(
        id: 'artist1',
        name: 'Test Artist',
        serverId: 'server1',
        lastModified: DateTime.now(),
        albumCount: 1,
      );

      final album = Album(
        id: 'album1',
        title: 'Test Album',
        artist: 'Test Artist',
        serverId: 'server1',
        lastModified: DateTime.now(),
        artistId: 'artist1',
        trackCount: 2,
        duration: const Duration(minutes: 8),
      );

      final track = Track(
        id: 'track1',
        title: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 4),
        serverId: 'server1',
        streamUrl: 'http://example.com/stream/track1',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
        albumId: 'album1',
        artistId: 'artist1',
      );

      // Insert all entities
      await database.musicDao.insertArtist(artist);
      await database.musicDao.insertAlbum(album);
      await database.musicDao.insertTrack(track);

      // Verify relationships
      final retrievedTrack = await database.musicDao.getTrackById('track1');
      expect(retrievedTrack!.artistId, 'artist1');
      expect(retrievedTrack.albumId, 'album1');

      final retrievedAlbum = await database.musicDao.getAlbumById('album1');
      expect(retrievedAlbum!.artistId, 'artist1');

      final retrievedArtist = await database.musicDao.getArtistById('artist1');
      expect(retrievedArtist!.name, 'Test Artist');
    });
  });
}
