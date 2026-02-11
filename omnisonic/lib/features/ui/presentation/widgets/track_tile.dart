import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/track.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';

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
      leading: showAlbumArt ? _buildAlbumArt() : _buildTrackNumber(),
      title: Text(
        track.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.duration),
            style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildAlbumArt() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[300],
      ),
      child: track.coverArtUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                cacheKey: track.coverArtUrl!.subsonicCacheKey,
                fit: BoxFit.cover,
                maxWidthDiskCache: 96,
                maxHeightDiskCache: 96,
                memCacheWidth: 96,
                memCacheHeight: 96,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.grey),
    );
  }

  Widget _buildTrackNumber() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: Text(
        track.trackNumber?.toString() ?? '—',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
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