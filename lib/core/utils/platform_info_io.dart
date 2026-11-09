import 'dart:io' as io;

/// Native implementation of [AppPlatform], backed by `dart:io`.
class AppPlatform {
  const AppPlatform._();

  static bool get isIOS => io.Platform.isIOS;
  static bool get isAndroid => io.Platform.isAndroid;
  static bool get isMacOS => io.Platform.isMacOS;
  static bool get isWindows => io.Platform.isWindows;
  static bool get isLinux => io.Platform.isLinux;
  static bool get isWeb => false;

  /// The machine's network name, a sensible default name for a desktop.
  static String? get hostName {
    try {
      final name = io.Platform.localHostname.trim();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }
}
