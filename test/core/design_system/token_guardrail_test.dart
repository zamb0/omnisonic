import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #61: font sizes, weights and colours belong to the design system.
///
/// The audit found 49 literal `fontSize:` values (9.5 to 52), 13 hard-coded
/// `Colors.*` and literal weights across the feature code, each a small
/// divergence from the tokens. This keeps the debt from coming back: any of
/// them outside `lib/core/design_system/` fails here, with the line.
///
/// Add a token to the design system instead. `Colors.transparent` is fine —
/// it is not a colour choice.
void main() {
  final rules = <String, RegExp>{
    'a literal fontSize (use an OmnisonicTypography token)': RegExp(
      r'fontSize:\s*[0-9]',
    ),
    'a Colors.* colour (use OmnisonicColors or the ColorScheme)': RegExp(
      r'(?<![A-Za-z_])Colors\.(?!transparent\b)[a-z]\w*',
    ),
    'a Color(0x…) literal (use OmnisonicColors)': RegExp(r'\bColor\(0x'),
    'a literal FontWeight (use OmnisonicTypography.<weight>)': RegExp(
      r'\bFontWeight\.(w[1-9]00|bold|normal)\b',
    ),
  };

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.contains('/core/design_system/'))
      .toList();

  // Animation lengths (milliseconds) belong to AnimationManager. Only UI code
  // is scanned; display times in seconds (snackbar) are not motion. Logic like
  // debounce, polling and position maths in view models and data sources is
  // not motion either.
  final uiFiles = files.where((f) => f.path.contains('/presentation/'));
  test('no literal animation Duration in UI code (use AnimationManager)', () {
    final pattern = RegExp(r'\bDuration\(\s*milliseconds:\s*[0-9]');
    final hits = <String>[];
    for (final file in uiFiles.where(
      (f) =>
          !f.path.contains('/viewmodels/') &&
          !f.path.contains('/bloc/') &&
          !f.path.contains('/datasources/'),
    )) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i].split('//').first)) {
          hits.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason: 'Found literal Durations:\n${hits.join('\n')}',
    );
  });

  // Aurora is the signature: at most one filled Aurora button per page, or
  // none of them is the main action any more.
  test('at most one AuroraButton per page (docs/design-system.md §1)', () {
    final hits = <String>[];
    for (final file in files.where((f) => f.path.contains('/pages/'))) {
      final count = RegExp(
        r'\bAuroraButton\(',
      ).allMatches(file.readAsStringSync()).length;
      if (count > 1) hits.add('${file.path}: $count');
    }
    expect(
      hits,
      isEmpty,
      reason: 'More than one AuroraButton:\n${hits.join('\n')}',
    );
  });

  for (final MapEntry(key: what, value: pattern) in rules.entries) {
    test('no $what outside the design system', () {
      final hits = <String>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final code = line.split('//').first;
          if (pattern.hasMatch(code)) {
            hits.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(hits, isEmpty, reason: 'Found $what:\n${hits.join('\n')}');
    });
  }
}
