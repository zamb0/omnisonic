import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// docs/design-system.md and `lib/` must say the same thing: a token named in
/// the document exists in code, and the tokens that exist only because of
/// the document are in it.
///
/// Not every legacy alias in code is in the doc (that is fine: the doc is
/// the vocabulary to *use*), but nothing the doc tells you to use may be
/// missing, and nothing new in the brand/surface/motion/elevation vocabulary
/// may go undocumented.
void main() {
  final doc = File('docs/design-system.md').readAsStringSync();
  final lib = [
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart')) f.readAsStringSync(),
  ].join('\n');

  String source(String path) =>
      File('lib/core/design_system/$path').readAsStringSync();

  /// Backticked tokens in column [column] of the table rows under heading
  /// [heading] (up to the next `## `).
  List<String> tableTokens(String heading, {int column = 1}) {
    final start = doc.indexOf(heading);
    expect(start, isNonNegative, reason: 'heading "$heading" is in the doc');
    final next = doc.indexOf('\n## ', start + heading.length);
    final section = doc.substring(start, next < 0 ? doc.length : next);
    final tokens = <String>[];
    for (final line in section.split('\n')) {
      if (!line.startsWith('|') || line.startsWith('|---')) continue;
      final cells = line.split('|').map((c) => c.trim()).toList();
      if (cells.length <= column + 1) continue;
      tokens.addAll(
        RegExp(
          r'`([^`]+)`',
        ).allMatches(cells[column + 1]).map((m) => m.group(1)!),
      );
    }
    return tokens;
  }

  group('doc -> code', () {
    test('classes the doc names exist', () {
      const flutterOwn = {
        'CircularProgressIndicator',
        'FilledButton',
        'Hero',
        'MediaQuery',
        'Semantics',
        'ThemeExtension',
      };
      final named = RegExp(
        r'`([A-Z][A-Za-z0-9]+)`',
      ).allMatches(doc).map((m) => m.group(1)!).toSet().difference(flutterOwn);
      final missing = [
        for (final name in named)
          if (!RegExp('(class|enum|mixin|extension) $name\\b').hasMatch(lib))
            name,
      ];
      expect(missing, isEmpty, reason: 'documented but not defined: $missing');
    });

    test('Class.member tokens exist', () {
      final tokens = RegExp(
        r'`(Omnisonic[A-Za-z]+|AnimationUtils)\.([a-zA-Z]+)(\(\))?`',
      ).allMatches(doc).map((m) => (m.group(1)!, m.group(2)!)).toSet();
      final missing = [
        for (final (cls, member) in tokens)
          if (!RegExp('(static|get|final)[^;{=]*\\b$member\\b').hasMatch(lib) &&
              !RegExp('static [^;]*\\b$member\\b').hasMatch(lib))
            '$cls.$member',
      ];
      expect(missing, isEmpty, reason: 'documented but not defined: $missing');
    });

    test('surfaces.* tokens are fields of OmnisonicSurfaces', () {
      final surfaces = source('surfaces.dart');
      final names = RegExp(
        r'`surfaces\.(?!dart\b)([a-zA-Z]+)`',
      ).allMatches(doc).map((m) => m.group(1)!).toSet();
      expect(names, isNotEmpty);
      for (final name in names) {
        expect(
          surfaces,
          contains('final Color $name'),
          reason: 'surfaces.$name',
        );
      }
    });

    test('typography tokens in §3 exist', () {
      final typography = source('typography.dart');
      final tokens = tableTokens(
        '## 3. Tipografia',
      ).where((t) => RegExp(r'^[a-z][A-Za-z]+$').hasMatch(t));
      expect(tokens, isNotEmpty);
      for (final token in tokens) {
        expect(typography, contains('TextStyle get $token'), reason: token);
      }
    });

    test('spacing tokens in §4 exist', () {
      final spacing = source('spacing.dart');
      for (final token in tableTokens('## 4. Spaziatura')) {
        expect(
          spacing,
          contains('static const double $token ='),
          reason: token,
        );
      }
    });

    test('radius tokens in §5 exist', () {
      final spacing = source('spacing.dart');
      for (final token in tableTokens('## 5. Raggi').where((t) => t != '∞')) {
        expect(
          spacing,
          contains('static const double $token ='),
          reason: token,
        );
      }
    });

    test('durations and curves in §7 exist', () {
      final motion = source('animation_manager.dart');
      for (final d in [
        'instant',
        'fast',
        'quick',
        'normal',
        'emphasis',
        'tint',
      ]) {
        expect(doc, contains('`$d`'), reason: '$d in the doc');
        expect(
          motion,
          contains('static const Duration ${d}Duration'),
          reason: d,
        );
      }
      for (final c in ['standard', 'enter', 'exit', 'spring']) {
        expect(doc, contains(c), reason: '$c in the doc');
        expect(motion, contains('Curve ${c}Curve'), reason: c);
      }
    });

    test('OmnisonicBrand fields named in §2.4 exist', () {
      final brand = source('brand.dart');
      for (final field in [
        'aurora',
        'auroraSoft',
        'auroraMesh',
        'onAurora',
        'heat',
        'glow',
      ]) {
        expect(doc, contains('`$field`'), reason: '$field in the doc');
        expect(brand, contains(' $field;'), reason: field);
      }
    });
  });

  group('code -> doc', () {
    test('every OmnisonicBrand field is documented', () {
      final fields = RegExp(
        r'final [A-Za-z<>]+ (\w+);',
      ).allMatches(source('brand.dart')).map((m) => m.group(1)!);
      for (final f in fields) {
        expect(doc, contains('`$f`'), reason: 'brand.$f');
      }
    });

    test('every OmnisonicSurfaces field is documented', () {
      final fields = RegExp(
        r'final Color (\w+);',
      ).allMatches(source('surfaces.dart')).map((m) => m.group(1)!);
      for (final f in fields) {
        expect(
          doc.contains('`$f`') || doc.contains('`surfaces.$f`'),
          isTrue,
          reason: 'surfaces.$f',
        );
      }
    });

    test('every OmnisonicShadows token is documented', () {
      final body = source('spacing.dart');
      final shadows = body.substring(
        body.indexOf('class OmnisonicShadows'),
        body.indexOf('class OmnisonicElevation'),
      );
      final names = RegExp(
        r'static (?:const )?(?:List<BoxShadow>(?: get)? |List<BoxShadow> )(\w+)',
      ).allMatches(shadows).map((m) => m.group(1)!);
      expect(names, isNotEmpty);
      for (final n in names) {
        expect(doc, contains('OmnisonicShadows.$n'), reason: n);
      }
    });

    test('every motion duration and curve is documented', () {
      final motion = source('animation_manager.dart');
      final names = RegExp(
        r'static const (?:Duration|Curve) (\w+?)(?:Duration|Curve) =',
      ).allMatches(motion).map((m) => m.group(1)!).toSet();
      // `loading`, `slow`, `fast` curve aliases etc. are internal; the ladder
      // in §7 is what to use.
      for (final n in [
        'instant',
        'fast',
        'quick',
        'normal',
        'emphasis',
        'tint',
        'standard',
        'enter',
        'exit',
        'spring',
      ]) {
        expect(names, contains(n));
        expect(doc, contains(n));
      }
    });

    test('the v2 components are documented', () {
      for (final component in [
        'AuroraButton',
        'PlayDisc',
        'OmnisonicButton',
        'OmnisonicIconButton',
        'OmnisonicSegmented',
        'AuroraProgress',
        'AuroraProgressLine',
        'AuroraMesh',
        'AuroraRing',
        'FocusDecoration',
        'PressScale',
        'Staggered',
        'EntranceScope',
        'NowPlayingEqualizer',
        'QualityBadge',
        'ComponentGalleryPage',
        'GrowingThumbShape',
        'HeaderCollapseMixin',
        'ServerHealth',
      ]) {
        expect(
          doc,
          contains('`$component`'),
          reason: '$component is not in the doc',
        );
      }
    });
  });

  test('the doc no longer calls itself a target', () {
    expect(doc, isNot(contains('sistema **target**')));
    expect(doc, isNot(contains('Migrazione v1 → v2')));
  });
}
