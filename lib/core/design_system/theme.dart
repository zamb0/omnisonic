import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'icons.dart';

/// Main theme system for Omnisonic UI Enhancement
class OmnisonicTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: OmnisonicColors.lightColorScheme,
      textTheme: OmnisonicTypography.textTheme.apply(
        bodyColor: OmnisonicColors.lightColorScheme.onSurface,
        displayColor: OmnisonicColors.lightColorScheme.onSurface,
      ),
      scaffoldBackgroundColor: OmnisonicColors.lightColorScheme.surface,
      canvasColor: OmnisonicColors.lightColorScheme.surface,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: OmnisonicElevation.appBar,
        centerTitle: true,
        backgroundColor: OmnisonicColors.lightColorScheme.surface,
        foregroundColor: OmnisonicColors.lightColorScheme.onSurface,
        titleTextStyle: OmnisonicTypography.titleLarge.copyWith(
          color: OmnisonicColors.lightColorScheme.onSurface,
        ),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(OmnisonicRadius.card)),
        ),
        color: OmnisonicColors.cardLight,
        shadowColor: Colors.transparent,
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
          iconSize: OmnisonicIconSizes.md,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: OmnisonicElevation.fab,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        ),
        iconSize: OmnisonicIconSizes.lg,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        // Horizontal only: ListTile already enforces its own minimum height,
        // and vertical padding here added 32pt on top of it.
        contentPadding: OmnisonicInsets.horizontalMd,
        minVerticalPadding: OmnisonicSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        titleTextStyle: OmnisonicTypography.titleMedium,
        subtitleTextStyle: OmnisonicTypography.bodyMedium,
        textColor: OmnisonicColors.lightColorScheme.onSurface,
        iconColor: OmnisonicColors.lightColorScheme.onSurfaceVariant,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmnisonicColors.lightColorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: OmnisonicColors.lightColorScheme.error),
        ),
        contentPadding: OmnisonicInsets.allMd,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: OmnisonicColors.lightColorScheme.surface,
        selectedColor: OmnisonicColors.lightColorScheme.secondaryContainer,
        disabledColor: OmnisonicColors.lightColorScheme.outline,
        padding: OmnisonicInsets.horizontalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        ),
        labelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: OmnisonicColors.lightColorScheme.onSurface,
        ),
        secondaryLabelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: OmnisonicColors.lightColorScheme.onSecondaryContainer,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: OmnisonicElevation.modal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(OmnisonicRadius.modal),
          ),
        ),
        backgroundColor: OmnisonicColors.surfaceLight,
        // Explicit colours: without them the title inherits the ambient
        // DefaultTextStyle, which is light-on-light in the light theme.
        titleTextStyle: OmnisonicTypography.headlineSmall.copyWith(
          color: OmnisonicColors.lightColorScheme.onSurface,
        ),
        contentTextStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: OmnisonicColors.lightColorScheme.onSurfaceVariant,
        ),
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
      dividerTheme: DividerThemeData(
        color: OmnisonicColors.lightColorScheme.outlineVariant,
        thickness: 1,
        space: OmnisonicSpacing.md,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OmnisonicColors.lightColorScheme.inverseSurface,
        contentTextStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: OmnisonicColors.lightColorScheme.onInverseSurface,
        ),
        actionTextColor: OmnisonicColors.lightColorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: OmnisonicColors.lightColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        textStyle: OmnisonicTypography.bodySmall.copyWith(
          color: OmnisonicColors.lightColorScheme.onInverseSurface,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: OmnisonicColors.lightColorScheme.primary,
        selectionColor: OmnisonicColors.lightColorScheme.primary.withValues(
          alpha: 0.2,
        ),
        selectionHandleColor: OmnisonicColors.lightColorScheme.primary,
      ),
      iconTheme: IconThemeData(
        color: OmnisonicColors.lightColorScheme.onSurface,
        size: OmnisonicIconSizes.md,
      ),
      primaryIconTheme: IconThemeData(
        color: OmnisonicColors.lightColorScheme.onPrimary,
        size: OmnisonicIconSizes.md,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: OmnisonicColors.lightColorScheme.primary,
        inactiveTrackColor: OmnisonicColors.lightColorScheme.outline,
        thumbColor: OmnisonicColors.lightColorScheme.primary,
        overlayColor: OmnisonicColors.lightColorScheme.primary.withValues(
          alpha: 0.2,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: OmnisonicColors.lightColorScheme.primary,
        linearTrackColor: OmnisonicColors.lightColorScheme.outline,
        circularTrackColor: OmnisonicColors.lightColorScheme.outline,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            OmnisonicColors.lightColorScheme.surfaceContainerHighest,
        selectedItemColor: OmnisonicColors.lightColorScheme.primary,
        unselectedItemColor: OmnisonicColors.lightColorScheme.onSurfaceVariant,
        selectedIconTheme: IconThemeData(
          color: OmnisonicColors.lightColorScheme.primary,
          size: OmnisonicIconSizes.md,
        ),
        unselectedIconTheme: IconThemeData(
          color: OmnisonicColors.lightColorScheme.onSurfaceVariant,
          size: OmnisonicIconSizes.md,
        ),
        selectedLabelStyle: OmnisonicTypography.labelSmall,
        unselectedLabelStyle: OmnisonicTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: OmnisonicElevation.appBar,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            OmnisonicColors.lightColorScheme.surfaceContainerHighest,
        indicatorColor: OmnisonicColors.lightColorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          OmnisonicTypography.labelSmall.copyWith(
            color: OmnisonicColors.lightColorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(
            size: OmnisonicIconSizes.md,
            color: OmnisonicColors.lightColorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: OmnisonicColors.darkColorScheme,
      textTheme: OmnisonicTypography.textTheme.apply(
        bodyColor: OmnisonicColors.darkColorScheme.onSurface,
        displayColor: OmnisonicColors.darkColorScheme.onSurface,
      ),
      scaffoldBackgroundColor: OmnisonicColors.darkColorScheme.surface,
      canvasColor: OmnisonicColors.darkColorScheme.surface,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: OmnisonicElevation.appBar,
        centerTitle: true,
        backgroundColor: OmnisonicColors.darkColorScheme.surface,
        foregroundColor: OmnisonicColors.darkColorScheme.onSurface,
        titleTextStyle: OmnisonicTypography.titleLarge.copyWith(
          color: OmnisonicColors.darkColorScheme.onSurface,
        ),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(OmnisonicRadius.card)),
        ),
        color: OmnisonicColors.cardDark,
        shadowColor: Colors.transparent,
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
          iconSize: OmnisonicIconSizes.md,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: OmnisonicElevation.fab,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        ),
        iconSize: OmnisonicIconSizes.lg,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        // Horizontal only: ListTile already enforces its own minimum height,
        // and vertical padding here added 32pt on top of it.
        contentPadding: OmnisonicInsets.horizontalMd,
        minVerticalPadding: OmnisonicSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        titleTextStyle: OmnisonicTypography.titleMedium,
        subtitleTextStyle: OmnisonicTypography.bodyMedium,
        textColor: OmnisonicColors.darkColorScheme.onSurface,
        iconColor: OmnisonicColors.darkColorScheme.onSurfaceVariant,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmnisonicColors.darkColorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: OmnisonicColors.darkColorScheme.error),
        ),
        contentPadding: OmnisonicInsets.allMd,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: OmnisonicColors.darkColorScheme.surface,
        selectedColor: OmnisonicColors.darkColorScheme.secondaryContainer,
        disabledColor: OmnisonicColors.darkColorScheme.outline,
        padding: OmnisonicInsets.horizontalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        ),
        labelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: OmnisonicColors.darkColorScheme.onSurface,
        ),
        secondaryLabelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: OmnisonicColors.darkColorScheme.onSecondaryContainer,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: OmnisonicElevation.modal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(OmnisonicRadius.modal),
          ),
        ),
        backgroundColor: OmnisonicColors.surfaceDark,
        // Explicit colours: without them the title inherits the ambient
        // DefaultTextStyle, which is light-on-light in the light theme.
        titleTextStyle: OmnisonicTypography.headlineSmall.copyWith(
          color: OmnisonicColors.darkColorScheme.onSurface,
        ),
        contentTextStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: OmnisonicColors.darkColorScheme.onSurfaceVariant,
        ),
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
      dividerTheme: DividerThemeData(
        color: OmnisonicColors.darkColorScheme.outlineVariant,
        thickness: 1,
        space: OmnisonicSpacing.md,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OmnisonicColors.darkColorScheme.inverseSurface,
        contentTextStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: OmnisonicColors.darkColorScheme.onInverseSurface,
        ),
        actionTextColor: OmnisonicColors.darkColorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: OmnisonicColors.darkColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        textStyle: OmnisonicTypography.bodySmall.copyWith(
          color: OmnisonicColors.darkColorScheme.onInverseSurface,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: OmnisonicColors.darkColorScheme.primary,
        selectionColor: OmnisonicColors.darkColorScheme.primary.withValues(
          alpha: 0.25,
        ),
        selectionHandleColor: OmnisonicColors.darkColorScheme.primary,
      ),
      iconTheme: IconThemeData(
        color: OmnisonicColors.darkColorScheme.onSurface,
        size: OmnisonicIconSizes.md,
      ),
      primaryIconTheme: IconThemeData(
        color: OmnisonicColors.darkColorScheme.onPrimary,
        size: OmnisonicIconSizes.md,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: OmnisonicColors.darkColorScheme.primary,
        inactiveTrackColor: OmnisonicColors.darkColorScheme.outline,
        thumbColor: OmnisonicColors.darkColorScheme.primary,
        overlayColor: OmnisonicColors.darkColorScheme.primary.withValues(
          alpha: 0.2,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: OmnisonicColors.darkColorScheme.primary,
        linearTrackColor: OmnisonicColors.darkColorScheme.outline,
        circularTrackColor: OmnisonicColors.darkColorScheme.outline,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            OmnisonicColors.darkColorScheme.surfaceContainerHighest,
        selectedItemColor: OmnisonicColors.darkColorScheme.primary,
        unselectedItemColor: OmnisonicColors.darkColorScheme.onSurfaceVariant,
        selectedIconTheme: IconThemeData(
          color: OmnisonicColors.darkColorScheme.primary,
          size: OmnisonicIconSizes.md,
        ),
        unselectedIconTheme: IconThemeData(
          color: OmnisonicColors.darkColorScheme.onSurfaceVariant,
          size: OmnisonicIconSizes.md,
        ),
        selectedLabelStyle: OmnisonicTypography.labelSmall,
        unselectedLabelStyle: OmnisonicTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: OmnisonicElevation.appBar,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            OmnisonicColors.darkColorScheme.surfaceContainerHighest,
        indicatorColor: OmnisonicColors.darkColorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          OmnisonicTypography.labelSmall.copyWith(
            color: OmnisonicColors.darkColorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(
            size: OmnisonicIconSizes.md,
            color: OmnisonicColors.darkColorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
