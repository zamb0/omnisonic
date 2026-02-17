import 'package:flutter/material.dart';
import '../../../../core/entities/artist.dart';
import 'feishin_card.dart';

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
    final meta = artist.albumCount != null && artist.albumCount! > 0
        ? '${artist.albumCount} album${artist.albumCount != 1 ? 's' : ''}'
        : null;

    return FeishinCard(
      title: artist.name,
      meta: meta,
      imageUrl: artist.imageUrl,
      onTap: onTap,
      width: width,
      imageShape: FeishinImageShape.circle,
    );
  }
}