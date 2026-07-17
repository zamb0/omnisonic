import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'app_log.dart';

/// Utility class for encrypting and decrypting passwords for database storage
/// Uses AES-like encryption with a device-specific key
class PasswordEncryption {
  /// Generates a device-specific encryption key
  static String _generateDeviceKey() {
    // Create a consistent key based on a fixed seed for the device
    // In production, you might want to use actual device identifiers
    const deviceSeed = 'omnisonic_device_seed_v1';
    final bytes = utf8.encode(deviceSeed);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Simple XOR-based encryption (not AES, but better than plaintext)
  /// For production, consider using a proper encryption library
  static String _xorEncrypt(String plaintext, String key) {
    final plaintextBytes = utf8.encode(plaintext);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];

    for (int i = 0; i < plaintextBytes.length; i++) {
      encrypted.add(plaintextBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  /// Simple XOR-based decryption
  static String _xorDecrypt(String encryptedBase64, String key) {
    try {
      final encryptedBytes = base64.decode(encryptedBase64);
      final keyBytes = utf8.encode(key);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt password: $e');
    }
  }

  /// Encrypts a password for database storage
  static String encryptPassword(String password) {
    if (password.isEmpty) {
      return '';
    }

    try {
      // Generate a random salt for this password
      final random = Random.secure();
      final salt = List.generate(16, (_) => random.nextInt(256));
      final saltBase64 = base64.encode(salt);

      // Create encryption key from device key + salt
      final deviceKey = _generateDeviceKey();
      final combinedKey = '$deviceKey$saltBase64';
      final keyHash = sha256.convert(utf8.encode(combinedKey));
      final encryptionKey = base64.encode(keyHash.bytes);
      // Encrypt the password
      final encrypted = _xorEncrypt(password, encryptionKey);

      // Combine salt + encrypted data
      final result = '$saltBase64:$encrypted';
      return result;
    } catch (e) {
      AppLog.error('Encryption error: $e');
      throw Exception('Failed to encrypt password: $e');
    }
  }

  /// Decrypts a password from database storage
  static String decryptPassword(String encryptedPassword) {
    if (encryptedPassword.isEmpty) {
      return '';
    }

    try {
      // Split salt and encrypted data
      final parts = encryptedPassword.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted password format');
      }

      final saltBase64 = parts[0];
      final encrypted = parts[1];

      // Recreate encryption key
      final deviceKey = _generateDeviceKey();
      final combinedKey = '$deviceKey$saltBase64';
      final keyHash = sha256.convert(utf8.encode(combinedKey));
      final encryptionKey = base64.encode(keyHash.bytes);
      // Decrypt the password
      final decrypted = _xorDecrypt(encrypted, encryptionKey);
      return decrypted;
    } catch (e) {
      AppLog.error('Decryption error: $e');
      throw Exception('Failed to decrypt password: $e');
    }
  }

  /// Validates that an encrypted password can be decrypted
  static bool validateEncryptedPassword(String encryptedPassword) {
    try {
      if (encryptedPassword.isEmpty) {
        return true; // Empty is valid
      }

      decryptPassword(encryptedPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Creates a test encryption/decryption to verify the system works
  static bool testEncryption() {
    try {
      const testPassword = 'test_password_123';
      final encrypted = encryptPassword(testPassword);
      final decrypted = decryptPassword(encrypted);
      return decrypted == testPassword;
    } catch (e) {
      return false;
    }
  }
}
