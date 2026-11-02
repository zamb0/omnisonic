import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import 'add_to_playlist_sheet.dart';
import '../../../../core/utils/formatters.dart';
import '../../../ui/presentation/widgets/cover_art.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: _buildLeading(scheme),
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
        trailing: _buildTrailing(context, scheme),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading(ColorScheme scheme) {
    if (showDragHandle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(OmnisonicIcons.dragHandle, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          _buildAlbumArt(scheme),
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
            style: OmnisonicTypography.metadata.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        _buildAlbumArt(scheme),
      ],
    );
  }

  Widget _buildAlbumArt(ColorScheme scheme) =>
      CoverArt(url: track.coverArtUrl, size: 40);

  Widget _buildTrailing(BuildContext context, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatDuration(track.duration),
          // Equal-width digits, so durations line up down the list.
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: ListTile(
                leading: Icon(OmnisonicIcons.playArrow),
                title: Text('Play'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'add_to_queue',
              child: ListTile(
                leading: Icon(OmnisonicIcons.queueMusic),
                title: Text('Add to Queue'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'add_to_playlist',
              child: ListTile(
                leading: Icon(OmnisonicIcons.playlistAdd),
                title: Text('Add to Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(OmnisonicIcons.remove, color: scheme.error),
                title: Text(
                  'Remove from Playlist',
                  style: TextStyle(color: scheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: const Icon(OmnisonicIcons.moreVert),
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
}
