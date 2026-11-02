import 'package:flutter/material.dart';

import '../../../ui/presentation/widgets/feedback.dart';
import '../viewmodels/playback_view_model.dart';

/// Surfaces [PlaybackViewModel.errorMessage] as a snackbar, then clears it.
///
/// Without this a failed play, favourite or source selection was silent: the
/// view model recorded the error and nothing in the UI ever read it, so the
/// tap simply did nothing.
///
/// Sits in `MaterialApp.builder`, under the app's [ScaffoldMessenger] and
/// above the navigator, so it outlives every route — the full-screen player
/// included.
class PlaybackErrorListener extends StatefulWidget {
  const PlaybackErrorListener({
    super.key,
    required this.playback,
    required this.child,
  });

  final PlaybackViewModel Function() playback;
  final Widget child;

  @override
  State<PlaybackErrorListener> createState() => _PlaybackErrorListenerState();
}

class _PlaybackErrorListenerState extends State<PlaybackErrorListener> {
  PlaybackViewModel? _vm;

  @override
  void initState() {
    super.initState();
    try {
      _vm = widget.playback()..addListener(_onChange);
    } catch (_) {
      // No playback in this build (e.g. a widget test without DI).
      _vm = null;
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final vm = _vm;
    final message = vm?.errorMessage;
    if (vm == null || message == null) return;
    // Clearing notifies; defer both so this never runs mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || vm.errorMessage != message) return;
      vm.clearError();
      showFeedback(context, message, kind: FeedbackKind.error);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
