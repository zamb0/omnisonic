import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import 'add_to_playlist_sheet.dart';

/// A draggable track tile for playlist reordering
class DraggableTrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showDragHandle;

  const DraggableTrackTile({
    super.key,
    required this.track,
    required this.index,
    this.onTap,
    this.onRemove,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: _buildLeading(),
        title: Text(
          track.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${track.artist} • ${track.album}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildTrailing(context),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading() {
    if (showDragHandle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drag_handle, color: Colors.grey),
          const SizedBox(width: 8),
          _buildAlbumArt(),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        _buildAlbumArt(),
      ],
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[300],
      ),
      child: track.coverArtUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: SubsonicCoverArt.of(track.coverArtUrl!, 128).url,
                cacheKey: SubsonicCoverArt.of(track.coverArtUrl!, 128).cacheKey,
                cacheManager: OmnisonicImageCacheManager.instance,
                fit: BoxFit.cover,
                memCacheWidth: 128,
                memCacheHeight: 128,
                fadeInDuration: const Duration(milliseconds: 120),
                useOldImageOnUrlChange: true,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.grey, size: 16),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDuration(track.duration),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Play'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'add_to_queue',
              child: ListTile(
                leading: Icon(Icons.queue_music),
                title: Text('Add to Queue'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'add_to_playlist',
              child: ListTile(
                leading: Icon(Icons.playlist_add),
                title: Text('Add to Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove, color: Colors.red),
                title: Text(
                  'Remove from Playlist',
                  style: TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'play':
        onTap?.call();
        break;
      case 'add_to_queue':
        context.read<PlaybackViewModel>().addToQueue(track);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to queue')));
        break;
      case 'add_to_playlist':
        showAddToPlaylistSheet(context, track);
        break;
      case 'remove':
        onRemove?.call();
        break;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
