import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// What a [showFeedback] message reports.
enum FeedbackKind { info, success, error }

/// Shows a transient message about the outcome of an action.
///
/// The one place snackbars are styled. The bar keeps the theme's own
/// inverse-surface fill — white text on the warning/success fills that ad hoc
/// snackbars used was 2.1–2.5:1 — and the kind is carried by a leading icon
/// and by the screen-reader announcement, never by colour alone.
///
/// Pass [actionLabel] and [onAction] for a follow-up such as Retry or Undo;
/// the bar then stays up long enough to reach it.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showFeedback(
  BuildContext context,
  String message, {
  FeedbackKind kind = FeedbackKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return null;

  final scheme = Theme.of(context).colorScheme;
  final (IconData icon, Color color) = switch (kind) {
    FeedbackKind.success => (OmnisonicIcons.checkCircle, scheme.inversePrimary),
    FeedbackKind.error => (OmnisonicIcons.error, _errorOnInverse(scheme)),
    FeedbackKind.info => (OmnisonicIcons.info, scheme.onInverseSurface),
  };

  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: OmnisonicSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
      duration: actionLabel != null
          ? const Duration(seconds: 6)
          : const Duration(seconds: 4),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}

/// The error colour that reads on the snackbar's inverse surface: the light
/// theme's bar is dark, the dark theme's bar is light.
Color _errorOnInverse(ColorScheme scheme) =>
    scheme.brightness == Brightness.light
    ? OmnisonicColors.error
    : OmnisonicColors.errorAccessible;
