import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../../../ui/presentation/widgets/dialogs.dart';
import '../../../ui/presentation/widgets/feedback.dart';
import '../viewmodels/playlist_view_model.dart';

/// Asks, then deletes [playlist]. Resolves to true once it is gone.
///
/// One flow for the list and the detail page, which each had their own
/// hand-built dialog. Failures are reported by the app-wide
/// [ActionErrorListener].
Future<bool> confirmAndDeletePlaylist(
  BuildContext context,
  Playlist playlist,
) async {
  final viewModel = context.read<PlaylistViewModel>();
  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete "${playlist.name}"?',
    message:
        'The playlist is removed from its server. The tracks in it are not '
        'affected.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!confirmed) return false;

  final ok = await viewModel.deletePlaylist(playlist.id);
  if (ok && context.mounted) {
    showFeedback(
      context,
      'Deleted "${playlist.name}"',
      kind: FeedbackKind.success,
    );
  }
  return ok;
}

/// Asks for a name, then duplicates [playlist].
///
/// Empty names are refused in the dialog instead of silently doing nothing,
/// and the controller is disposed with the dialog.
Future<void> duplicatePlaylistFlow(
  BuildContext context,
  Playlist playlist,
) async {
  final viewModel = context.read<PlaylistViewModel>();
  final name = await showTextInputDialog(
    context,
    title: 'Duplicate playlist',
    label: 'Name',
    confirmLabel: 'Duplicate',
    initialValue: '${playlist.name} (copy)',
  );
  if (name == null) return;

  final ok = await viewModel.duplicatePlaylist(playlist.id, name);
  if (ok && context.mounted) {
    showFeedback(context, 'Created "$name"', kind: FeedbackKind.success);
  }
}
