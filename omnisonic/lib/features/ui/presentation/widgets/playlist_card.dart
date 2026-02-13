import 'package:flutter/material.dart';
import '../../../../core/entities/playlist.dart';
import 'feishin_card.dart';

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
    final meta = '${playlist.trackCount} track${playlist.trackCount != 1 ? 's' : ''}';

    return FeishinCard(
      title: playlist.name,
      subtitle: playlist.description?.isNotEmpty == true ? playlist.description : null,
      meta: meta,
      imageUrl: playlist.coverArtUrl,
      onTap: onTap,
      width: width,
    );
  }
}