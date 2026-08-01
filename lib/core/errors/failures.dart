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
  const NetworkFailure(super.message, [super.code]);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

/// Authentication-related failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

/// Audio playback failures
class AudioFailure extends Failure {
  const AudioFailure(super.message, [super.code]);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

/// Data-related failures
class DataFailure extends Failure {
  const DataFailure(super.message, [super.code]);
}

/// Synchronization failures
class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.code]);
}

/// Playback-related failures
class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message, [super.code]);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}
