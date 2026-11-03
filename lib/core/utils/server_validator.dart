import '../entities/music_server.dart';
import '../errors/result.dart';
import '../errors/failures.dart';

/// Utility class for validating server configurations
class ServerValidator {
  /// Turns what people type into the base URL the app needs.
  ///
  /// `music.example.com` was rejected for having no scheme; now it gets
  /// `https://`. A trailing slash and a trailing `/rest` — the Subsonic API
  /// path, which the client adds itself — are dropped.
  static String normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(url)) {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.toLowerCase().endsWith('/rest')) {
      url = url.substring(0, url.length - '/rest'.length);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Validates a server configuration
  static Result<void> validateServerConfig(MusicServer server) {
    // Check required fields
    if (server.id.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('Server ID cannot be empty'),
      );
    }

    if (server.name.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('Server name cannot be empty'),
      );
    }

    if (server.username.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('Username cannot be empty'),
      );
    }

    // Validate URL format
    final urlValidation = validateUrl(server.url);
    if (urlValidation.isFailure) {
      return urlValidation;
    }

    return ResultHelper.success(null);
  }

  /// Validates URL format and scheme
  static Result<void> validateUrl(String url) {
    if (url.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('Server URL cannot be empty'),
      );
    }

    try {
      final uri = Uri.parse(url);

      if (!uri.hasScheme) {
        return ResultHelper.failure(
          ValidationFailure('URL must include protocol (http:// or https://)'),
        );
      }

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return ResultHelper.failure(
          ValidationFailure('URL must use http:// or https:// protocol'),
        );
      }

      if (uri.host.isEmpty) {
        return ResultHelper.failure(
          ValidationFailure('URL must include a valid hostname'),
        );
      }

      // Check for common URL issues
      if (uri.path.isNotEmpty && uri.path != '/') {
        return ResultHelper.failure(
          ValidationFailure(
            'URL should not include a path (e.g., use http://server.com not http://server.com/subsonic)',
          ),
        );
      }

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(ValidationFailure('Invalid URL format: $e'));
    }
  }

  /// Validates username format
  static Result<void> validateUsername(String username) {
    if (username.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('Username cannot be empty'),
      );
    }

    if (username.length < 2) {
      return ResultHelper.failure(
        ValidationFailure('Username must be at least 2 characters long'),
      );
    }

    // Check for invalid characters
    if (username.contains(' ')) {
      return ResultHelper.failure(
        ValidationFailure('Username cannot contain spaces'),
      );
    }

    return ResultHelper.success(null);
  }

  /// Validates password strength (basic validation)
  static Result<void> validatePassword(String password) {
    if (password.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('Password cannot be empty'),
      );
    }

    if (password.length < 3) {
      return ResultHelper.failure(
        ValidationFailure('Password must be at least 3 characters long'),
      );
    }

    return ResultHelper.success(null);
  }
}
