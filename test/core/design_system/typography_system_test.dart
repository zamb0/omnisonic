import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/typography.dart';

void main() {
  group('Typography Scale Tests', () {
    test('Typography scale has consistent font families', () {
      expect(
        OmnisonicTypography.displayLarge.fontFamily,
        OmnisonicTypography.displayFont,
      );
      expect(
        OmnisonicTypography.headlineLarge.fontFamily,
        OmnisonicTypography.displayFont,
      );
      expect(
        OmnisonicTypography.titleLarge.fontFamily,
        OmnisonicTypography.primaryFont,
      );
      expect(
        OmnisonicTypography.bodyLarge.fontFamily,
        OmnisonicTypography.primaryFont,
      );
      expect(
        OmnisonicTypography.duration.fontFamily,
        OmnisonicTypography.monoFont,
      );
    });

    test('Typography scale has proper font sizes', () {
      expect(OmnisonicTypography.displayLarge.fontSize, equals(57));
      expect(OmnisonicTypography.displayMedium.fontSize, equals(45));
      expect(OmnisonicTypography.headlineLarge.fontSize, equals(32));
      expect(OmnisonicTypography.titleLarge.fontSize, equals(22));
      expect(OmnisonicTypography.bodyLarge.fontSize, equals(16));
    });

    test('Music-specific typography has correct properties', () {
      expect(
        OmnisonicTypography.trackTitle.fontFamily,
        OmnisonicTypography.primaryFont,
      );
      expect(OmnisonicTypography.trackTitle.fontSize, equals(16));
      expect(
        OmnisonicTypography.trackTitle.fontWeight,
        equals(FontWeight.w500),
      );

      expect(
        OmnisonicTypography.artistName.fontFamily,
        OmnisonicTypography.primaryFont,
      );
      expect(OmnisonicTypography.artistName.fontSize, equals(14));

      expect(
        OmnisonicTypography.albumTitle.fontFamily,
        OmnisonicTypography.primaryFont,
      );
      expect(OmnisonicTypography.albumTitle.fontSize, equals(14));
      expect(
        OmnisonicTypography.albumTitle.fontWeight,
        equals(FontWeight.w500),
      );
    });

    // Every weight a style asks for has to have a matching `asset:` entry in
    // pubspec.yaml, otherwise Flutter silently renders the nearest bundled
    // weight and the design drifts without anything failing.
    test('Every style uses a bundled weight', () {
      final bundled = <String, Set<FontWeight>>{
        OmnisonicTypography.primaryFont: {
          FontWeight.w400,
          FontWeight.w500,
          FontWeight.w600,
          FontWeight.w700,
        },
        OmnisonicTypography.displayFont: {
          FontWeight.w500,
          FontWeight.w600,
          FontWeight.w700,
          FontWeight.w800,
        },
        OmnisonicTypography.monoFont: {
          FontWeight.w400,
          FontWeight.w500,
          FontWeight.w600,
        },
      };

      final styles = <String, TextStyle>{
        'displayLarge': OmnisonicTypography.displayLarge,
        'displayMedium': OmnisonicTypography.displayMedium,
        'displaySmall': OmnisonicTypography.displaySmall,
        'headlineLarge': OmnisonicTypography.headlineLarge,
        'headlineMedium': OmnisonicTypography.headlineMedium,
        'headlineSmall': OmnisonicTypography.headlineSmall,
        'titleLarge': OmnisonicTypography.titleLarge,
        'titleMedium': OmnisonicTypography.titleMedium,
        'titleSmall': OmnisonicTypography.titleSmall,
        'labelLarge': OmnisonicTypography.labelLarge,
        'labelMedium': OmnisonicTypography.labelMedium,
        'labelSmall': OmnisonicTypography.labelSmall,
        'bodyLarge': OmnisonicTypography.bodyLarge,
        'bodyMedium': OmnisonicTypography.bodyMedium,
        'bodySmall': OmnisonicTypography.bodySmall,
        'trackTitle': OmnisonicTypography.trackTitle,
        'artistName': OmnisonicTypography.artistName,
        'albumTitle': OmnisonicTypography.albumTitle,
        'playlistTitle': OmnisonicTypography.playlistTitle,
        'nowPlayingTitle': OmnisonicTypography.nowPlayingTitle,
        'nowPlayingArtist': OmnisonicTypography.nowPlayingArtist,
        'duration': OmnisonicTypography.duration,
        'metadata': OmnisonicTypography.metadata,
        'pageTitle': OmnisonicTypography.pageTitle,
        'sectionTitle': OmnisonicTypography.sectionTitle,
        'sectionTitleSmall': OmnisonicTypography.sectionTitleSmall,
        'eyebrow': OmnisonicTypography.eyebrow,
        'navLabel': OmnisonicTypography.navLabel,
        'glassButton': OmnisonicTypography.glassButton,
        'statValue': OmnisonicTypography.statValue,
        'technical': OmnisonicTypography.technical,
        'buttonLarge': OmnisonicTypography.buttonLarge,
        'buttonMedium': OmnisonicTypography.buttonMedium,
        'buttonSmall': OmnisonicTypography.buttonSmall,
        'caption': OmnisonicTypography.caption,
        'overline': OmnisonicTypography.overline,
      };

      styles.forEach((name, style) {
        final weights = bundled[style.fontFamily];
        expect(weights, isNotNull, reason: '$name uses an unknown family');
        expect(
          weights,
          contains(style.fontWeight),
          reason: '$name asks for ${style.fontWeight} in ${style.fontFamily}, '
              'which is not bundled in pubspec.yaml',
        );
      });
    });

    // A missing or misnamed font asset doesn't throw — Flutter silently
    // falls back to the platform font, so every other assertion here would
    // still pass while the app rendered in the wrong typeface. Measuring
    // real glyphs is the only way to catch that.
    testWidgets('Bundled families actually render', (tester) async {
      Future<Size> measure(String family) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: Text(
                'Omnisonic WWWiii',
                style: TextStyle(fontFamily: family, fontSize: 40),
              ),
            ),
          ),
        );
        return tester.getSize(find.byType(Text));
      }

      final fallback = await measure('NoSuchFontFamily');
      for (final family in [
        OmnisonicTypography.primaryFont,
        OmnisonicTypography.displayFont,
        OmnisonicTypography.monoFont,
      ]) {
        expect(
          await measure(family),
          isNot(fallback),
          reason: '$family is not loading — check its assets/fonts/ entries '
              'in pubspec.yaml and test/flutter_test_config.dart',
        );
      }
    });

    test('Typography utilities work correctly', () {
      const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
      const newColor = Colors.blue;

      final styledText = OmnisonicTypography.withColor(baseStyle, newColor);
      expect(styledText.color, equals(newColor));
      expect(styledText.fontSize, equals(baseStyle.fontSize));

      final opacityText = OmnisonicTypography.withOpacity(baseStyle, 0.5);
      expect(opacityText.color?.a, closeTo(0.5, 0.01));
    });
  });
}
