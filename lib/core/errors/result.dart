import 'package:dartz/dartz.dart';
import 'failures.dart';

/// A Result type that wraps Either for better ergonomics
/// Success case contains the value, failure case contains a Failure
typedef Result<T> = Either<Failure, T>;

/// Extension methods for Result to make it easier to work with
extension ResultExtensions<T> on Result<T> {
  /// Returns true if this is a success result
  bool get isSuccess => isRight();
  
  /// Returns true if this is a failure result
  bool get isFailure => isLeft();
  
  /// Gets the success value or null if this is a failure
  T? get valueOrNull => fold((_) => null, (value) => value);
  
  /// Gets the failure or null if this is a success
  Failure? get failureOrNull => fold((failure) => failure, (_) => null);
  
  /// Maps the success value to a new type
  Result<U> mapValue<U>(U Function(T) mapper) {
    return map(mapper);
  }
  
  /// Maps the failure to a new failure
  Result<T> mapFailure(Failure Function(Failure) mapper) {
    return leftMap(mapper);
  }
  
  /// Executes a function if this is a success, returns the original result
  Result<T> onSuccess(void Function(T) action) {
    return fold(
      (failure) => Left(failure),
      (value) {
        action(value);
        return Right(value);
      },
    );
  }
  
  /// Executes a function if this is a failure, returns the original result
  Result<T> onFailure(void Function(Failure) action) {
    return fold(
      (failure) {
        action(failure);
        return Left(failure);
      },
      (value) => Right(value),
    );
  }
}

/// Helper methods for creating Result instances
class ResultHelper {
  /// Creates a success result
  static Result<T> success<T>(T value) => Right(value);
  
  /// Creates a failure result
  static Result<T> failure<T>(Failure failure) => Left(failure);
  
  /// Creates a result from a nullable value
  static Result<T> fromNullable<T>(T? value, Failure failure) {
    return value != null ? success(value) : ResultHelper.failure(failure);
  }
  
  /// Executes an async operation and catches exceptions, converting them to failures
  static Future<Result<T>> guard<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return success(result);
    } catch (e) {
      return failure(UnknownFailure(e.toString()));
    }
  }
  
  /// Executes a sync operation and catches exceptions, converting them to failures
  static Result<T> guardSync<T>(T Function() operation) {
    try {
      final result = operation();
      return success(result);
    } catch (e) {
      return failure(UnknownFailure(e.toString()));
    }
  }
}