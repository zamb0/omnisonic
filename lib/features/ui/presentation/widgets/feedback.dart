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
  // The bar is the opposite of the theme: dark on light, light on dark. Each
  // kind takes the semantic colour that reads on it.
  final onDarkBar = scheme.brightness == Brightness.light;
  final (IconData icon, Color color) = switch (kind) {
    FeedbackKind.success => (
      OmnisonicIcons.checkCircle,
      onDarkBar ? OmnisonicColors.success : OmnisonicColors.successAccessible,
    ),
    FeedbackKind.error => (OmnisonicIcons.error, _errorOnInverse(scheme)),
    FeedbackKind.info => (
      OmnisonicIcons.info,
      onDarkBar ? OmnisonicColors.info : OmnisonicColors.infoAccessible,
    ),
  };

  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: color, size: OmnisonicIconSizes.smd),
          ),
          const SizedBox(width: OmnisonicSpacing.ms),
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

/// Shows a view model's transient action error as an error snackbar, then
/// clears it.
///
/// Action errors (a failed delete, a refused reorder) are reported this way
/// so they never replace the page the user is looking at. Sits above the
/// navigator, in `MaterialApp.builder`, so it covers every route.
///
/// If something else consumes the error first — a dialog that shows it
/// inline and clears it — nothing is shown here.
class ActionErrorListener extends StatefulWidget {
  const ActionErrorListener({
    super.key,
    required this.source,
    required this.message,
    required this.clear,
    required this.child,
    this.kind = FeedbackKind.error,
  });

  /// How the message is shown: an error unless said otherwise (a notice
  /// such as "Now playing on MacBook" is [FeedbackKind.info]).
  final FeedbackKind kind;

  /// Resolves the notifier lazily; returning null (no DI in a test, say)
  /// makes this a pass-through.
  final Listenable? Function() source;
  final String? Function() message;
  final VoidCallback clear;
  final Widget child;

  @override
  State<ActionErrorListener> createState() => _ActionErrorListenerState();
}

class _ActionErrorListenerState extends State<ActionErrorListener> {
  Listenable? _source;

  @override
  void initState() {
    super.initState();
    try {
      _source = widget.source()?..addListener(_onChange);
    } catch (_) {
      _source = null;
    }
  }

  @override
  void dispose() {
    _source?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final message = widget.message();
    if (message == null) return;
    // Clearing notifies; defer both so this never runs mid-build, and so a
    // dialog that shows the error inline gets to consume it first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.message() != message) return;
      widget.clear();
      showFeedback(context, message, kind: widget.kind);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
