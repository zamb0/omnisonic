/// Web-safe platform detection.
///
/// `dart:io` cannot be imported in a web build at all - the import itself is a
/// compile error, so `kIsWeb` guards are not enough. Anything that only needs
/// to know *which* platform it is running on should import this barrel instead
/// of `dart:io`; the web variant reports `false` for every native platform.
///
/// Code that needs `File`/`Directory` still has to use `dart:io` directly and
/// therefore cannot be part of a web build.
library;

export 'platform_info_web.dart' if (dart.library.io) 'platform_info_io.dart';
