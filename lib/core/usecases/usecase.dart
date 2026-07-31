import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Base use case class for all business logic operations
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case for operations that don't require parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Use case for operations that return streams
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
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
