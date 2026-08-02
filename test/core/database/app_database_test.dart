import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:drift/native.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() async {
      // Create in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('should insert and retrieve server', () async {
      final server = MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      // Insert server
      await database.serverDao.insertServer(server, 'password123');

      // Retrieve server
      final retrievedServer = await database.serverDao.getServerById('server1');

      expect(retrievedServer, isNotNull);
      expect(retrievedServer!.id, server.id);
      expect(retrievedServer.name, server.name);
      expect(retrievedServer.url, server.url);
      expect(retrievedServer.username, server.username);
      expect(retrievedServer.status, server.status);
    });

    test('should insert and retrieve track', () async {
      // Tracks reference a server, and foreign keys are enforced.
      await database.serverDao.insertServer(
        MusicServer(
          id: 'server1',
          name: 'Test Server',
          url: 'http://example.com',
          username: 'testuser',
          status: ServerStatus.online,
          createdAt: DateTime.now(),
        ),
        'password123',
      );

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

      // Insert track
      await database.musicDao.insertTrack(track);

      // Retrieve track
      final retrievedTrack = await database.musicDao.getTrackById('track1');

      expect(retrievedTrack, isNotNull);
      expect(retrievedTrack!.id, track.id);
      expect(retrievedTrack.title, track.title);
      expect(retrievedTrack.artist, track.artist);
      expect(retrievedTrack.album, track.album);
      expect(retrievedTrack.serverId, track.serverId);
      expect(retrievedTrack.quality, track.quality);
    });

    test('should handle multiple servers', () async {
      final server1 = MusicServer(
        id: 'server1',
        name: 'Server 1',
        url: 'http://server1.com',
        username: 'user1',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      final server2 = MusicServer(
        id: 'server2',
        name: 'Server 2',
        url: 'http://server2.com',
        username: 'user2',
        status: ServerStatus.offline,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      // Insert servers
      await database.serverDao.insertServer(server1, 'password1');
      await database.serverDao.insertServer(server2, 'password2');

      // Retrieve all servers
      final servers = await database.serverDao.getAllServers();

      expect(servers.length, 2);
      expect(servers.map((s) => s.id), containsAll(['server1', 'server2']));
    });

    test('should update server status', () async {
      final server = MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      // Insert server
      await database.serverDao.insertServer(server, 'password123');

      // Update status
      final updatedServer = server.copyWith(status: ServerStatus.offline);
      await database.serverDao.updateServer(updatedServer);

      // Verify update
      final retrievedServer = await database.serverDao.getServerById('server1');
      expect(retrievedServer!.status, ServerStatus.offline);
    });
  });
}
