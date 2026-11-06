import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/utils/server_validator.dart';

void main() {
  group('ServerValidator.normalizeUrl', () {
    test('adds https:// to a bare host', () {
      expect(
        ServerValidator.normalizeUrl('music.example.com'),
        'https://music.example.com',
      );
    });

    test('keeps an explicit scheme and port', () {
      expect(
        ServerValidator.normalizeUrl('http://192.168.1.4:4533'),
        'http://192.168.1.4:4533',
      );
    });

    test('drops trailing slashes and the /rest API path', () {
      expect(
        ServerValidator.normalizeUrl(' https://music.example.com/rest/ '),
        'https://music.example.com',
      );
      expect(
        ServerValidator.normalizeUrl('https://music.example.com//'),
        'https://music.example.com',
      );
    });

    test('a normalized bare host passes validation', () {
      final url = ServerValidator.normalizeUrl('music.example.com/rest');
      expect(ServerValidator.validateUrl(url).isRight(), isTrue);
    });
  });

  group('ServerValidator.webUrlWarning', () {
    test('warns about http://', () {
      expect(
        ServerValidator.webUrlWarning('http://music.example.com'),
        contains('https://'),
      );
    });

    test('warns about private and loopback hosts', () {
      for (final url in [
        'https://192.168.1.4:4533',
        'https://10.0.0.2',
        'https://172.20.1.1',
        'https://127.0.0.1',
        'https://localhost:4533',
        'https://nas.local',
        'https://[fd00::1]',
      ]) {
        expect(ServerValidator.webUrlWarning(url), isNotNull, reason: url);
      }
    });

    test('accepts public https hosts', () {
      for (final url in [
        'https://music.example.com',
        'https://172.32.0.1',
        'https://8.8.8.8',
      ]) {
        expect(ServerValidator.webUrlWarning(url), isNull, reason: url);
      }
    });
  });
}
