import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

void main() {
  group('Design System Tests', () {
    test('Color palette has all required colors', () {
      // Test primary colors
      expect(OmnisonicColors.primaryPurple, const Color(0xFF6366F1));
      expect(OmnisonicColors.primaryBlue, const Color(0xFF3B82F6));
      expect(OmnisonicColors.primaryTeal, const Color(0xFF06B6D4));

      // Test semantic colors
      expect(OmnisonicColors.success, const Color(0xFF10B981));
      expect(OmnisonicColors.warning, const Color(0xFFF59E0B));
      expect(OmnisonicColors.error, const Color(0xFFEF4444));
      expect(OmnisonicColors.info, const Color(0xFF3B82F6));
    });

    test('Typography system has all required styles', () {
      // Test display styles
      expect(OmnisonicTypography.displayLarge.fontFamily, 'Poppins');
      expect(OmnisonicTypography.displayLarge.fontSize, 57);
      expect(OmnisonicTypography.displayLarge.fontWeight, FontWeight.w700);

      // Test body styles
      expect(OmnisonicTypography.bodyLarge.fontFamily, 'Inter');
      expect(OmnisonicTypography.bodyLarge.fontSize, 16);
      expect(OmnisonicTypography.bodyLarge.fontWeight, FontWeight.w400);

      // Test music-specific styles
      expect(OmnisonicTypography.trackTitle.fontFamily, 'Inter');
      expect(OmnisonicTypography.artistName.fontFamily, 'Inter');
      expect(OmnisonicTypography.albumTitle.fontFamily, 'Inter');
    });

    test('Spacing system follows 8px grid', () {
      expect(OmnisonicSpacing.baseUnit, 8.0);
      expect(OmnisonicSpacing.xs, 4.0);
      expect(OmnisonicSpacing.sm, 8.0);
      expect(OmnisonicSpacing.md, 16.0);
      expect(OmnisonicSpacing.lg, 24.0);
      expect(OmnisonicSpacing.xl, 32.0);
    });

    test('Icon sizes are consistent', () {
      expect(OmnisonicIconSizes.xs, 12.0);
      expect(OmnisonicIconSizes.sm, 16.0);
      expect(OmnisonicIconSizes.md, 24.0);
      expect(OmnisonicIconSizes.lg, 32.0);
      expect(OmnisonicIconSizes.xl, 40.0);
    });

    test('Touch targets meet accessibility requirements', () {
      expect(OmnisonicTouchTargets.minimum, 44.0);
      expect(OmnisonicTouchTargets.comfortable, 48.0);
      expect(OmnisonicTouchTargets.large, 56.0);
    });

    test('Theme manager handles theme switching', () {
      final themeManager = OmnisonicThemeManager();

      // Test initial state
      expect(themeManager.themeMode, ThemeMode.system);
      expect(themeManager.themeModeName, 'System');

      // Test switching to light theme
      themeManager.setLightTheme();
      expect(themeManager.themeMode, ThemeMode.light);
      expect(themeManager.themeModeName, 'Light');

      // Test switching to dark theme
      themeManager.setDarkTheme();
      expect(themeManager.themeMode, ThemeMode.dark);
      expect(themeManager.themeModeName, 'Dark');

      // Test toggle functionality
      themeManager.toggleTheme();
      expect(themeManager.themeMode, ThemeMode.light);
    });

    test('Color schemes are properly configured', () {
      final lightScheme = OmnisonicColors.lightColorScheme;
      final darkScheme = OmnisonicColors.darkColorScheme;

      expect(lightScheme.brightness, Brightness.light);
      expect(darkScheme.brightness, Brightness.dark);

      // The light scheme uses the darkened brand variants so that white
      // foreground text on them clears WCAG AA; see color_contrast_test.dart.
      expect(lightScheme.primary, OmnisonicColors.primaryLight);
      expect(lightScheme.secondary, OmnisonicColors.secondaryLight);
      expect(lightScheme.tertiary, OmnisonicColors.tertiaryLight);
    });

    test('Gradients are properly defined', () {
      expect(OmnisonicColors.primaryGradient.colors.length, 2);
      expect(
        OmnisonicColors.primaryGradient.colors[0],
        OmnisonicColors.primaryPurple,
      );
      expect(
        OmnisonicColors.primaryGradient.colors[1],
        OmnisonicColors.primaryBlue,
      );

      expect(OmnisonicColors.accentGradient.colors.length, 2);
      expect(
        OmnisonicColors.accentGradient.colors[0],
        OmnisonicColors.primaryBlue,
      );
      expect(
        OmnisonicColors.accentGradient.colors[1],
        OmnisonicColors.primaryTeal,
      );
    });

    test('Grid system provides responsive columns', () {
      expect(OmnisonicGrid.mobileColumns, 4);
      expect(OmnisonicGrid.tabletColumns, 8);
      expect(OmnisonicGrid.desktopColumns, 12);
    });

    test('Border radius values are consistent', () {
      expect(OmnisonicRadius.xs, 4.0);
      expect(OmnisonicRadius.sm, 8.0);
      expect(OmnisonicRadius.md, 12.0);
      expect(OmnisonicRadius.lg, 16.0);
      expect(OmnisonicRadius.xl, 20.0);
    });

    test('Elevation values follow Material Design', () {
      expect(OmnisonicElevation.none, 0.0);
      expect(OmnisonicElevation.xs, 1.0);
      expect(OmnisonicElevation.sm, 2.0);
      expect(OmnisonicElevation.md, 4.0);
      expect(OmnisonicElevation.lg, 8.0);
    });
  });
}
