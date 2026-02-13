import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import 'platform_optimizations.dart';
import 'platform_animations.dart';

/// Platform-specific theme extensions
@immutable
class PlatformThemeExtension extends ThemeExtension<PlatformThemeExtension> {
  final double touchTargetSize;
  final double borderRadius;
  final double elevation;
  final ScrollPhysics scrollPhysics;
  final PageTransitionsBuilder pageTransitionsBuilder;
  final PlatformAnimationDurations animationDurations;
  final PlatformAnimationCurves animationCurves;
  final bool supportsHover;
  final bool supportsHaptics;
  final MouseCursor interactiveCursor;

  const PlatformThemeExtension({
    required this.touchTargetSize,
    required this.borderRadius,
    required this.elevation,
    required this.scrollPhysics,
    required this.pageTransitionsBuilder,
    required this.animationDurations,
    required this.animationCurves,
    required this.supportsHover,
    required this.supportsHaptics,
    required this.interactiveCursor,
  });

  /// Create platform-specific theme extension
  factory PlatformThemeExtension.forCurrentPlatform() {
    final platform = PlatformOptimizations();
    final animations = PlatformAnimations();
    
    return PlatformThemeExtension(
      touchTargetSize: platform.touchTargetSize,
      borderRadius: platform.defaultBorderRadius,
      elevation: platform.defaultElevation,
      scrollPhysics: platform.scrollPhysics,
      pageTransitionsBuilder: animations.pageTransitionBuilder,
      animationDurations: animations.durations,
      animationCurves: animations.curves,
      supportsHover: platform.supportsHover,
      supportsHaptics: platform.supportsHaptics,
      interactiveCursor: platform.interactiveCursor,
    );
  }

  @override
  PlatformThemeExtension copyWith({
    double? touchTargetSize,
    double? borderRadius,
    double? elevation,
    ScrollPhysics? scrollPhysics,
    PageTransitionsBuilder? pageTransitionsBuilder,
    PlatformAnimationDurations? animationDurations,
    PlatformAnimationCurves? animationCurves,
    bool? supportsHover,
    bool? supportsHaptics,
    MouseCursor? interactiveCursor,
  }) {
    return PlatformThemeExtension(
      touchTargetSize: touchTargetSize ?? this.touchTargetSize,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      pageTransitionsBuilder: pageTransitionsBuilder ?? this.pageTransitionsBuilder,
      animationDurations: animationDurations ?? this.animationDurations,
      animationCurves: animationCurves ?? this.animationCurves,
      supportsHover: supportsHover ?? this.supportsHover,
      supportsHaptics: supportsHaptics ?? this.supportsHaptics,
      interactiveCursor: interactiveCursor ?? this.interactiveCursor,
    );
  }

  @override
  PlatformThemeExtension lerp(PlatformThemeExtension? other, double t) {
    if (other is! PlatformThemeExtension) {
      return this;
    }
    
    return PlatformThemeExtension(
      touchTargetSize: lerpDouble(touchTargetSize, other.touchTargetSize, t) ?? touchTargetSize,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t) ?? borderRadius,
      elevation: lerpDouble(elevation, other.elevation, t) ?? elevation,
      scrollPhysics: t < 0.5 ? scrollPhysics : other.scrollPhysics,
      pageTransitionsBuilder: t < 0.5 ? pageTransitionsBuilder : other.pageTransitionsBuilder,
      animationDurations: t < 0.5 ? animationDurations : other.animationDurations,
      animationCurves: t < 0.5 ? animationCurves : other.animationCurves,
      supportsHover: t < 0.5 ? supportsHover : other.supportsHover,
      supportsHaptics: t < 0.5 ? supportsHaptics : other.supportsHaptics,
      interactiveCursor: t < 0.5 ? interactiveCursor : other.interactiveCursor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PlatformThemeExtension &&
        other.touchTargetSize == touchTargetSize &&
        other.borderRadius == borderRadius &&
        other.elevation == elevation &&
        other.scrollPhysics == scrollPhysics &&
        other.pageTransitionsBuilder == pageTransitionsBuilder &&
        other.animationDurations == animationDurations &&
        other.animationCurves == animationCurves &&
        other.supportsHover == supportsHover &&
        other.supportsHaptics == supportsHaptics &&
        other.interactiveCursor == interactiveCursor;
  }

  @override
  int get hashCode {
    return Object.hash(
      touchTargetSize,
      borderRadius,
      elevation,
      scrollPhysics,
      pageTransitionsBuilder,
      animationDurations,
      animationCurves,
      supportsHover,
      supportsHaptics,
      interactiveCursor,
    );
  }
}

/// Helper extension to access platform theme from BuildContext
extension PlatformThemeContext on BuildContext {
  PlatformThemeExtension get platformTheme {
    return Theme.of(this).extension<PlatformThemeExtension>() ??
        PlatformThemeExtension.forCurrentPlatform();
  }
}

/// Platform-specific button styles
class PlatformButtonStyles {
  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    final platformTheme = context.platformTheme;
    
    return ElevatedButton.styleFrom(
      minimumSize: Size(platformTheme.touchTargetSize, platformTheme.touchTargetSize),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
      ),
      elevation: platformTheme.elevation,
    );
  }

  static ButtonStyle textButtonStyle(BuildContext context) {
    final platformTheme = context.platformTheme;
    
    return TextButton.styleFrom(
      minimumSize: Size(platformTheme.touchTargetSize, platformTheme.touchTargetSize),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    final platformTheme = context.platformTheme;
    
    return OutlinedButton.styleFrom(
      minimumSize: Size(platformTheme.touchTargetSize, platformTheme.touchTargetSize),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
      ),
    );
  }

  static ButtonStyle iconButtonStyle(BuildContext context) {
    final platformTheme = context.platformTheme;
    
    return IconButton.styleFrom(
      minimumSize: Size(platformTheme.touchTargetSize, platformTheme.touchTargetSize),
    );
  }
}

/// Platform-specific card styles
class PlatformCardStyles {
  static Widget platformCard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
    Color? color,
    double? elevation,
  }) {
    final platformTheme = context.platformTheme;
    
    return Card(
      elevation: elevation ?? platformTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
      ),
      color: color,
      child: platformTheme.supportsHover && onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(platformTheme.borderRadius),
              mouseCursor: platformTheme.interactiveCursor,
              child: child,
            )
          : GestureDetector(
              onTap: onTap,
              child: child,
            ),
    );
  }
}

/// Platform-specific input decoration
class PlatformInputDecorations {
  static InputDecoration textFieldDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final platformTheme = context.platformTheme;
    
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(platformTheme.borderRadius),
        borderSide: const BorderSide(width: 2.0),
      ),
    );
  }
}

/// Utility function to add platform theme extension to ThemeData
ThemeData addPlatformExtensions(ThemeData theme) {
  final extensions = <ThemeExtension<dynamic>>[
    PlatformThemeExtension.forCurrentPlatform(),
  ];
  
  return theme.copyWith(
    extensions: extensions,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: PlatformAnimations().pageTransitionBuilder,
      },
    ),
  );
}

/// Helper function to get platform-appropriate focus highlight color
Color getPlatformFocusColor(BuildContext context) {
  return PlatformOptimizations().getFocusHighlightColor(context);
}

/// Helper function to trigger platform-appropriate haptic feedback
Future<void> triggerPlatformHaptic(HapticFeedbackType type) async {
  await PlatformOptimizations().triggerHapticFeedback(type);
}