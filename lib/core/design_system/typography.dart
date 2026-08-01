import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Omnisonic UI Enhancement
/// Uses Inter for body text and Poppins for display text
///
/// Fonts are loaded via `google_fonts` (fetched and cached on first use, no
/// bundled `.ttf` assets required) rather than declared as bare
/// `fontFamily` strings, which silently fall back to the system font
/// without ever actually loading the intended typeface.
class OmnisonicTypography {
  // Font families
  static const String primaryFont = 'Inter';
  static const String displayFont = 'Poppins';
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
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle get displaySmall => GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline styles (using Poppins)
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title styles (using Inter)
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Label styles (using Inter)
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Body styles (using Inter)
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Music-specific typography styles
  static TextStyle get trackTitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get artistName => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get albumTitle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get playlistTitle => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get nowPlayingTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get nowPlayingArtist => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get duration => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.2,
  );

  static TextStyle get metadata => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.3,
    height: 1.3,
  );

  // Button typography
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // Caption and overline
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static TextStyle get overline => GoogleFonts.inter(
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
