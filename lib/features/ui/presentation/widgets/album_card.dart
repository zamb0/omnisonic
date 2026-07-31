import 'package:flutter/material.dart';

import '../../../../core/entities/album.dart';
import 'feishin_card.dart';

/// A card widget for displaying album information in a grid or list
/// Now uses the enhanced card system for better visual appeal and animations
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStar;
  final VoidCallback? onUnstar;
  final double? width;
  final bool showArtist;
  final String? serverName;
  final bool showMeta;
  final bool? isStarred; // Override album.isStarred for optimistic UI updates

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onLongPress,
    this.onStar,
    this.onUnstar,
    this.width,
    this.showArtist = true,
    this.serverName,
    this.showMeta = true,
    this.isStarred,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = showArtist ? album.artist : null;
    final meta = showMeta
        ? (album.year?.toString() ??
              serverName ??
              (album.trackCount != null
                  ? '${album.trackCount} track${album.trackCount != 1 ? 's' : ''}'
                  : null))
        : null;

    // Use the provided isStarred value or fall back to album.isStarred
    final starred = isStarred ?? album.isStarred;

    return FeishinCard(
      title: album.title,
      subtitle: subtitle,
      meta: meta,
      imageUrl: album.coverArtUrl,
      onTap: onTap,
      onStar: starred ? onUnstar : onStar,
      isStarred: starred,
      width: width,
      titleMaxLines: 1,
    );
  }
}
