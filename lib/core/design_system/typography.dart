import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Omnisonic UI Enhancement
/// Uses Manrope for UI text, Gabarito for display text, and JetBrains Mono
/// for technical text (durations, bitrates, IDs, server names).
///
/// Fonts are loaded via `google_fonts` (fetched and cached on first use, no
/// bundled `.ttf` assets required) rather than declared as bare
/// `fontFamily` strings, which silently fall back to the system font
/// without ever actually loading the intended typeface.
class OmnisonicTypography {
  // Font families
  static const String primaryFont = 'Manrope';
  static const String displayFont = 'Gabarito';
  static const String monoFont = 'JetBrains Mono';
  static const String fallbackFont = 'Roboto';

  // Font weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // Display styles (using Poppins)
  static TextStyle get displayLarge => GoogleFonts.gabarito(
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.gabarito(
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle get displaySmall => GoogleFonts.gabarito(
    fontSize: 36,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline styles (using Poppins)
  static TextStyle get headlineLarge => GoogleFonts.gabarito(
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.gabarito(
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => GoogleFonts.gabarito(
    fontSize: 24,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title styles (using Inter)
  static TextStyle get titleLarge => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static TextStyle get titleSmall => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Label styles (using Inter)
  static TextStyle get labelLarge => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Body styles (using Inter)
  static TextStyle get bodyLarge => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Music-specific typography styles
  static TextStyle get trackTitle => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get artistName => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get albumTitle => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get playlistTitle => GoogleFonts.gabarito(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get nowPlayingTitle => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get nowPlayingArtist => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get duration => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.2,
  );

  static TextStyle get metadata => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.3,
    height: 1.3,
  );

  // Button typography
  static TextStyle get buttonLarge => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  static TextStyle get buttonMedium => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  static TextStyle get buttonSmall => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // Caption and overline
  static TextStyle get caption => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static TextStyle get overline => GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 1.5,
    height: 1.6,
  );

  /// Creates the complete TextTheme for the app
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
  );

  /// Creates a responsive text style based on screen size
  static TextStyle responsive({
    required BuildContext context,
    required TextStyle baseStyle,
    double? mobileScale,
    double? tabletScale,
    double? desktopScale,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scale = 1.0;

    if (screenWidth < 600) {
      scale = mobileScale ?? 0.9;
    } else if (screenWidth < 1200) {
      scale = tabletScale ?? 1.0;
    } else {
      scale = desktopScale ?? 1.1;
    }

    return baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * scale);
  }

  /// Creates a text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Creates a text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(
      color: (style.color ?? Colors.black).withValues(alpha: opacity),
    );
  }
}

/// Extension for easy access to music-specific typography
extension OmnisonicTextTheme on TextTheme {
  TextStyle get trackTitle => OmnisonicTypography.trackTitle;
  TextStyle get artistName => OmnisonicTypography.artistName;
  TextStyle get albumTitle => OmnisonicTypography.albumTitle;
  TextStyle get playlistTitle => OmnisonicTypography.playlistTitle;
  TextStyle get nowPlayingTitle => OmnisonicTypography.nowPlayingTitle;
  TextStyle get nowPlayingArtist => OmnisonicTypography.nowPlayingArtist;
  TextStyle get duration => OmnisonicTypography.duration;
  TextStyle get metadata => OmnisonicTypography.metadata;
  TextStyle get buttonLarge => OmnisonicTypography.buttonLarge;
  TextStyle get buttonMedium => OmnisonicTypography.buttonMedium;
  TextStyle get buttonSmall => OmnisonicTypography.buttonSmall;
  TextStyle get caption => OmnisonicTypography.caption;
  TextStyle get overline => OmnisonicTypography.overline;
}
