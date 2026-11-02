import 'dart:async';

/// Runs the most recent action after a quiet period.
///
/// Used for text fields that filter a list on every keystroke: without it,
/// typing an eight-character query re-filters the collection eight times.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 250)});

  final Duration duration;
  Timer? _timer;

  /// Schedules [action], cancelling anything scheduled but not yet run.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels a pending action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
