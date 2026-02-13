import 'package:flutter/material.dart';

/// Typography system for Omnisonic UI Enhancement
/// Uses Inter for body text and Poppins for display text
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
  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline styles (using Poppins)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 24,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title styles (using Inter)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Label styles (using Inter)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );
  
  // Body styles (using Inter)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Music-specific typography styles
  static const TextStyle trackTitle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static const TextStyle artistName = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );
  
  static const TextStyle albumTitle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.3,
  );
  
  static const TextStyle playlistTitle = TextStyle(
    fontFamily: displayFont,
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle nowPlayingTitle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle nowPlayingArtist = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );
  
  static const TextStyle duration = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.2,
  );
  
  static const TextStyle metadata = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.3,
    height: 1.3,
  );
  
  // Button typography
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );
  
  // Caption and overline
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  static const TextStyle overline = TextStyle(
    fontFamily: primaryFont,
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 1.5,
    height: 1.6,
  );
  
  /// Creates the complete TextTheme for the app
  static TextTheme get textTheme => const TextTheme(
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
    
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scale,
    );
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