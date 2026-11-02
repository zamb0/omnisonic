import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Base use case class for all business logic operations
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Use case for operations that don't require parameters
abstract class NoParamsUseCase<T> {
  Future<Either<Failure, T>> call();
}

/// Use case for operations that return streams
abstract class StreamUseCase<T, P> {
  Stream<Either<Failure, T>> call(P params);
}

/// Base class for use case parameters
abstract class Params extends Equatable {
  const Params();
}

/// Empty parameters for use cases that don't need input
class NoParams extends Params {
  const NoParams();

  @override
  List<Object?> get props => [];
}
