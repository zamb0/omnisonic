import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';

void main() {
  group('SubsonicApiClient', () {
    late SubsonicApiClient apiClient;
    late MusicServer testServer;

    setUp(() {
      testServer = MusicServer(
        id: 'test-server',
        name: 'Test Server',
        url: 'http://demo.subsonic.org',
        username: 'guest',
        status: ServerStatus.online,
        createdAt: DateTime.now(),
        lastSync: DateTime.now(),
      );
      
      apiClient = SubsonicApiClient();
    });

    test('should generate correct stream URL', () {
      const trackId = 'track123';
      final streamUrl = apiClient.getStreamUrl(testServer, 'guest', trackId);
      
      expect(streamUrl, contains('http://demo.subsonic.org/rest/stream'));
      expect(streamUrl, contains('id=track123'));
      expect(streamUrl, contains('u=guest'));
      expect(streamUrl, contains('v=1.16.1'));
      expect(streamUrl, contains('c=Omnisonic'));
    });

    test('should generate correct cover art URL', () {
      const coverArtId = 'cover123';
      final coverUrl = apiClient.getCoverArtUrl(testServer, 'guest', coverArtId);
      
      expect(coverUrl, contains('http://demo.subsonic.org/rest/getCoverArt'));
      expect(coverUrl, contains('id=cover123'));
      expect(coverUrl, contains('u=guest'));
      expect(coverUrl, contains('v=1.16.1'));
      expect(coverUrl, contains('c=Omnisonic'));
    });

    test('should handle authentication parameters correctly', () {
      const trackId = 'track123';
      final streamUrl = apiClient.getStreamUrl(testServer, 'guest', trackId);
      
      // Should contain either token-based auth (t= and s=) or password-based auth (p=)
      final hasTokenAuth = streamUrl.contains('t=') && streamUrl.contains('s=');
      final hasPasswordAuth = streamUrl.contains('p=');
      
      expect(hasTokenAuth || hasPasswordAuth, isTrue);
    });
  });
}