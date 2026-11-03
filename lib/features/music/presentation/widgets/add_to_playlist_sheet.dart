import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/presentation/widgets/feedback.dart';
import 'playlist_form_dialog.dart';

import '../../../../core/design_system/design_system.dart';

import '../../../../core/entities/entities.dart';
import '../../../ui/presentation/widgets/cover_art.dart';
import '../viewmodels/playlist_view_model.dart';
import '../../../../core/utils/formatters.dart';

/// Playlist picker for "Add to Playlist", shared by every surface that offers
/// the action so they cannot drift apart.
///
/// Shows a message instead of an empty sheet when there is no playlist to add
/// to, so the entry point is never a dead end.
Future<void> showAddToPlaylistSheet(BuildContext context, Track track) async {
  final playlistViewModel = context.read<PlaylistViewModel>();
  final playlists = playlistViewModel.playlists;

  if (playlists.isEmpty) {
    showFeedback(
      context,
      'Create a playlist first',
      actionLabel: 'New playlist',
      onAction: () => showPlaylistFormDialog(context),
    );
    return;
  }

  final playlistId = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OmnisonicSpacing.lg,
              0,
              OmnisonicSpacing.lg,
              OmnisonicSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add to playlist',
                style: OmnisonicTypography.overlayTitle.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: OmnisonicSpacing.lg,
                  ),
                  leading: CoverArt(
                    url: playlist.coverArtUrl,
                    size: 40,
                    fallbackIcon: OmnisonicIcons.playlistPlay,
                  ),
                  title: Text(playlist.name),
                  subtitle: Text(pluralize(playlist.trackCount, 'track')),
                  onTap: () => Navigator.pop(sheetContext, playlist.id),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  if (playlistId == null) return;

  final added = await playlistViewModel.addTrackToPlaylist(
    playlistId,
    track.id,
  );
  // A failure is reported by the app-wide ActionErrorListener.
  if (added && context.mounted) {
    showFeedback(context, 'Added to playlist', kind: FeedbackKind.success);
  }
}
