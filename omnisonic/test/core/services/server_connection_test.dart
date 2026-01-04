import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/server_connection_service.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';

void main() {
  group('Server Connection Service', () {
    late ServerConnectionService connectionService;

    setUp(() {
      connectionService = ServerConnectionService();
    });

    tearDown(() {
      connectionService.dispose();
    });

    test('should validate server configuration', () {
      // Valid server
      final validServer = MusicServer(
        id: 'test-server',
        name: 'Test Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.offline,
        createdAt: DateTime.now(),
      );

      expect(validServer.isValid, isTrue);
      expect(validServer.baseUrl, 'https://demo.subsonic.org');
      expect(validServer.apiUrl, 'https://demo.subsonic.org/rest');

      // Invalid server
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

    test('should handle server status checks', () {
      final onlineServer = MusicServer(
        id: 'online-server',
        name: 'Online Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
      );

      final offlineServer = MusicServer(
        id: 'offline-server',
        name: 'Offline Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.offline,
        createdAt: DateTime.now(),
      );

      final errorServer = MusicServer(
        id: 'error-server',
        name: 'Error Server',
        url: 'https://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.error,
        createdAt: DateTime.now(),
      );

      expect(onlineServer.isAvailable, isTrue);
      expect(offlineServer.isAvailable, isFalse);
      expect(errorServer.hasError, isTrue);
    });

    test('should handle connection monitoring lifecycle', () {
      const serverId = 'test-server';

      // Start monitoring
      connectionService.startConnectionMonitoring(serverId);

      // Stop monitoring
      connectionService.stopConnectionMonitoring(serverId);

      // Should not throw any exceptions
      expect(true, isTrue);
    });

    test('should clear password cache without errors', () {
      // Clear cache should not throw
      connectionService.clearPasswordCache();
      expect(true, isTrue);
    });

    test('should handle server URL validation', () {
      // Test various URL formats
      final validHttps = MusicServer(
        id: 'https-server',
        name: 'HTTPS Server',
        url: 'https://music.example.com',
        username: 'user',
        status: ServerStatus.offline,
        createdAt: DateTime.now(),
      );

      final validHttp = MusicServer(
        id: 'http-server',
        name: 'HTTP Server',
        url: 'http://192.168.1.100:4040',
        username: 'user',
        status: ServerStatus.offline,
        createdAt: DateTime.now(),
      );

      final invalidUrl = MusicServer(
        id: 'invalid-server',
        name: 'Invalid Server',
        url: 'ftp://invalid.com',
        username: 'user',
        status: ServerStatus.error,
        createdAt: DateTime.now(),
      );

      expect(validHttps.isValid, isTrue);
      expect(validHttp.isValid, isTrue);
      expect(invalidUrl.isValid, isFalse);
    });
  });
}