import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/accessibility.dart';
import 'package:omnisonic/core/design_system/accessibility_preferences.dart';
import 'package:omnisonic/core/design_system/colors.dart';

void main() {
  group('Accessibility Tests', () {
    test('Color contrast calculation works correctly', () {
      // Test high contrast colors
      final highContrast = OmnisonicAccessibility.calculateContrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(highContrast, greaterThan(20.0)); // Should be 21:1

      // Test low contrast colors
      final lowContrast = OmnisonicAccessibility.calculateContrastRatio(
        Colors.grey.shade400,
        Colors.grey.shade500,
      );
      expect(lowContrast, lessThan(4.5)); // Should fail WCAG AA
    });

    test('WCAG AA compliance check works', () {
      // Test passing combination
      expect(
        OmnisonicAccessibility.meetsWCAGAA(Colors.black, Colors.white),
        isTrue,
      );

      // Test failing combination
      expect(
        OmnisonicAccessibility.meetsWCAGAA(
          Colors.grey.shade400,
          Colors.grey.shade500,
        ),
        isFalse,
      );
    });

    test('Theme accessibility validation works', () {
      const lightTheme = ColorScheme.light();
      final results = OmnisonicAccessibility.validateThemeAccessibility(
        lightTheme,
      );

      expect(results, isA<Map<String, bool>>());
      expect(results.isNotEmpty, isTrue);

      // Most combinations should pass for Material light theme
      final passedTests = results.values.where((passed) => passed).length;
      expect(passedTests, greaterThan(results.length ~/ 2));
    });

    test('Semantic labels are generated correctly', () {
      final trackLabel = OmnisonicSemantics.trackSemanticLabel(
        title: 'Test Song',
        artist: 'Test Artist',
        duration: const Duration(minutes: 3, seconds: 45),
        isPlaying: true,
        isFavorite: true,
      );

      expect(trackLabel, contains('Now playing'));
      expect(trackLabel, contains('Test Song'));
      expect(trackLabel, contains('Test Artist'));
      expect(trackLabel, contains('3 minutes and 45 seconds'));
      expect(trackLabel, contains('marked as favorite'));
    });

    test('Album semantic labels work correctly', () {
      final albumLabel = OmnisonicSemantics.albumSemanticLabel(
        title: 'Test Album',
        artist: 'Test Artist',
        trackCount: 12,
        year: 2023,
      );

      expect(albumLabel, contains('Album Test Album'));
      expect(albumLabel, contains('Test Artist'));
      expect(albumLabel, contains('from 2023'));
      expect(albumLabel, contains('12 tracks'));
    });

    test('Alternative text generation works', () {
      final altText = OmnisonicAlternativeText.albumArtworkAlt(
        albumTitle: 'Test Album',
        artistName: 'Test Artist',
        hasArtwork: true,
      );

      expect(altText, contains('Album artwork'));
      expect(altText, contains('Test Album'));
      expect(altText, contains('Test Artist'));
    });
  });

  group('Accessibility Preferences Tests', () {
    test('Accessibility preferences can be created', () {
      final preferences = OmnisonicAccessibilityPreferences();

      // Test default values
      expect(preferences.reducedMotionEnabled, isFalse);
      expect(preferences.highContrastEnabled, isFalse);
      expect(preferences.largeTextEnabled, isFalse);
      expect(preferences.screenReaderEnabled, isFalse);
      expect(preferences.hapticFeedbackEnabled, isTrue);
    });

    test('Animation adjustments work correctly', () {
      final preferences = OmnisonicAccessibilityPreferences();

      // Test normal duration
      const normalDuration = Duration(milliseconds: 300);
      expect(
        preferences.getAdjustedDuration(normalDuration),
        equals(normalDuration),
      );

      // Test with reduced motion (would need to mock the setting)
      expect(preferences.shouldDisableAnimations, isFalse);
      expect(preferences.animationScale, equals(1.0));
    });
  });
}
