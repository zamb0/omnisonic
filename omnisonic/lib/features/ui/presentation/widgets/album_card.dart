import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/album.dart';

/// A card widget for displaying album information in a grid or list
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final double? width;
  final bool showArtist;

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.width,
    this.showArtist = true,
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
                _buildAlbumArt(cardWidth - 24),
                const SizedBox(height: 12),
                Text(
                  album.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showArtist) ...[
                  const SizedBox(height: 4),
                  Text(
                    album.artist,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (album.year != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    album.year.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[300],
      ),
      child: album.coverArtUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: album.coverArtUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.album,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.album,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            )
          : const Icon(
              Icons.album,
              color: Colors.grey,
              size: 32,
            ),
    );
  }
}