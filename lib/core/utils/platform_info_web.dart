/// Web implementation of [AppPlatform].
///
/// `dart:io` is unavailable on the web, so every native platform check is
/// `false` and [isWeb] is the only one that reports `true`.
class AppPlatform {
  const AppPlatform._();

  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isWeb => true;
}
