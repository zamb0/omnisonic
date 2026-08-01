import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/typography.dart';

void main() {
  // OmnisonicTypography's getters build a GoogleFonts style, which kicks
  // off a background asset/network lookup the first time each family is
  // used. Outside a widget tree that lookup's rejection surfaces as a
  // stray uncaught error; pumping a trivial widget first routes it through
  // Flutter's normal error handling instead.
  Future<void> primeGoogleFonts(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(home: Builder(builder: (context) => const Text('x'))),
  );

  group('Typography Scale Tests', () {
    testWidgets('Typography scale has consistent font families', (
      tester,
    ) async {
      await primeGoogleFonts(tester);

      // google_fonts suffixes the family with the resolved weight (e.g.
      // "Poppins_700"), so match the base name rather than an exact string.
      expect(
        OmnisonicTypography.displayLarge.fontFamily,
        startsWith(OmnisonicTypography.displayFont),
      );
      expect(
        OmnisonicTypography.headlineLarge.fontFamily,
        startsWith(OmnisonicTypography.displayFont),
      );
      expect(
        OmnisonicTypography.titleLarge.fontFamily,
        startsWith(OmnisonicTypography.primaryFont),
      );
      expect(
        OmnisonicTypography.bodyLarge.fontFamily,
        startsWith(OmnisonicTypography.primaryFont),
      );
    });

    testWidgets('Typography scale has proper font sizes', (tester) async {
      await primeGoogleFonts(tester);

      expect(OmnisonicTypography.displayLarge.fontSize, equals(57));
      expect(OmnisonicTypography.displayMedium.fontSize, equals(45));
      expect(OmnisonicTypography.headlineLarge.fontSize, equals(32));
      expect(OmnisonicTypography.titleLarge.fontSize, equals(22));
      expect(OmnisonicTypography.bodyLarge.fontSize, equals(16));
    });

    testWidgets('Music-specific typography has correct properties', (
      tester,
    ) async {
      await primeGoogleFonts(tester);

      expect(
        OmnisonicTypography.trackTitle.fontFamily,
        startsWith(OmnisonicTypography.primaryFont),
      );
      expect(OmnisonicTypography.trackTitle.fontSize, equals(16));
      expect(
        OmnisonicTypography.trackTitle.fontWeight,
        equals(FontWeight.w500),
      );

      expect(
        OmnisonicTypography.artistName.fontFamily,
        startsWith(OmnisonicTypography.primaryFont),
      );
      expect(OmnisonicTypography.artistName.fontSize, equals(14));

      expect(
        OmnisonicTypography.albumTitle.fontFamily,
        startsWith(OmnisonicTypography.primaryFont),
      );
      expect(OmnisonicTypography.albumTitle.fontSize, equals(14));
      expect(
        OmnisonicTypography.albumTitle.fontWeight,
        equals(FontWeight.w500),
      );
    });

    test('Typography utilities work correctly', () {
      const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
      const newColor = Colors.blue;

      final styledText = OmnisonicTypography.withColor(baseStyle, newColor);
      expect(styledText.color, equals(newColor));
      expect(styledText.fontSize, equals(baseStyle.fontSize));

      final opacityText = OmnisonicTypography.withOpacity(baseStyle, 0.5);
      expect(opacityText.color?.alpha, equals((255 * 0.5).round()));
    });
  });
}
