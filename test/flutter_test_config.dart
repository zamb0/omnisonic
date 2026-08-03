import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs once before every test file in this package.
///
/// `flutter test` renders all text with a placeholder font unless the real
/// typefaces are registered explicitly — even though they are bundled in
/// `pubspec.yaml`. Without this, goldens lock in fake metrics and any test
/// that measures text is meaningless. Registering here rather than in a
/// `setUpAll` keeps it out of every individual test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();
  await testMain();
}

/// Family name -> bundled asset paths. Must stay in sync with the `fonts:`
/// section of `pubspec.yaml`.
const _fontAssets = <String, List<String>>{
  'Manrope': [
    'assets/fonts/Manrope-400.ttf',
    'assets/fonts/Manrope-500.ttf',
    'assets/fonts/Manrope-600.ttf',
    'assets/fonts/Manrope-700.ttf',
  ],
  'Gabarito': [
    'assets/fonts/Gabarito-500.ttf',
    'assets/fonts/Gabarito-600.ttf',
    'assets/fonts/Gabarito-700.ttf',
    'assets/fonts/Gabarito-800.ttf',
  ],
  'JetBrains Mono': [
    'assets/fonts/JetBrainsMono-400.ttf',
    'assets/fonts/JetBrainsMono-500.ttf',
    'assets/fonts/JetBrainsMono-600.ttf',
  ],
};

Future<void> _loadAppFonts() async {
  for (final entry in _fontAssets.entries) {
    final loader = FontLoader(entry.key);
    for (final asset in entry.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
