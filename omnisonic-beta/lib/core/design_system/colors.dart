import 'package:flutter/material.dart';

/// Comprehensive color palette system for Omnisonic UI Enhancement
class OmnisonicColors {
  // Primary Brand Colors
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryTeal = Color(0xFF06B6D4);
  
  // Secondary Colors
  static const Color secondaryIndigo = Color(0xFF4F46E5);
  static const Color secondaryViolet = Color(0xFF7C3AED);
  static const Color secondaryCyan = Color(0xFF0891B2);
  
  // Accent Colors
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFF059669);
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
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
  
  // Surface Colors - Light Mode
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color onSurfaceLight = Color(0xFF1F2937);
  static const Color onBackgroundLight = Color(0xFF111827);

  // Container Colors - Light Mode
  static const Color primaryContainerLight = Color(0xFFE0E7FF);
  static const Color onPrimaryContainerLight = Color(0xFF1E1B3A);
  static const Color secondaryContainerLight = Color(0xFFEDE9FE);
  static const Color onSecondaryContainerLight = Color(0xFF2E1065);
  static const Color tertiaryContainerLight = Color(0xFFCFFAFE);
  static const Color onTertiaryContainerLight = Color(0xFF003544);
  static const Color errorContainerLight = Color(0xFFFEE2E2);
  static const Color onErrorContainerLight = Color(0xFF7F1D1D);
  
  // Surface Colors - Dark Mode
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color onSurfaceDark = Color(0xFFE5E7EB);
  static const Color onBackgroundDark = Color(0xFFF9FAFB);

  // Container Colors - Dark Mode
  static const Color primaryContainerDark = Color(0xFF2A2F6B);
  static const Color onPrimaryContainerDark = Color(0xFFE0E7FF);
  static const Color secondaryContainerDark = Color(0xFF2E2C6B);
  static const Color onSecondaryContainerDark = Color(0xFFEDE9FE);
  static const Color tertiaryContainerDark = Color(0xFF003B4D);
  static const Color onTertiaryContainerDark = Color(0xFFCFFAFE);
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
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkSubtleGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
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
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    center: Alignment.topLeft,
    radius: 1.5,
  );
  
  static const RadialGradient darkCardDepthGradient = RadialGradient(
    colors: [Color(0xFF2D2D2D), Color(0xFF1E1E1E)],
    center: Alignment.topLeft,
    radius: 1.5,
  );
  
  // Shimmer gradients for loading states
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE2E8F0),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );
  
  static const LinearGradient darkShimmerGradient = LinearGradient(
    colors: [
      Color(0xFF374151),
      Color(0xFF4B5563),
      Color(0xFF374151),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );
  
  // Glass morphism gradients
  static const LinearGradient glassMorphismLight = LinearGradient(
    colors: [
      Color(0x40FFFFFF),
      Color(0x20FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassMorphismDark = LinearGradient(
    colors: [
      Color(0x40000000),
      Color(0x20000000),
    ],
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
    colors: [
      Color(0x00000000),
      Color(0x80000000),
    ],
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
    primary: primaryPurple,
    onPrimary: neutralWhite,
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: onPrimaryContainerLight,
    secondary: secondaryIndigo,
    onSecondary: neutralWhite,
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: onSecondaryContainerLight,
    tertiary: primaryTeal,
    onTertiary: neutralWhite,
    tertiaryContainer: tertiaryContainerLight,
    onTertiaryContainer: onTertiaryContainerLight,
    error: error,
    onError: neutralWhite,
    errorContainer: errorContainerLight,
    onErrorContainer: onErrorContainerLight,
    background: backgroundLight,
    onBackground: onBackgroundLight,
    surface: surfaceLight,
    onSurface: onSurfaceLight,
    surfaceVariant: neutralGray100,
    onSurfaceVariant: neutralGray700,
    outline: neutralGray300,
    outlineVariant: neutralGray200,
    shadow: Color(0x1A000000),
    scrim: Color(0x80000000),
    inverseSurface: neutralGray800,
    onInverseSurface: neutralGray100,
    inversePrimary: Color(0xFF9CA3FF),
    surfaceTint: primaryPurple,
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
    background: backgroundDark,
    onBackground: onBackgroundDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceVariant: neutralGray800,
    onSurfaceVariant: neutralGray300,
    outline: neutralGray600,
    outlineVariant: neutralGray700,
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
  
  // Status colors with opacity variants
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  static const Color successDark = Color(0xFF064E3B);
  static const Color warningDark = Color(0xFF78350F);
  static const Color errorDark = Color(0xFF7F1D1D);
  static const Color infoDark = Color(0xFF1E3A8A);
}

/// Extension for custom colors in theme
class OmnisonicColorExtension extends ThemeExtension<OmnisonicColorExtension> {
  final Color? playingIndicator;
  final Color? pausedIndicator;
  final Color? queueIndicator;
  final Color? favoriteIndicator;
  final LinearGradient? primaryGradient;
  final LinearGradient? accentGradient;
  final LinearGradient? heroGradient;
  final LinearGradient? subtleGradient;
  final LinearGradient? primaryAnimatedGradient;
  final LinearGradient? accentAnimatedGradient;
  final RadialGradient? cardDepthGradient;
  final LinearGradient? shimmerGradient;
  final LinearGradient? glassMorphismGradient;
  final LinearGradient? nowPlayingGradient;
  final LinearGradient? albumArtOverlay;
  final LinearGradient? progressBarGradient;
  
  const OmnisonicColorExtension({
    this.playingIndicator,
    this.pausedIndicator,
    this.queueIndicator,
    this.favoriteIndicator,
    this.primaryGradient,
    this.accentGradient,
    this.heroGradient,
    this.subtleGradient,
    this.primaryAnimatedGradient,
    this.accentAnimatedGradient,
    this.cardDepthGradient,
    this.shimmerGradient,
    this.glassMorphismGradient,
    this.nowPlayingGradient,
    this.albumArtOverlay,
    this.progressBarGradient,
  });
  
  static const OmnisonicColorExtension light = OmnisonicColorExtension(
    playingIndicator: OmnisonicColors.playingIndicator,
    pausedIndicator: OmnisonicColors.pausedIndicator,
    queueIndicator: OmnisonicColors.queueIndicator,
    favoriteIndicator: OmnisonicColors.favoriteIndicator,
    primaryGradient: OmnisonicColors.primaryGradient,
    accentGradient: OmnisonicColors.accentGradient,
    heroGradient: OmnisonicColors.heroGradient,
    subtleGradient: OmnisonicColors.subtleGradient,
    primaryAnimatedGradient: OmnisonicColors.primaryAnimatedGradient,
    accentAnimatedGradient: OmnisonicColors.accentAnimatedGradient,
    cardDepthGradient: OmnisonicColors.cardDepthGradient,
    shimmerGradient: OmnisonicColors.shimmerGradient,
    glassMorphismGradient: OmnisonicColors.glassMorphismLight,
    nowPlayingGradient: OmnisonicColors.nowPlayingGradient,
    albumArtOverlay: OmnisonicColors.albumArtOverlay,
    progressBarGradient: OmnisonicColors.progressBarGradient,
  );
  
  static const OmnisonicColorExtension dark = OmnisonicColorExtension(
    playingIndicator: OmnisonicColors.playingIndicator,
    pausedIndicator: OmnisonicColors.pausedIndicator,
    queueIndicator: OmnisonicColors.queueIndicator,
    favoriteIndicator: OmnisonicColors.favoriteIndicator,
    primaryGradient: OmnisonicColors.primaryGradient,
    accentGradient: OmnisonicColors.accentGradient,
    heroGradient: OmnisonicColors.heroGradient,
    subtleGradient: OmnisonicColors.darkSubtleGradient,
    primaryAnimatedGradient: OmnisonicColors.primaryAnimatedGradient,
    accentAnimatedGradient: OmnisonicColors.accentAnimatedGradient,
    cardDepthGradient: OmnisonicColors.darkCardDepthGradient,
    shimmerGradient: OmnisonicColors.darkShimmerGradient,
    glassMorphismGradient: OmnisonicColors.glassMorphismDark,
    nowPlayingGradient: OmnisonicColors.nowPlayingGradient,
    albumArtOverlay: OmnisonicColors.albumArtOverlay,
    progressBarGradient: OmnisonicColors.progressBarGradient,
  );
  
  @override
  ThemeExtension<OmnisonicColorExtension> copyWith({
    Color? playingIndicator,
    Color? pausedIndicator,
    Color? queueIndicator,
    Color? favoriteIndicator,
    LinearGradient? primaryGradient,
    LinearGradient? accentGradient,
    LinearGradient? heroGradient,
    LinearGradient? subtleGradient,
    LinearGradient? primaryAnimatedGradient,
    LinearGradient? accentAnimatedGradient,
    RadialGradient? cardDepthGradient,
    LinearGradient? shimmerGradient,
    LinearGradient? glassMorphismGradient,
    LinearGradient? nowPlayingGradient,
    LinearGradient? albumArtOverlay,
    LinearGradient? progressBarGradient,
  }) {
    return OmnisonicColorExtension(
      playingIndicator: playingIndicator ?? this.playingIndicator,
      pausedIndicator: pausedIndicator ?? this.pausedIndicator,
      queueIndicator: queueIndicator ?? this.queueIndicator,
      favoriteIndicator: favoriteIndicator ?? this.favoriteIndicator,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      subtleGradient: subtleGradient ?? this.subtleGradient,
      primaryAnimatedGradient: primaryAnimatedGradient ?? this.primaryAnimatedGradient,
      accentAnimatedGradient: accentAnimatedGradient ?? this.accentAnimatedGradient,
      cardDepthGradient: cardDepthGradient ?? this.cardDepthGradient,
      shimmerGradient: shimmerGradient ?? this.shimmerGradient,
      glassMorphismGradient: glassMorphismGradient ?? this.glassMorphismGradient,
      nowPlayingGradient: nowPlayingGradient ?? this.nowPlayingGradient,
      albumArtOverlay: albumArtOverlay ?? this.albumArtOverlay,
      progressBarGradient: progressBarGradient ?? this.progressBarGradient,
    );
  }
  
  @override
  ThemeExtension<OmnisonicColorExtension> lerp(
    ThemeExtension<OmnisonicColorExtension>? other,
    double t,
  ) {
    if (other is! OmnisonicColorExtension) {
      return this;
    }
    
    return OmnisonicColorExtension(
      playingIndicator: Color.lerp(playingIndicator, other.playingIndicator, t),
      pausedIndicator: Color.lerp(pausedIndicator, other.pausedIndicator, t),
      queueIndicator: Color.lerp(queueIndicator, other.queueIndicator, t),
      favoriteIndicator: Color.lerp(favoriteIndicator, other.favoriteIndicator, t),
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t),
      accentGradient: LinearGradient.lerp(accentGradient, other.accentGradient, t),
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t),
      subtleGradient: LinearGradient.lerp(subtleGradient, other.subtleGradient, t),
      primaryAnimatedGradient: LinearGradient.lerp(primaryAnimatedGradient, other.primaryAnimatedGradient, t),
      accentAnimatedGradient: LinearGradient.lerp(accentAnimatedGradient, other.accentAnimatedGradient, t),
      cardDepthGradient: RadialGradient.lerp(cardDepthGradient, other.cardDepthGradient, t),
      shimmerGradient: LinearGradient.lerp(shimmerGradient, other.shimmerGradient, t),
      glassMorphismGradient: LinearGradient.lerp(glassMorphismGradient, other.glassMorphismGradient, t),
      nowPlayingGradient: LinearGradient.lerp(nowPlayingGradient, other.nowPlayingGradient, t),
      albumArtOverlay: LinearGradient.lerp(albumArtOverlay, other.albumArtOverlay, t),
      progressBarGradient: LinearGradient.lerp(progressBarGradient, other.progressBarGradient, t),
    );
  }
}