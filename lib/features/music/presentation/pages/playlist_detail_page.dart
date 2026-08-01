import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../viewmodels/playlist_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../widgets/draggable_track_tile.dart';
import '../widgets/playlist_edit_dialog.dart';
import '../../../ui/presentation/widgets/loading_indicator.dart';

/// Detailed view of a playlist with track management and drag-and-drop reordering
class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistViewModel>().selectPlaylist(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.selectPlaylist(widget.playlistId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final playlist = viewModel.selectedPlaylist;
          if (playlist == null) {
            return const Center(child: Text('Playlist not found'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(playlist, viewModel),
              _buildPlaylistInfo(playlist),
              _buildTrackList(playlist, viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Playlist playlist, PlaylistViewModel viewModel) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlist.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: playlist.coverArtUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: playlist.coverArtUrl!.withCoverArtSize(600),
                      cacheKey: playlist.coverArtUrl!
                          .withCoverArtSize(600)
                          .subsonicCacheKey,
                      cacheManager: OmnisonicImageCacheManager.instance,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      memCacheHeight: 600,
                      fadeInDuration: const Duration(milliseconds: 120),
                      useOldImageOnUrlChange: true,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Icon(
                  Icons.playlist_play,
                  size: 80,
                  color: Colors.white70,
                ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isReorderMode ? Icons.check : Icons.reorder),
          onPressed: () {
            setState(() {
              _isReorderMode = !_isReorderMode;
            });
          },
          tooltip: _isReorderMode ? 'Done Reordering' : 'Reorder Tracks',
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, playlist, viewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Duplicate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Playlist',
                  style: TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaylistInfo(Playlist playlist) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${playlist.trackCount} track${playlist.trackCount != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (playlist.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          playlist.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            playlist.isPublic ? Icons.public : Icons.lock,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            playlist.isPublic ? 'Public' : 'Private',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Consumer<PlaybackViewModel>(
                  builder: (context, playbackViewModel, child) {
                    return ElevatedButton.icon(
                      onPressed: playlist.trackCount > 0
                          ? () => _playPlaylist(playbackViewModel)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(Playlist playlist, PlaylistViewModel viewModel) {
    final tracks = viewModel.selectedPlaylistTracks;

    if (tracks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tracks in this playlist',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Add some tracks to get started',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_isReorderMode) {
      return SliverReorderableList(
        itemCount: tracks.length,
        onReorderItem: (oldIndex, newIndex) =>
            _reorderTracks(oldIndex, newIndex, viewModel),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return ReorderableDragStartListener(
            key: ValueKey(track.id),
            index: index,
            child: DraggableTrackTile(
              track: track,
              index: index,
              onTap: () => _playTrack(track, tracks, index),
              onRemove: () => _removeTrack(track, viewModel),
              showDragHandle: true,
            ),
          );
        },
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = tracks[index];
        return DraggableTrackTile(
          track: track,
          index: index,
          onTap: () => _playTrack(track, tracks, index),
          onRemove: () => _removeTrack(track, viewModel),
          showDragHandle: false,
        );
      }, childCount: tracks.length),
    );
  }

  void _handleMenuAction(
    String action,
    Playlist playlist,
    PlaylistViewModel viewModel,
  ) {
    switch (action) {
      case 'edit':
        _showEditDialog(playlist);
        break;
      case 'share':
        _sharePlaylist(playlist);
        break;
      case 'export':
        _exportPlaylist(playlist);
        break;
      case 'duplicate':
        _duplicatePlaylist(playlist, viewModel);
        break;
      case 'delete':
        _deletePlaylist(playlist, viewModel);
        break;
    }
  }

  void _showEditDialog(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => PlaylistEditDialog(playlist: playlist),
    );
  }

  void _sharePlaylist(Playlist playlist) {
    // TODO: Implement playlist sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playlist sharing coming soon!')),
    );
  }

  void _exportPlaylist(Playlist playlist) {
    // TODO: Implement playlist export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playlist export coming soon!')),
    );
  }

  void _duplicatePlaylist(Playlist playlist, PlaylistViewModel viewModel) {
    final controller = TextEditingController(text: '${playlist.name} (Copy)');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duplicate Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New playlist name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(dialogContext).pop();
                final success = await viewModel.duplicatePlaylist(
                  playlist.id,
                  newName,
                );
                if (success && mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Created "$newName"')),
                  );
                }
              }
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(Playlist playlist, PlaylistViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();
              final success = await viewModel.deletePlaylist(playlist.id);
              if (success && mounted) {
                Navigator.of(context).pop(); // Go back to previous screen
                messenger.showSnackBar(
                  SnackBar(content: Text('Deleted "${playlist.name}"')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderTracks(int oldIndex, int newIndex, PlaylistViewModel viewModel) {
    viewModel.moveTrackInPlaylist(widget.playlistId, oldIndex, newIndex);
  }

  void _playTrack(Track track, List<Track> tracks, int index) {
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(track, queue: tracks, startIndex: index);
  }

  void _playPlaylist(PlaybackViewModel playbackViewModel) {
    final tracks = context.read<PlaylistViewModel>().selectedPlaylistTracks;
    if (tracks.isNotEmpty) {
      playbackViewModel.playTrack(tracks.first, queue: tracks, startIndex: 0);
    }
  }

  void _removeTrack(Track track, PlaylistViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Track'),
        content: Text('Remove "${track.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();
              final success = await viewModel.removeTrackFromPlaylist(
                widget.playlistId,
                track.id,
              );
              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Removed "${track.title}"')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
