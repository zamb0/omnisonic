import 'package:flutter/material.dart';

import '../design_system/animation_manager.dart';
import '../design_system/colors.dart';
import '../design_system/spacing.dart';

/// Utility class for creating consistent animations throughout the app
class AnimationUtils {
  /// Respects the platform "reduce motion" accessibility setting: returns
  /// [Duration.zero] when it's on, so callers snap to the end state instead
  /// of silently ignoring the preference.
  static Duration adjustedDuration(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }

  /// Creates a slide down transition for player dismissal
  static Widget slideDownTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position:
          Tween<Offset>(
            begin: const Offset(0.0, 0.0),
            end: const Offset(0.0, 1.0),
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AnimationManager.standardCurve,
            ),
          ),
      child: child,
    );
  }

  /// Creates a slide up transition for bottom sheets
  static Widget slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position:
          Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: const Offset(0.0, 0.0),
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AnimationManager.sheetCurve,
            ),
          ),
      child: child,
    );
  }

  /// Creates a fade transition for dialogs
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AnimationManager.dialogCurve,
      ),
      child: child,
    );
  }

  /// Creates a custom modal bottom sheet with consistent animation
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      // An AnimationController created here was never disposed — one leaked
      // per sheet — and its fixed duration ignored reduced motion.
      sheetAnimationStyle: AnimationStyle(
        duration: adjustedDuration(context, AnimationManager.normalDuration),
        reverseDuration: adjustedDuration(
          context,
          AnimationManager.quickDuration,
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OmnisonicRadius.lg),
        ),
      ),
    );
  }

  /// Creates a custom dialog with consistent animation
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: OmnisonicColors.scrim,
      transitionBuilder: fadeTransition,
      transitionDuration: AnimationManager.quickDuration,
    );
  }
}
