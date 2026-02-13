import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/utils/password_encryption.dart';

void main() {
  group('PasswordEncryption', () {
    test('should encrypt and decrypt password correctly', () {
      const password = 'test_password_123';
      
      final encrypted = PasswordEncryption.encryptPassword(password);
      final decrypted = PasswordEncryption.decryptPassword(encrypted);
      
      expect(decrypted, equals(password));
      expect(encrypted, isNot(equals(password)));
    });

    test('should handle empty password', () {
      const password = '';
      
      final encrypted = PasswordEncryption.encryptPassword(password);
      final decrypted = PasswordEncryption.decryptPassword(encrypted);
      
      expect(decrypted, equals(password));
      expect(encrypted, equals(''));
    });

    test('should produce different encrypted values for same password', () {
      const password = 'test_password_123';
      
      final encrypted1 = PasswordEncryption.encryptPassword(password);
      final encrypted2 = PasswordEncryption.encryptPassword(password);
      
      // Should be different due to random salt
      expect(encrypted1, isNot(equals(encrypted2)));
      
      // But both should decrypt to same password
      expect(PasswordEncryption.decryptPassword(encrypted1), equals(password));
      expect(PasswordEncryption.decryptPassword(encrypted2), equals(password));
    });

    test('should validate encrypted passwords correctly', () {
      const password = 'test_password_123';
      final encrypted = PasswordEncryption.encryptPassword(password);
      
      expect(PasswordEncryption.validateEncryptedPassword(encrypted), isTrue);
      expect(PasswordEncryption.validateEncryptedPassword(''), isTrue);
      expect(PasswordEncryption.validateEncryptedPassword('invalid'), isFalse);
    });

    test('should pass self test', () {
      expect(PasswordEncryption.testEncryption(), isTrue);
    });

    test('should handle special characters', () {
      const password = 'pässwörd!@#\$%^&*()_+{}|:"<>?[]\\;\',./ 中文';
      
      final encrypted = PasswordEncryption.encryptPassword(password);
      final decrypted = PasswordEncryption.decryptPassword(encrypted);
      
      expect(decrypted, equals(password));
    });

    test('should handle long passwords', () {
      final password = 'a' * 1000; // 1000 character password
      
      final encrypted = PasswordEncryption.encryptPassword(password);
      final decrypted = PasswordEncryption.decryptPassword(encrypted);
      
      expect(decrypted, equals(password));
    });
  });
}