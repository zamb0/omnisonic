import 'package:flutter/material.dart';

/// Typography system for Omnisonic UI Enhancement
/// Uses Manrope for UI text, Gabarito for display text, and JetBrains Mono
/// for technical text (durations, bitrates, IDs, server names).
///
/// The three families are bundled as assets (see the `fonts:` section of
/// `pubspec.yaml`) rather than fetched at runtime. Golden tests need
/// deterministic metrics, and a first launch shouldn't need the network to
/// draw text.
class OmnisonicTypography {
  // Font families. These names must match the `family:` keys in pubspec.yaml.
  static const String primaryFont = 'Manrope';
  static const String displayFont = 'Gabarito';
  static const String monoFont = 'JetBrains Mono';
  static const String fallbackFont = 'Roboto';

  // Family constructors. Every style below goes through one of these so the
  // family name is written once per typeface instead of once per style.
  static TextStyle _manrope({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: primaryFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle _gabarito({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: displayFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle _mono({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: monoFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    // Mono already has fixed-width digits; tnum keeps timers steady even if
    // the bundled face is unavailable and a proportional fallback is used.
    fontFeatures: const [FontFeature.tabularFigures()],
  );

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

  // Display styles
  static TextStyle get displayLarge => _gabarito(
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium =>
      _gabarito(fontSize: 45, fontWeight: bold, letterSpacing: 0, height: 1.16);

  static TextStyle get displaySmall => _gabarito(
    fontSize: 36,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline styles
  static TextStyle get headlineLarge => _gabarito(
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => _gabarito(
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => _gabarito(
    fontSize: 24,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title styles
  static TextStyle get titleLarge => _manrope(
    fontSize: 22,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle get titleMedium => _manrope(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static TextStyle get titleSmall => _manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Label styles
  static TextStyle get labelLarge => _manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => _manrope(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => _manrope(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Body styles
  static TextStyle get bodyLarge => _manrope(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _manrope(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => _manrope(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Music-specific typography styles
  static TextStyle get trackTitle =>
      _manrope(fontSize: 16, fontWeight: medium, letterSpacing: 0, height: 1.4);

  static TextStyle get artistName => _manrope(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get albumTitle => _manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get playlistTitle => _gabarito(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get nowPlayingTitle => _manrope(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get nowPlayingArtist => _manrope(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get duration =>
      _mono(fontSize: 12, fontWeight: regular, letterSpacing: 0.4, height: 1.2);

  static TextStyle get metadata =>
      _mono(fontSize: 12, fontWeight: regular, letterSpacing: 0.3, height: 1.3);

  // ---------------------------------------------------------------------
  // Liquid-glass shell styles
  //
  // The redesign leans on a much tighter set of type roles than the Material
  // ramp above: an oversized Gabarito title per screen, a Gabarito section
  // heading, a Gabarito nav/button label, and JetBrains Mono for every
  // technical string (counts, bitrates, server ids, timestamps).
  // ---------------------------------------------------------------------

  /// Screen title — "Home", "Library". Gabarito 800 at display size.
  static TextStyle get pageTitle => _gabarito(
    fontSize: 40,
    fontWeight: extraBold,
    letterSpacing: -0.8,
    height: 1.0,
  );

  /// Section heading inside a screen — "Recently added".
  static TextStyle get sectionTitle => _gabarito(
    fontSize: 30,
    fontWeight: extraBold,
    letterSpacing: -0.6,
    height: 1.1,
  );

  /// Compact section heading, used where a full [sectionTitle] would crowd
  /// the layout (mobile, side rails).
  static TextStyle get sectionTitleSmall => _gabarito(
    fontSize: 22,
    fontWeight: extraBold,
    letterSpacing: -0.22,
    height: 1.15,
  );

  /// All-caps mono label above a group — "SERVERS", "THIS WEEK".
  static TextStyle get eyebrow => _mono(
    fontSize: 10,
    fontWeight: semiBold,
    letterSpacing: 0.8,
    height: 1.4,
  );

  /// Sidebar / segmented-control label.
  static TextStyle get navLabel => _gabarito(
    fontSize: 13.5,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.2,
  );

  /// Glass button label — "Play", "Sync now".
  static TextStyle get glassButton =>
      _gabarito(fontSize: 13, fontWeight: bold, letterSpacing: 0, height: 1.2);

  /// Big number in a stat tile.
  static TextStyle get statValue => _gabarito(
    fontSize: 21,
    fontWeight: extraBold,
    letterSpacing: -0.2,
    height: 1.1,
  );

  /// Inline technical string — bitrate, server id, count, timestamp.
  static TextStyle get technical => _mono(
    fontSize: 10.5,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
  );

  // Button typography
  static TextStyle get buttonLarge => _manrope(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  static TextStyle get buttonMedium => _manrope(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  static TextStyle get buttonSmall => _manrope(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // Caption and overline
  static TextStyle get caption => _manrope(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static TextStyle get overline => _manrope(
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
  TextStyle get pageTitle => OmnisonicTypography.pageTitle;
  TextStyle get sectionTitle => OmnisonicTypography.sectionTitle;
  TextStyle get sectionTitleSmall => OmnisonicTypography.sectionTitleSmall;
  TextStyle get eyebrow => OmnisonicTypography.eyebrow;
  TextStyle get navLabel => OmnisonicTypography.navLabel;
  TextStyle get glassButton => OmnisonicTypography.glassButton;
  TextStyle get statValue => OmnisonicTypography.statValue;
  TextStyle get technical => OmnisonicTypography.technical;
  TextStyle get buttonLarge => OmnisonicTypography.buttonLarge;
  TextStyle get buttonMedium => OmnisonicTypography.buttonMedium;
  TextStyle get buttonSmall => OmnisonicTypography.buttonSmall;
  TextStyle get caption => OmnisonicTypography.caption;
  TextStyle get overline => OmnisonicTypography.overline;
}
