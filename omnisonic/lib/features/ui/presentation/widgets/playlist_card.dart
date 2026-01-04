import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/playlist.dart';

/// A card widget for displaying playlist information
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final double? width;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 160.0;
    
    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlaylistArt(cardWidth - 24),
                const SizedBox(height: 12),
                Text(
                  playlist.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${playlist.trackCount} track${playlist.trackCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (playlist.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    playlist.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistArt(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[300],
      ),
      child: playlist.coverArtUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: playlist.coverArtUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.playlist_play,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.playlist_play,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            )
          : const Icon(
              Icons.playlist_play,
              color: Colors.grey,
              size: 32,
            ),
    );
  }
}