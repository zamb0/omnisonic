import 'package:equatable/equatable.dart';

/// Base failure class for error handling in the domain layer
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  
  const Failure(this.message, [this.code]);
  
  @override
  List<Object?> get props => [message, code];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, [String? code]) : super(message, code);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(String message, [String? code]) : super(message, code);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(String message, [String? code]) : super(message, code);
}

/// Authentication-related failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message, [String? code]) : super(message, code);
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message, [String? code]) : super(message, code);
}

/// Audio playback failures
class AudioFailure extends Failure {
  const AudioFailure(String message, [String? code]) : super(message, code);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? code]) : super(message, code);
}

/// Data-related failures
class DataFailure extends Failure {
  const DataFailure(String message, [String? code]) : super(message, code);
}

/// Synchronization failures
class SyncFailure extends Failure {
  const SyncFailure(String message, [String? code]) : super(message, code);
}

/// Playback-related failures
class PlaybackFailure extends Failure {
  const PlaybackFailure(String message, [String? code]) : super(message, code);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure(String message, [String? code]) : super(message, code);
}