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
}
