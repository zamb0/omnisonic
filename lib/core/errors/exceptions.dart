/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(String message, [String? code]) : super(message, code);
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException(String message, [String? code]) : super(message, code);
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(String message, [String? code]) : super(message, code);
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(String message, [String? code])
    : super(message, code);
}

/// Subsonic API specific exceptions
class SubsonicApiException extends ServerException {
  const SubsonicApiException(String message, [String? code])
    : super(message, code);
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, [String? code])
    : super(message, code);
}

/// Audio playback exceptions
class AudioException extends AppException {
  const AudioException(String message, [String? code]) : super(message, code);
}

/// Unknown/unexpected exceptions
class UnknownException extends AppException {
  const UnknownException(String message, [String? code]) : super(message, code);
}
