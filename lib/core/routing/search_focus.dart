import 'package:flutter/foundation.dart';

/// Asks the Search page to focus its field.
///
/// ⌘K and the desktop top bar's search pill used to only navigate to
/// /search, leaving the user to click into the field — and on /search
/// itself ⌘K did nothing. They now call [request]; the Search page listens
/// while it is mounted, and checks [takePending] when it first builds.
class SearchFocusRequest {
  SearchFocusRequest._();

  static final ValueNotifier<int> requests = ValueNotifier(0);
  static bool _pending = false;

  static void request() {
    _pending = true;
    requests.value++;
  }

  /// Whether a request is waiting, clearing it.
  static bool takePending() {
    final pending = _pending;
    _pending = false;
    return pending;
  }
}
