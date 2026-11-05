import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'icons.dart';
import 'surfaces.dart';
import 'brand.dart';
import 'slider_thumb.dart';

/// The app's [ThemeData], light and dark.
///
/// Both themes come from one builder over a [ColorScheme] and its
/// [OmnisonicSurfaces], so a component cannot be styled in one brightness
/// and forgotten in the other — the two hand-copied 270-line halves this
/// replaced had already drifted. The rules it encodes are in
/// `docs/design-system.md` §9: ink for the primary action, the accent only
/// for live state, stadium buttons, opaque overlays.
class OmnisonicTheme {
  static ThemeData get lightTheme => _build(
    OmnisonicColors.lightColorScheme,
    OmnisonicSurfaces.light,
    OmnisonicBrand.light,
  );

  static ThemeData get darkTheme => _build(
    OmnisonicColors.darkColorScheme,
    OmnisonicSurfaces.dark,
    OmnisonicBrand.dark,
  );

  static ThemeData _build(
    ColorScheme scheme,
    OmnisonicSurfaces surfaces,
    OmnisonicBrand brand,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    const stadium = StadiumBorder();
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(OmnisonicRadius.control),
    );
    final overlayShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(OmnisonicRadius.overlay),
      side: BorderSide(color: surfaces.hairline),
    );
    final button = OmnisonicTypography.button;
    const buttonPadding = EdgeInsets.symmetric(horizontal: OmnisonicSpacing.ml);
    const buttonSize = Size(64, OmnisonicTouchTargets.minimum);

    // Hover, focus and press washes over any control, in the colour of its
    // foreground so they read on ink and on glass alike.
    WidgetStateProperty<Color?> overlayOn(Color foreground) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return foreground.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.focused)) {
            return foreground.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return foreground.withValues(alpha: 0.08);
          }
          return null;
        });

    // The keyboard focus ring: the accent, because focus is live state.
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>(
      (states) => states.contains(WidgetState.focused)
          ? BorderSide(color: scheme.primary, width: 2)
          : null,
    );

    InputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      extensions: [surfaces, brand],
      textTheme: OmnisonicTypography.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      hoverColor: scheme.onSurface.withValues(alpha: 0.06),
      focusColor: scheme.primary.withValues(alpha: 0.16),
      highlightColor: scheme.onSurface.withValues(alpha: 0.08),
      dividerColor: surfaces.hairline,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: OmnisonicTypography.overlayTitle.copyWith(
          color: scheme.onSurface,
        ),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
          side: BorderSide(color: surfaces.hairline),
        ),
        color: surfaces.well,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Buttons: one stadium, one label style, one height. Primary is ink,
      // not the accent — the accent means "live", a button is not.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.12)
                : surfaces.ink,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : surfaces.onInk,
          ),
          overlayColor: overlayOn(surfaces.onInk),
          textStyle: WidgetStatePropertyAll(button),
          padding: const WidgetStatePropertyAll(buttonPadding),
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: const WidgetStatePropertyAll(stadium),
          side: focusSide,
          elevation: const WidgetStatePropertyAll(0),
          iconSize: const WidgetStatePropertyAll(OmnisonicIconSizes.smd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: surfaces.well,
          foregroundColor: scheme.onSurface,
          padding: buttonPadding,
          minimumSize: buttonSize,
          shape: stadium,
          textStyle: button,
        ).copyWith(side: focusSide),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurface,
          ),
          overlayColor: overlayOn(scheme.onSurface),
          textStyle: WidgetStatePropertyAll(button),
          padding: const WidgetStatePropertyAll(buttonPadding),
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: const WidgetStatePropertyAll(stadium),
          iconSize: const WidgetStatePropertyAll(OmnisonicIconSizes.smd),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide(color: scheme.outline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurface,
          ),
          overlayColor: overlayOn(scheme.onSurface),
          textStyle: WidgetStatePropertyAll(button),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
          ),
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: const WidgetStatePropertyAll(stadium),
          iconSize: const WidgetStatePropertyAll(OmnisonicIconSizes.smd),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(OmnisonicTouchTargets.minimum),
          ),
          iconSize: const WidgetStatePropertyAll(OmnisonicIconSizes.smd),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return scheme.onSurface;
          }),
          overlayColor: overlayOn(scheme.onSurface),
          side: focusSide,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14)
                : surfaces.well,
          ),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          textStyle: WidgetStatePropertyAll(OmnisonicTypography.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: surfaces.hairline)),
          shape: const WidgetStatePropertyAll(stadium),
          minimumSize: const WidgetStatePropertyAll(buttonSize),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: surfaces.ink,
        foregroundColor: surfaces.onInk,
        shape: stadium,
        extendedTextStyle: button,
        iconSize: OmnisonicIconSizes.md,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.md,
        ),
        minVerticalPadding: OmnisonicSpacing.sm,
        minTileHeight: 56,
        horizontalTitleGap: OmnisonicSpacing.ms,
        shape: controlShape,
        titleTextStyle: OmnisonicTypography.titleMedium.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: OmnisonicTypography.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: OmnisonicTypography.technical.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        selectedColor: scheme.onSurface,
        selectedTileColor: surfaces.wellHover,
      ),

      // Inputs are wells: recessed into whatever glass they sit on, edged by
      // the hairline, ringed with the accent while focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.well,
        hoverColor: surfaces.wellHover,
        // A field's edge is what says "type here": 3:1 or better against the
        // canvas it sits on (`outline`), not the decorative hairline.
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        disabledBorder: inputBorder(surfaces.hairline),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.md,
          vertical: OmnisonicSpacing.md,
        ),
        labelStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        helperStyle: OmnisonicTypography.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: OmnisonicTypography.bodySmall.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),

      // A selected chip is a toggle that is on: live state, so the accent —
      // `primaryContainer` with a 1 px `primary` edge *and* a check, so the
      // state survives greyscale.
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.well,
        selectedColor: scheme.primaryContainer,
        disabledColor: surfaces.well,
        checkmarkColor: scheme.primary,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : surfaces.hairline,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.sm,
          vertical: OmnisonicSpacing.xs,
        ),
        shape: stadium,
        labelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: OmnisonicTypography.labelMedium.copyWith(
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: scheme.onSurface,
          size: OmnisonicIconSizes.sm,
        ),
        showCheckmark: true,
      ),

      // Overlays are opaque, one step up the container ladder, with a
      // hairline edge instead of a Material elevation tint.
      dialogTheme: DialogThemeData(
        // Opaque, hairline-edged, lifted by a deep shadow rather than a
        // Material tint. 440 is as wide as a dialog gets.
        elevation: 24,
        shadowColor: OmnisonicColors.overlayShadow,
        constraints: const BoxConstraints(maxWidth: 440),
        shape: overlayShape,
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: OmnisonicTypography.overlayTitle.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.lg,
          vertical: OmnisonicSpacing.lg,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          OmnisonicSpacing.lg,
          0,
          OmnisonicSpacing.lg,
          OmnisonicSpacing.lg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(OmnisonicRadius.overlay),
          ),
          side: BorderSide(color: surfaces.hairline),
        ),
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(36, 4),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(16),
          shadowColor: const WidgetStatePropertyAll(
            OmnisonicColors.overlayShadow,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OmnisonicRadius.control),
              side: BorderSide(color: surfaces.hairline),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.all(OmnisonicSpacing.xs),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(OmnisonicTypography.titleSmall),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          iconColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
          // Hover and keyboard focus are the `well`; a press is one step
          // up. (On L3 the usual onSurface wash read as grey.)
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return surfaces.wellHover;
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return surfaces.well;
            }
            return null;
          }),
          minimumSize: const WidgetStatePropertyAll(
            Size(180, OmnisonicTouchTargets.minimum),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: OmnisonicSpacing.ms),
          ),
          shape: WidgetStatePropertyAll(controlShape),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: OmnisonicColors.overlayShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.control),
          side: BorderSide(color: surfaces.hairline),
        ),
        textStyle: OmnisonicTypography.titleSmall.copyWith(
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: surfaces.hairline,
        thickness: 1,
        space: OmnisonicSpacing.md,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: OmnisonicTypography.bodyMedium.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.control),
        ),
        insetPadding: const EdgeInsets.all(OmnisonicSpacing.md),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        textStyle: OmnisonicTypography.bodySmall.copyWith(
          color: scheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.sm,
          vertical: OmnisonicSpacing.xs,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        selectionHandleColor: scheme.primary,
      ),
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: OmnisonicIconSizes.md,
      ),
      primaryIconTheme: IconThemeData(
        color: scheme.onPrimary,
        size: OmnisonicIconSizes.md,
      ),

      // Live state: the accent.
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        // 14 px thumb that grows to 18 under the finger.
        thumbShape: const GrowingThumbShape(),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.onSurface.withValues(alpha: 0.12),
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
        borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        // Off: the top rung of the container ladder, readable on glass, with
        // the `outline` edge below; on: the accent.
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: OmnisonicTypography.navLabel,
        unselectedLabelStyle: OmnisonicTypography.navLabel,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.onSurface,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: surfaces.hairline,
        overlayColor: overlayOn(scheme.onSurface),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: scheme.onSurface,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: OmnisonicTypography.labelSmall,
        unselectedLabelStyle: OmnisonicTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: surfaces.ink,
        labelTextStyle: WidgetStatePropertyAll(
          OmnisonicTypography.labelSmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: OmnisonicIconSizes.md,
            color: states.contains(WidgetState.selected)
                ? surfaces.onInk
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
