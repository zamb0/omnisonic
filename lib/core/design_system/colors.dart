import 'package:flutter/material.dart';

/// Comprehensive color palette system for Omnisonic UI Enhancement
class OmnisonicColors {
  // ---------------------------------------------------------------------
  // Aurora Glass v2 palette (docs/design-system.md §2)
  // ---------------------------------------------------------------------

  // Canvas
  static const Color midnight = Color(0xFF0B0A12);
  static const Color pearl = Color(0xFFF6F4FA);

  // Accent (electric violet): live state, focus, selection.
  static const Color primaryDark = Color(0xFFB49CFF); // 8.6:1 on Midnight
  static const Color primaryLight = Color(0xFF6A3DF0); // 5.4:1 on Pearl
  static const Color onPrimaryDark = Color(0xFF1A0F3D);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);

  // Secondary (magenta): second Aurora stop, "new" badges.
  static const Color secondaryDark = Color(0xFFF07BFF);
  static const Color secondaryLight = Color(0xFFB026C9);

  // Heat (coral): favourites / love only.
  static const Color heatDark = Color(0xFFFF8A6B);
  static const Color heatLight = Color(0xFFB83A1F);

  // Tertiary (aqua): info, download, offline, cache.
  static const Color tertiaryDark = Color(0xFF4FE3D0);
  static const Color tertiaryLight = Color(0xFF0A7268);

  // Aurora signature gradient stops.
  static const Color auroraViolet = Color(0xFF9479FF);
  static const Color auroraMagenta = Color(0xFFE07BFF);
  static const Color auroraCoral = Color(0xFFFF8F6B);

  /// Text and icons on Aurora, in both themes (5.9–8.7:1 on the stops).
  static const Color onAurora = Color(0xFF14081F);

  // Semantic colours: vivid on dark, `*Accessible` on light.
  static const Color success = Color(0xFF4ADE9B);
  static const Color warning = Color(0xFFFFC25C);
  static const Color error = Color(0xFFFF6B7F);
  static const Color info = tertiaryDark;

  static const Color successAccessible = Color(0xFF13784B);
  static const Color warningAccessible = Color(0xFFA55A00);
  static const Color errorAccessible = Color(0xFFD12A45);
  static const Color infoAccessible = tertiaryLight;

  // Neutrals
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);

  // Surfaces
  static const Color surfaceLight = pearl;
  static const Color surfaceDark = midnight;
  static const Color onSurfaceLight = Color(0xFF17141F);
  static const Color onSurfaceDark = Color(0xFFF3F1F8);

  // Containers - Light Mode
  static const Color primaryContainerLight = Color(0xFFECE6FF);
  static const Color onPrimaryContainerLight = Color(0xFF2A1F5C);
  static const Color secondaryContainerLight = Color(0xFFF7E4FB);
  static const Color onSecondaryContainerLight = Color(0xFF4A0F57);
  static const Color tertiaryContainerLight = Color(0xFFD4F4F0);
  static const Color onTertiaryContainerLight = Color(0xFF00332E);
  static const Color errorContainerLight = Color(0xFFFEE2E6);
  static const Color onErrorContainerLight = Color(0xFF6B0F20);

  // Containers - Dark Mode
  static const Color primaryContainerDark = Color(0xFF2B2350);
  static const Color onPrimaryContainerDark = Color(0xFFE9E1FF);
  static const Color secondaryContainerDark = Color(0xFF45204F);
  static const Color onSecondaryContainerDark = Color(0xFFF9E1FF);
  static const Color tertiaryContainerDark = Color(0xFF0A3B38);
  static const Color onTertiaryContainerDark = Color(0xFFCFF8F3);
  static const Color errorContainerDark = Color(0xFF4F1520);
  static const Color onErrorContainerDark = Color(0xFFFFDDE2);

  // Light Theme Color Scheme (Pearl). The surfaceContainer ladder is spelled
  // out because Material's defaults collapse every level onto `surface`.
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: onPrimaryLight,
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
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBFAFD),
    surfaceContainer: Color(0xFFEFECF5),
    surfaceContainerHigh: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFE9E5F1),
    onSurfaceVariant: Color(0xFF5C5670), // 6.4:1 on the canvas
    outline: Color(0xFF8C869E), // 3.2:1, the floor for an input's edge
    outlineVariant: Color(0x1A2A1F5C),
    shadow: Color(0x1A000000),
    scrim: Color(0x80000000),
    inverseSurface: Color(0xFF1C1A29),
    onInverseSurface: Color(0xFFF3F1F8),
    inversePrimary: primaryDark,
    surfaceTint: Colors.transparent,
  );

  // Dark Theme Color Scheme (Midnight)
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: onPrimaryDark,
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: onPrimaryContainerDark,
    secondary: secondaryDark,
    onSecondary: Color(0xFF2A0833),
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: onSecondaryContainerDark,
    tertiary: tertiaryDark,
    onTertiary: Color(0xFF00332E),
    tertiaryContainer: tertiaryContainerDark,
    onTertiaryContainer: onTertiaryContainerDark,
    error: error,
    onError: Color(0xFF3A0A12),
    errorContainer: errorContainerDark,
    onErrorContainer: onErrorContainerDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceContainerLowest: Color(0xFF07060C),
    surfaceContainerLow: Color(0xFF100F19),
    surfaceContainer: Color(0xFF15141F),
    surfaceContainerHigh: Color(0xFF1C1A29),
    surfaceContainerHighest: Color(0xFF262338),
    onSurfaceVariant: Color(0xFFA9A4BC), // 8.2:1 on the canvas
    outline: Color(0xFF6E6885), // 3.7:1
    outlineVariant: Color(0x1AFFFFFF),
    shadow: Color(0x80000000),
    scrim: Color(0xCC000000),
    inverseSurface: Color(0xFFF3F1F8),
    onInverseSurface: Color(0xFF17141F),
    inversePrimary: primaryLight,
    surfaceTint: Colors.transparent,
  );

  // Scrims and the colours that sit on them. Artwork can be any colour, so
  // anything drawn over it goes on a dark scrim and uses the on-scrim
  // colours, in both themes.

  /// Behind controls over artwork — the card hover overlay.
  static const Color scrim = Color(0x8C000000);

  /// Over artwork while a card is hovered: 35 %, enough to seat the Play
  /// disc without hiding the cover.
  static const Color scrimHover = Color(0x59000000);

  /// Under text over artwork — the bottom of a hero image.
  static const Color scrimStrong = Color(0xB3000000);

  /// Text and icons on a [scrim].
  static const Color onScrim = Color(0xFFFFFFFF);

  /// Secondary text and icons on a [scrim].
  static const Color onScrimMuted = Color(0xCCFFFFFF);

  /// Icons on a solid [onScrim] disc — the play button over a cover.
  static const Color onScrimFill = Color(0xFF0B0A12);

  /// A translucent control on a [scrim] — the secondary buttons over a
  /// cover.
  static const Color scrimControl = Color(0x33FFFFFF);

  /// Text on a [warning] or [success] fill. White on those was 2.1:1 and
  /// 2.5:1; these dark tones clear 7:1.
  static const Color onWarning = Color(0xFF241500);
  static const Color onSuccess = Color(0xFF00210F);

  // Status colors with opacity variants
  static const Color successLight = Color(0xFFD6F5E6);
  static const Color warningLight = Color(0xFFFFEFCC);
  static const Color errorLight = Color(0xFFFEE2E6);
  static const Color infoLight = Color(0xFFD4F4F0);

  static const Color successDark = Color(0xFF0B3D2A);
  static const Color warningDark = Color(0xFF4A3000);
  static const Color errorDark = Color(0xFF4F1520);
  static const Color infoDark = Color(0xFF0A3B38);

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

  /// Server dot hues for dark themes (oklch L .74 C .15; 7.8–11.5:1 on
  /// Midnight). Avoid red/orange/yellow (read as errors) and the Aurora
  /// violet/magenta (read as brand / "now playing"). Ordered so neighbouring
  /// servers get distant hues.
  static const List<Color> serverHueSwatches = [
    Color(0xFF5AA9F0),
    Color(0xFF4FD6A0),
    Color(0xFF4FD0DE),
    Color(0xFFA7D45A),
    Color(0xFF8FA2FF),
    Color(0xFF5CC9C0),
    Color(0xFFC6B25A),
    Color(0xFF7FB8E8),
  ];

  /// Same hues for light themes (oklch L .52; >= 3:1 on Pearl).
  static const List<Color> serverHueSwatchesLight = [
    Color(0xFF2E78C7),
    Color(0xFF0F8A5F),
    Color(0xFF0F7F8C),
    Color(0xFF5E7F10),
    Color(0xFF4F63D6),
    Color(0xFF0F7F77),
    Color(0xFF78650A),
    Color(0xFF2F73A8),
  ];

  /// Deterministic accent color for a server ID. Hashes `serverId`'s code
  /// units directly (`String.hashCode` is not stable across platforms).
  /// Pass [index] — the server's position in the user's list — where known:
  /// hashing eight swatches collides quickly. Pass [brightness] to get the
  /// variant that clears 3:1 on the theme's canvas.
  static Color serverColorFor(
    String serverId, {
    int? index,
    Brightness brightness = Brightness.dark,
  }) {
    final swatches = brightness == Brightness.dark
        ? serverHueSwatches
        : serverHueSwatchesLight;
    if (index != null && index >= 0) {
      return swatches[index % swatches.length];
    }
    var hash = 0;
    for (final unit in serverId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return swatches[hash % swatches.length];
  }
}
