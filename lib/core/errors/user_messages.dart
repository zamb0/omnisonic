import 'package:flutter/foundation.dart' show kIsWeb;

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

/// The sentence for a failed connection test, from its raw [message].
///
/// In a browser a request the page may not make — an `http://` server from
/// an HTTPS page, a server without CORS headers, a LAN address from a public
/// site — fails as a bare network error with no detail, which Dio reports as
/// an `XMLHttpRequest` error. On the web that is almost always the cause, so
/// it is named instead of the useless raw text.
String describeConnectionTestError(String? message, {bool isWeb = kIsWeb}) {
  if (isWeb && message != null && _isBrowserNetworkError(message)) {
    return "Couldn't connect to the server: the browser blocked the request. "
        'The web app needs an https:// server that allows cross-origin '
        'requests (CORS) and is reachable from the internet.';
  }
  return "Couldn't connect to the server: "
      '${message ?? 'check the URL and credentials.'}';
}

bool _isBrowserNetworkError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('xmlhttprequest') ||
      lower.startsWith('connection error') ||
      lower.contains('the connection errored');
}
