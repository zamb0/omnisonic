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
  const NetworkException(super.message, [super.code]);
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException(super.message, [super.code]);
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(super.message, [super.code]);
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

/// Subsonic API specific exceptions
class SubsonicApiException extends ServerException {
  const SubsonicApiException(super.message, [super.code]);
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);
}

/// Audio playback exceptions
class AudioException extends AppException {
  const AudioException(super.message, [super.code]);
}

/// Unknown/unexpected exceptions
class UnknownException extends AppException {
  const UnknownException(super.message, [super.code]);
}
