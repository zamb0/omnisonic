import 'package:flutter/material.dart';

/// Comprehensive color palette system for Omnisonic UI Enhancement
class OmnisonicColors {
  // Primary Brand Colors
  static const Color primaryPurple = Color(0xFF7C7CFF);
  static const Color primaryBlue = Color(0xFF5A67D8);
  static const Color primaryTeal = Color(0xFF4DD0E1);

  // Secondary Colors
  static const Color secondaryIndigo = Color(0xFF6D6DFF);
  static const Color secondaryViolet = Color(0xFF8B7BFF);
  static const Color secondaryCyan = Color(0xFF3DB6C6);

  // Accent Colors
  static const Color accentPink = Color(0xFFEC6BA6);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentGreen = Color(0xFF10B981);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Semantic Colors - accessible on light surfaces.
  // The vivid variants above stay too light for white foreground text; these
  // keep the same hue while clearing WCAG AA (4.5:1) against white.
  static const Color successAccessible = Color(0xFF047857); // 5.48:1 on white
  static const Color warningAccessible = Color(0xFFB45309); // 5.02:1 on white
  static const Color errorAccessible = Color(0xFFDC2626); // 4.83:1 on white
  static const Color infoAccessible = Color(0xFF1D4ED8); // 6.70:1 on white

  // Brand Colors - accessible on light surfaces.
  // Same hues as the primary/secondary/tertiary brand colors, darkened so that
  // white foreground text and `primary`-coloured text on white both clear AA.
  static const Color primaryLight = Color(0xFF4F46E5); // 6.29:1 on white
  static const Color secondaryLight = Color(0xFF4338CA); // 7.68:1 on white
  static const Color tertiaryLight = Color(0xFF0E7490); // 5.36:1 on white

  // Neutral Colors - Light Mode
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray50 = Color(0xFFF9FAFB);
  static const Color neutralGray100 = Color(0xFFF3F4F6);
  static const Color neutralGray200 = Color(0xFFE5E7EB);
  static const Color neutralGray300 = Color(0xFFD1D5DB);
  static const Color neutralGray400 = Color(0xFF9CA3AF);
  static const Color neutralGray500 = Color(0xFF6B7280);
  static const Color neutralGray600 = Color(0xFF4B5563);
  static const Color neutralGray700 = Color(0xFF374151);
  static const Color neutralGray800 = Color(0xFF1F2937);
  static const Color neutralGray900 = Color(0xFF111827);
  static const Color neutralBlack = Color(0xFF000000);

  // Surface Colors - Light Mode (warm greige, liquid-glass redesign)
  static const Color surfaceLight = Color(0xFFEFEDEA);
  static const Color cardLight = Color(0xFFEFEDEA);
  static const Color backgroundLight = Color(0xFFE8E6E2);
  static const Color onSurfaceLight = Color(0xFF141414);
  static const Color onBackgroundLight = Color(0xFF141414);

  // Container Colors - Light Mode
  static const Color primaryContainerLight = Color(0xFFE6E7FF);
  static const Color onPrimaryContainerLight = Color(0xFF20204D);
  static const Color secondaryContainerLight = Color(0xFFEDEAFF);
  static const Color onSecondaryContainerLight = Color(0xFF24245A);
  static const Color tertiaryContainerLight = Color(0xFFD4F4F8);
  static const Color onTertiaryContainerLight = Color(0xFF003544);
  static const Color errorContainerLight = Color(0xFFFEE2E2);
  static const Color onErrorContainerLight = Color(0xFF7F1D1D);

  // Surface Colors - Dark Mode (near-black, liquid-glass redesign)
  static const Color surfaceDark = Color(0xFF0D0E10);
  static const Color cardDark = Color(0xFF0D0E10);
  static const Color backgroundDark = Color(0xFF0C0D0F);
  static const Color onSurfaceDark = Color(0xFFF4F2EF);
  static const Color onBackgroundDark = Color(0xFFF4F2EF);

  // Container Colors - Dark Mode
  static const Color primaryContainerDark = Color(0xFF2A2A46);
  static const Color onPrimaryContainerDark = Color(0xFFE6E7FF);
  static const Color secondaryContainerDark = Color(0xFF2B2B4D);
  static const Color onSecondaryContainerDark = Color(0xFFEDEAFF);
  static const Color tertiaryContainerDark = Color(0xFF003B4D);
  static const Color onTertiaryContainerDark = Color(0xFFD4F4F8);
  static const Color errorContainerDark = Color(0xFF5F1D1D);
  static const Color onErrorContainerDark = Color(0xFFFEE2E2);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryBlue, primaryTeal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryPurple, secondaryViolet, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFF5F5F5), Color(0xFFEAEAEA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSubtleGradient = LinearGradient(
    colors: [Color(0xFF141414), Color(0xFF1F1F21)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Animated gradient definitions for smooth transitions
  static const LinearGradient primaryAnimatedGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentAnimatedGradient = LinearGradient(
    colors: [accentPink, primaryPurple, primaryBlue],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    stops: [0.0, 0.6, 1.0],
  );

  // Radial gradients for depth effects
  static const RadialGradient cardDepthGradient = RadialGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
    center: Alignment.topLeft,
    radius: 1.5,
  );

  static const RadialGradient darkCardDepthGradient = RadialGradient(
    colors: [Color(0xFF1F1F21), Color(0xFF141414)],
    center: Alignment.topLeft,
    radius: 1.5,
  );

  // Shimmer gradients for loading states
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );

  static const LinearGradient darkShimmerGradient = LinearGradient(
    colors: [Color(0xFF2B2B2B), Color(0xFF3B3B3B), Color(0xFF2B2B2B)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );

  // Glass morphism gradients
  static const LinearGradient glassMorphismLight = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x20FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassMorphismDark = LinearGradient(
    colors: [Color(0x40000000), Color(0x20000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Music player specific gradients
  static const LinearGradient nowPlayingGradient = LinearGradient(
    colors: [primaryPurple, secondaryIndigo],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient albumArtOverlay = LinearGradient(
    colors: [Color(0x00000000), Color(0x80000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient progressBarGradient = LinearGradient(
    colors: [primaryTeal, primaryBlue, primaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Light Theme Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: neutralWhite,
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: onPrimaryContainerLight,
    secondary: secondaryLight,
    onSecondary: neutralWhite,
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: onSecondaryContainerLight,
    tertiary: tertiaryLight,
    onTertiary: neutralWhite,
    tertiaryContainer: tertiaryContainerLight,
    onTertiaryContainer: onTertiaryContainerLight,
    error: errorAccessible,
    onError: neutralWhite,
    errorContainer: errorContainerLight,
    onErrorContainer: onErrorContainerLight,
    surface: surfaceLight,
    onSurface: onSurfaceLight,
    surfaceContainerHighest: neutralGray100,
    onSurfaceVariant: neutralGray600,
    outline: neutralGray300,
    outlineVariant: neutralGray200,
    shadow: Color(0x1A000000),
    scrim: Color(0x80000000),
    inverseSurface: neutralGray800,
    onInverseSurface: neutralGray100,
    inversePrimary: Color(0xFF9CA3FF),
    surfaceTint: primaryLight,
  );

  // Dark Theme Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9CA3FF),
    onPrimary: Color(0xFF1E1B3A),
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: onPrimaryContainerDark,
    secondary: Color(0xFF7C7CFF),
    onSecondary: Color(0xFF1A1A3A),
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: onSecondaryContainerDark,
    tertiary: Color(0xFF4DD0E1),
    onTertiary: Color(0xFF003544),
    tertiaryContainer: tertiaryContainerDark,
    onTertiaryContainer: onTertiaryContainerDark,
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3A0A0A),
    errorContainer: errorContainerDark,
    onErrorContainer: onErrorContainerDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceContainerHighest: cardDark,
    onSurfaceVariant: Color(0xFF9A9A9A),
    outline: Color(0xFF2B2B2B),
    outlineVariant: Color(0xFF3B3B3B),
    shadow: Color(0x80000000),
    scrim: Color(0xCC000000),
    inverseSurface: neutralGray100,
    onInverseSurface: neutralGray800,
    inversePrimary: primaryPurple,
    surfaceTint: Color(0xFF9CA3FF),
  );

  // Music-specific colors
  static const Color playingIndicator = Color(0xFF1DB954); // Spotify-like green
  static const Color pausedIndicator = Color(0xFFF59E0B);
  static const Color queueIndicator = Color(0xFF8B5CF6);
  static const Color favoriteIndicator = Color(0xFFEC4899);

  // Scrims and the colours that sit on them. Artwork can be any colour, so
  // anything drawn over it goes on a dark scrim and uses the on-scrim
  // colours, in both themes.

  /// Behind controls over artwork — the card hover overlay.
  static const Color scrim = Color(0x8C000000);

  /// Under text over artwork — the bottom of a hero image.
  static const Color scrimStrong = Color(0xB3000000);

  /// Text and icons on a [scrim].
  static const Color onScrim = Color(0xFFFFFFFF);

  /// Secondary text and icons on a [scrim].
  static const Color onScrimMuted = Color(0xCCFFFFFF);

  /// Text on a [warning] or [success] fill. White on those was 2.1:1 and
  /// 2.5:1; these dark tones clear 7:1.
  static const Color onWarning = Color(0xFF241500);
  static const Color onSuccess = Color(0xFF00210F);

  // Status colors with opacity variants
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDBEAFE);

  static const Color successDark = Color(0xFF064E3B);
  static const Color warningDark = Color(0xFF78350F);
  static const Color errorDark = Color(0xFF7F1D1D);
  static const Color infoDark = Color(0xFF1E3A8A);

  // ---------------------------------------------------------------------
  // Liquid-glass surfaces
  // ---------------------------------------------------------------------

  /// White-overlay alpha stops for light-mode glass surfaces, from most
  /// transparent (subtle chrome) to most opaque (modal-like panels).
  static const List<double> glassAlphasLight = [0.40, 0.55, 0.70, 0.85];

  /// White-overlay alpha stops for dark-mode glass surfaces. Far fainter
  /// than the light stack since it sits on a near-black base.
  static const List<double> glassAlphasDark = [0.05, 0.09, 0.13, 0.18];

  /// A flat glass-like fill for a tile inside a glass pane: a white wash
  /// at [light] alpha in light mode and [dark] alpha in dark mode.
  static Color glassFill(
    Brightness brightness, {
    double light = 0.55,
    double dark = 0.06,
  }) => neutralWhite.withValues(
    alpha: brightness == Brightness.dark ? dark : light,
  );

  static Color glassLight(int stop) =>
      Colors.white.withValues(alpha: glassAlphasLight[stop]);

  static Color glassDark(int stop) =>
      Colors.white.withValues(alpha: glassAlphasDark[stop]);

  // ---------------------------------------------------------------------
  // Per-server accent hues
  // ---------------------------------------------------------------------

  /// Precomputed sRGB stand-ins for an oklch(.68 .16 H) sweep (H = 0..330 in
  /// 30° steps), used to give each source server a stable, distinguishable
  /// accent dot without a runtime oklch->sRGB conversion.
  static const List<Color> serverHueSwatches = [
    Color(0xFFD86464), // H 0
    Color(0xFFD89E64), // H 30
    Color(0xFFD8D864), // H 60
    Color(0xFF9ED864), // H 90
    Color(0xFF64D864), // H 120
    Color(0xFF64D89E), // H 150
    Color(0xFF64D8D8), // H 180
    Color(0xFF649ED8), // H 210
    Color(0xFF6464D8), // H 240
    Color(0xFF9E64D8), // H 270
    Color(0xFFD864D8), // H 300
    Color(0xFFD8649E), // H 330
  ];

  /// Deterministic accent color for a server ID, used to tag which source
  /// server a track/album came from in the aggregated view. Hashes
  /// `serverId`'s code units directly (rather than `String.hashCode`, which
  /// is not guaranteed stable across platforms/isolates) so the same server
  /// always gets the same dot everywhere.
  ///
  /// Pass [index] — the server's position in the user's server list — where
  /// it is known: hashing ~12 swatches collides as soon as there are a few
  /// servers, and two servers with the same dot defeat the point of it.
  static Color serverColorFor(String serverId, {int? index}) {
    if (index != null && index >= 0) {
      return serverHueSwatches[index % serverHueSwatches.length];
    }
    var hash = 0;
    for (final unit in serverId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return serverHueSwatches[hash % serverHueSwatches.length];
  }
}
