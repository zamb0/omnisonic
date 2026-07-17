import 'package:flutter/material.dart';
import '../constants/animation_constants.dart';

/// Utility class for creating consistent animations throughout the app
class AnimationUtils {
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
              curve: AnimationConstants.playerCurve,
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
              curve: AnimationConstants.bottomSheetCurve,
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
        curve: AnimationConstants.dialogCurve,
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
      transitionAnimationController: AnimationController(
        duration: AnimationConstants.standardAnimation,
        vsync: Navigator.of(context),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
      barrierColor: Colors.black54,
      transitionBuilder: fadeTransition,
      transitionDuration: AnimationConstants.quickAnimation,
    );
  }
}
