import 'package:flutter/foundation.dart';

/// Centralized logging utility with basic release filtering.
class AppLog {
  static void debug(String message, {bool sensitive = false}) {
    if (sensitive) return;
    if (!kReleaseMode) {
      debugPrint('DEBUG: $message');
    }
  }

  static void info(String message, {bool sensitive = false}) {
    _log('INFO', message, sensitive: sensitive);
  }

  static void warn(String message, {bool sensitive = false}) {
    _log('WARN', message, sensitive: sensitive);
  }

  static void error(String message, {bool sensitive = false}) {
    _log('ERROR', message, sensitive: sensitive);
  }

  static void _log(String level, String message, {required bool sensitive}) {
    if (sensitive) return;
    debugPrint('$level: $message');
  }
}
