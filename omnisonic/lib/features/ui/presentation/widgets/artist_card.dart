import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/artist.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';

/// A card widget for displaying artist information
class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final double? width;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 140.0;
    
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildArtistImage(cardWidth - 24),
                const SizedBox(height: 12),
                Text(
                  artist.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (artist.albumCount != null && artist.albumCount! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${artist.albumCount} album${artist.albumCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildArtistImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: artist.imageUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: artist.imageUrl!,
                cacheKey: artist.imageUrl!.subsonicCacheKey,
                fit: BoxFit.cover,
                maxWidthDiskCache: 400,
                maxHeightDiskCache: 400,
                memCacheWidth: 400,
                memCacheHeight: 400,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            )
          : const Icon(
              Icons.person,
              color: Colors.grey,
              size: 32,
            ),
    );
  }
}