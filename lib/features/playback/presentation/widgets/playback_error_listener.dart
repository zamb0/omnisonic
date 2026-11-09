import 'package:flutter/material.dart';

import '../../../ui/presentation/widgets/feedback.dart';
import '../viewmodels/playback_view_model.dart';

/// Surfaces [PlaybackViewModel.errorMessage] (and the handoff notice) as a
/// snackbar, then clears it.
///
/// Without this a failed play, favourite or source selection was silent: the
/// view model recorded the error and nothing in the UI ever read it, so the
/// tap simply did nothing.
class PlaybackErrorListener extends StatelessWidget {
  const PlaybackErrorListener({
    super.key,
    required this.playback,
    required this.child,
  });

  final PlaybackViewModel Function() playback;
  final Widget child;

  @override
  Widget build(BuildContext context) => ActionErrorListener(
    source: playback,
    message: () => playback().errorMessage,
    clear: () => playback().clearError(),
    // Also "Now playing on MacBook" when another device takes over: the
    // reason playback just stopped here.
    child: ActionErrorListener(
      source: playback,
      message: () => playback().handoffNotice,
      clear: () => playback().clearHandoffNotice(),
      kind: FeedbackKind.info,
      child: child,
    ),
  );
}
