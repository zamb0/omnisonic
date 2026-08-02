import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../../../ui/presentation/widgets/section_header.dart';
import '../viewmodels/playlist_view_model.dart';

/// Playlist picker for "Add to Playlist", shared by every surface that offers
/// the action so they cannot drift apart.
///
/// Shows a message instead of an empty sheet when there is no playlist to add
/// to, so the entry point is never a dead end.
Future<void> showAddToPlaylistSheet(BuildContext context, Track track) async {
  final playlistViewModel = context.read<PlaylistViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final playlists = playlistViewModel.playlists;

  if (playlists.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Create a playlist first')),
    );
    return;
  }

  final playlistId = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: SectionHeader(
              title: 'Add to Playlist',
              padding: EdgeInsets.zero,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackCount} tracks'),
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
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        added ? 'Added to playlist' : 'Could not add track to playlist',
      ),
    ),
  );
}
