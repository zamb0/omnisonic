import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/track.dart';

/// A reusable tile widget for displaying track information
class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final bool showAlbumArt;
  final bool showTrackNumber;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onMorePressed,
    this.showAlbumArt = true,
    this.showTrackNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 0,
      ),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: showAlbumArt ? _buildAlbumArt(context) : _buildTrackNumber(context),
      title: Text(
        track.title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (onMorePressed != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMorePressed,
              iconSize: 20,
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildAlbumArt(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: scheme.surfaceVariant,
      ),
      child: track.coverArtUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: scheme.surfaceVariant,
                  child: Icon(Icons.music_note, color: scheme.onSurfaceVariant),
                ),
                errorWidget: (context, url, error) => Container(
                  color: scheme.surfaceVariant,
                  child: Icon(Icons.music_note, color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : Icon(Icons.music_note, color: scheme.onSurfaceVariant),
    );
  }

  Widget _buildTrackNumber(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: Text(
        track.trackNumber?.toString() ?? '—',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}