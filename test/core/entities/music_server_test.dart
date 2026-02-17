import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';

void main() {
  group('MusicServer Entity', () {
    test('should create server with required fields', () {
      final server = MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );

      expect(server.id, 'server1');
      expect(server.name, 'Test Server');
      expect(server.url, 'http://example.com');
      expect(server.username, 'testuser');
      expect(server.status, ServerStatus.online);
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final server1 = MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: now,
        lastSync: now,
      );

      final server2 = MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: now,
        lastSync: now,
      );

      expect(server1, equals(server2));
      expect(server1.hashCode, equals(server2.hashCode));
    });

    test('should have different hash codes for different servers', () {
      final now = DateTime.now();
      final server1 = MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: now,
        lastSync: now,
      );

      final server2 = MusicServer(
        id: 'server2',
        name: 'Different Server',
        url: 'http://different.com',
        username: 'testuser',
        status: ServerStatus.online,
        createdAt: now,
        lastSync: now,
      );

      expect(server1, isNot(equals(server2)));
      expect(server1.hashCode, isNot(equals(server2.hashCode)));
    });
  });
}