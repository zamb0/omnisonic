import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'icons.dart';
import 'animation_manager.dart';
import 'platform_theme_extensions.dart';

/// Main theme system for Omnisonic UI Enhancement
class OmnisonicTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: OmnisonicColors.lightColorScheme,
      textTheme: OmnisonicTypography.textTheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: OmnisonicElevation.appBar,
        centerTitle: true,
        backgroundColor: OmnisonicColors.lightColorScheme.surface,
        foregroundColor: OmnisonicColors.lightColorScheme.onSurface,
        titleTextStyle: OmnisonicTypography.titleLarge.copyWith(
          color: OmnisonicColors.lightColorScheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(OmnisonicRadius.md),
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        elevation: OmnisonicElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(OmnisonicRadius.card)),
        ),
        color: OmnisonicColors.surfaceLight,
        shadowColor: OmnisonicColors.neutralGray300,
        margin: EdgeInsets.all(OmnisonicSpacing.cardMargin),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: OmnisonicElevation.button,
          padding: OmnisonicInsets.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OmnisonicRadius.button),
          ),
          textStyle: OmnisonicTypography.buttonMedium,
          minimumSize: const Size(0, OmnisonicTouchTargets.button),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: OmnisonicInsets.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OmnisonicRadius.button),
          ),
          textStyle: OmnisonicTypography.buttonMedium,
          minimumSize: const Size(0, OmnisonicTouchTargets.button),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: OmnisonicInsets.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OmnisonicRadius.button),
          ),
          textStyle: OmnisonicTypography.buttonMedium,
          minimumSize: const Size(0, OmnisonicTouchTargets.button),
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            OmnisonicTouchTargets.iconButton,
            OmnisonicTouchTargets.iconButton,
          ),
          iconSize: OmnisonicIconSizes.medium,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: OmnisonicElevation.fab,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        ),
        iconSize: OmnisonicIconSizes.large,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: OmnisonicInsets.listItem,
        minVerticalPadding: OmnisonicSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        titleTextStyle: OmnisonicTypography.titleMedium,
        subtitleTextStyle: OmnisonicTypography.bodyMedium,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmnisonicColors.lightColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.lightColorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.lightColorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.lightColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.lightColorScheme.error,
          ),
        ),
        contentPadding: OmnisonicInsets.allMd,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: OmnisonicColors.lightColorScheme.surface,
        selectedColor: OmnisonicColors.lightColorScheme.primary,
        disabledColor: OmnisonicColors.lightColorScheme.outline,
        padding: OmnisonicInsets.horizontalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        ),
        labelStyle: OmnisonicTypography.labelMedium,
      ),
      
      // Dialog Theme
      dialogTheme: const DialogThemeData(
        elevation: OmnisonicElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(OmnisonicRadius.modal)),
        ),
        backgroundColor: OmnisonicColors.surfaceLight,
        titleTextStyle: OmnisonicTypography.headlineSmall,
        contentTextStyle: OmnisonicTypography.bodyMedium,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: OmnisonicElevation.modal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(OmnisonicRadius.modal),
          ),
        ),
        backgroundColor: OmnisonicColors.lightColorScheme.surface,
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: OmnisonicColors.lightColorScheme.primary,
        inactiveTrackColor: OmnisonicColors.lightColorScheme.outline,
        thumbColor: OmnisonicColors.lightColorScheme.primary,
        overlayColor: OmnisonicColors.lightColorScheme.primary.withValues(alpha: 0.2),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: OmnisonicColors.lightColorScheme.primary,
        linearTrackColor: OmnisonicColors.lightColorScheme.outline,
        circularTrackColor: OmnisonicColors.lightColorScheme.outline,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: OmnisonicColors.lightColorScheme.surface,
        selectedItemColor: OmnisonicColors.lightColorScheme.primary,
        unselectedItemColor: OmnisonicColors.lightColorScheme.onSurface.withValues(alpha: 0.6),
        selectedIconTheme: IconThemeData(
          color: OmnisonicColors.lightColorScheme.primary,
          size: OmnisonicIconSizes.navigation,
        ),
        unselectedIconTheme: IconThemeData(
          color: OmnisonicColors.lightColorScheme.onSurface.withValues(alpha: 0.6),
          size: OmnisonicIconSizes.navigation,
        ),
        selectedLabelStyle: OmnisonicTypography.labelSmall,
        unselectedLabelStyle: OmnisonicTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: OmnisonicElevation.appBar,
      ),
      
      // Extensions
      extensions: const [
        OmnisonicColorExtension.light,
        OmnisonicAnimationExtension(),
      ],
    );
    
    // Add platform-specific extensions
    return addPlatformExtensions(baseTheme);
  }
  
  /// Dark theme configuration
  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: OmnisonicColors.darkColorScheme,
      textTheme: OmnisonicTypography.textTheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: OmnisonicElevation.appBar,
        centerTitle: true,
        backgroundColor: OmnisonicColors.darkColorScheme.surface,
        foregroundColor: OmnisonicColors.darkColorScheme.onSurface,
        titleTextStyle: OmnisonicTypography.titleLarge.copyWith(
          color: OmnisonicColors.darkColorScheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(OmnisonicRadius.md),
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        elevation: OmnisonicElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(OmnisonicRadius.card)),
        ),
        color: OmnisonicColors.surfaceDark,
        shadowColor: OmnisonicColors.neutralGray800,
        margin: EdgeInsets.all(OmnisonicSpacing.cardMargin),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: OmnisonicElevation.button,
          padding: OmnisonicInsets.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OmnisonicRadius.button),
          ),
          textStyle: OmnisonicTypography.buttonMedium,
          minimumSize: const Size(0, OmnisonicTouchTargets.button),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: OmnisonicInsets.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OmnisonicRadius.button),
          ),
          textStyle: OmnisonicTypography.buttonMedium,
          minimumSize: const Size(0, OmnisonicTouchTargets.button),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: OmnisonicInsets.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OmnisonicRadius.button),
          ),
          textStyle: OmnisonicTypography.buttonMedium,
          minimumSize: const Size(0, OmnisonicTouchTargets.button),
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            OmnisonicTouchTargets.iconButton,
            OmnisonicTouchTargets.iconButton,
          ),
          iconSize: OmnisonicIconSizes.medium,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: OmnisonicElevation.fab,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        ),
        iconSize: OmnisonicIconSizes.large,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: OmnisonicInsets.listItem,
        minVerticalPadding: OmnisonicSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        titleTextStyle: OmnisonicTypography.titleMedium,
        subtitleTextStyle: OmnisonicTypography.bodyMedium,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmnisonicColors.darkColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.darkColorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.darkColorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.darkColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(
            color: OmnisonicColors.darkColorScheme.error,
          ),
        ),
        contentPadding: OmnisonicInsets.allMd,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: OmnisonicColors.darkColorScheme.surface,
        selectedColor: OmnisonicColors.darkColorScheme.primary,
        disabledColor: OmnisonicColors.darkColorScheme.outline,
        padding: OmnisonicInsets.horizontalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        ),
        labelStyle: OmnisonicTypography.labelMedium,
      ),
      
      // Dialog Theme
      dialogTheme: const DialogThemeData(
        elevation: OmnisonicElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(OmnisonicRadius.modal)),
        ),
        backgroundColor: OmnisonicColors.surfaceDark,
        titleTextStyle: OmnisonicTypography.headlineSmall,
        contentTextStyle: OmnisonicTypography.bodyMedium,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: OmnisonicElevation.modal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(OmnisonicRadius.modal),
          ),
        ),
        backgroundColor: OmnisonicColors.darkColorScheme.surface,
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: OmnisonicColors.darkColorScheme.primary,
        inactiveTrackColor: OmnisonicColors.darkColorScheme.outline,
        thumbColor: OmnisonicColors.darkColorScheme.primary,
        overlayColor: OmnisonicColors.darkColorScheme.primary.withValues(alpha: 0.2),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: OmnisonicColors.darkColorScheme.primary,
        linearTrackColor: OmnisonicColors.darkColorScheme.outline,
        circularTrackColor: OmnisonicColors.darkColorScheme.outline,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: OmnisonicColors.darkColorScheme.surface,
        selectedItemColor: OmnisonicColors.darkColorScheme.primary,
        unselectedItemColor: OmnisonicColors.darkColorScheme.onSurface.withValues(alpha: 0.6),
        selectedIconTheme: IconThemeData(
          color: OmnisonicColors.darkColorScheme.primary,
          size: OmnisonicIconSizes.navigation,
        ),
        unselectedIconTheme: IconThemeData(
          color: OmnisonicColors.darkColorScheme.onSurface.withValues(alpha: 0.6),
          size: OmnisonicIconSizes.navigation,
        ),
        selectedLabelStyle: OmnisonicTypography.labelSmall,
        unselectedLabelStyle: OmnisonicTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: OmnisonicElevation.appBar,
      ),
      
      // Extensions
      extensions: const [
        OmnisonicColorExtension.dark,
        OmnisonicAnimationExtension(),
      ],
    );
    
    // Add platform-specific extensions
    return addPlatformExtensions(baseTheme);
  }
}

/// Extension to easily access Omnisonic color extension from context
extension OmnisonicThemeExtension on BuildContext {
  OmnisonicColorExtension get omnisonicColors {
    return Theme.of(this).extension<OmnisonicColorExtension>() ??
        OmnisonicColorExtension.light;
  }
  
  OmnisonicAnimationExtension get omnisonicAnimations {
    return Theme.of(this).extension<OmnisonicAnimationExtension>() ??
        const OmnisonicAnimationExtension();
  }
  
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Music-specific color getters
  Color get playingIndicatorColor => omnisonicColors.playingIndicator ?? OmnisonicColors.playingIndicator;
  Color get pausedIndicatorColor => omnisonicColors.pausedIndicator ?? OmnisonicColors.pausedIndicator;
  Color get queueIndicatorColor => omnisonicColors.queueIndicator ?? OmnisonicColors.queueIndicator;
  Color get favoriteIndicatorColor => omnisonicColors.favoriteIndicator ?? OmnisonicColors.favoriteIndicator;
  
  // Gradient getters
  LinearGradient get primaryGradient => omnisonicColors.primaryGradient ?? OmnisonicColors.primaryGradient;
  LinearGradient get accentGradient => omnisonicColors.accentGradient ?? OmnisonicColors.accentGradient;
  LinearGradient get heroGradient => omnisonicColors.heroGradient ?? OmnisonicColors.heroGradient;
  LinearGradient get subtleGradient => omnisonicColors.subtleGradient ?? OmnisonicColors.subtleGradient;
  LinearGradient get primaryAnimatedGradient => omnisonicColors.primaryAnimatedGradient ?? OmnisonicColors.primaryAnimatedGradient;
  LinearGradient get accentAnimatedGradient => omnisonicColors.accentAnimatedGradient ?? OmnisonicColors.accentAnimatedGradient;
  RadialGradient get cardDepthGradient => omnisonicColors.cardDepthGradient ?? OmnisonicColors.cardDepthGradient;
  LinearGradient get shimmerGradient => omnisonicColors.shimmerGradient ?? OmnisonicColors.shimmerGradient;
  LinearGradient get glassMorphismGradient => omnisonicColors.glassMorphismGradient ?? OmnisonicColors.glassMorphismLight;
  LinearGradient get nowPlayingGradient => omnisonicColors.nowPlayingGradient ?? OmnisonicColors.nowPlayingGradient;
  LinearGradient get albumArtOverlay => omnisonicColors.albumArtOverlay ?? OmnisonicColors.albumArtOverlay;
  LinearGradient get progressBarGradient => omnisonicColors.progressBarGradient ?? OmnisonicColors.progressBarGradient;
  
  // Animation getters
  Duration get fastAnimationDuration => omnisonicAnimations.fastDuration;
  Duration get normalAnimationDuration => omnisonicAnimations.normalDuration;
  Duration get slowAnimationDuration => omnisonicAnimations.slowDuration;
  Curve get standardAnimationCurve => omnisonicAnimations.standardCurve;
  Curve get fastAnimationCurve => omnisonicAnimations.fastCurve;
  Curve get slowAnimationCurve => omnisonicAnimations.slowCurve;
  bool get enableMicroInteractions => omnisonicAnimations.enableMicroInteractions;
  bool get enablePageTransitions => omnisonicAnimations.enablePageTransitions;
  bool get enableLoadingAnimations => omnisonicAnimations.enableLoadingAnimations;
  double get animationScale => omnisonicAnimations.animationScale;
}