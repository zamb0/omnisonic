import 'failures.dart';

/// Turns a [Failure] into a sentence for the UI.
///
/// Raw `failure.message` and `'$e'` strings — exception class names, HTTP
/// codes, SQL — used to be shown as they were. [action] completes "Couldn't
/// …", e.g. `'create the playlist'`. The technical detail belongs in
/// `AppLog`, not here.
String describeFailure(Failure failure, {required String action}) {
  final reason = switch (failure) {
    NetworkFailure() => 'check your connection and try again.',
    ServerFailure() => 'the server didn\'t respond. Try again in a moment.',
    AuthenticationFailure() =>
      'the server rejected the sign-in. Check the '
          'username and password.',
    DatabaseFailure() || CacheFailure() =>
      'local storage had a problem. '
          'Try again.',
    // Validation messages are written for people already.
    ValidationFailure() => failure.message,
    _ => 'something went wrong. Try again.',
  };
  return "Couldn't $action: $reason";
}

/// The same for an unexpected exception, whose text is never shown.
String describeUnexpected({required String action}) =>
    "Couldn't $action. Something went wrong — try again.";
