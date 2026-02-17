import 'package:flutter/material.dart';

import '../../../../core/entities/album.dart';
import 'feishin_card.dart';

/// A card widget for displaying album information in a grid or list
/// Now uses the enhanced card system for better visual appeal and animations
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool showArtist;
  final String? serverName;
  final bool showMeta;

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onLongPress,
    this.width,
    this.showArtist = true,
    this.serverName,
    this.showMeta = true,
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

    return FeishinCard(
      title: album.title,
      subtitle: subtitle,
      meta: meta,
      imageUrl: album.coverArtUrl,
      onTap: onTap,
      width: width,
      titleMaxLines: 1,
    );
  }
}