import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs once before every test file in this package.
///
/// `flutter test` renders all text with a placeholder font unless the real
/// typefaces are registered explicitly — including MaterialIcons, which is
/// why untouched goldens show icons as empty boxes. Without this, goldens
/// lock in fake metrics and any test that measures text is meaningless.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();
  await testMain();
}

/// Registers every font in the build's `FontManifest.json`.
///
/// Reading the manifest rather than a hard-coded list means the bundled
/// families in `pubspec.yaml` and the framework's own MaterialIcons are both
/// covered, and adding a weight to the pubspec needs no change here.
Future<void> _loadAppFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    // Fonts the engine ships are listed with a "packages/" prefix; the
    // family name has to keep that prefix or lookups miss.
    final loader = FontLoader(family);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
