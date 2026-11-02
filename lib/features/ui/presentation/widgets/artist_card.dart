import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/artist.dart';
import '../../../../core/routing/app_router.dart';
import 'cover_art.dart';
import 'media_card.dart';

/// An artist as a round [MediaCard]. Tap opens the artist by default.
class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final double? width;

  /// Pinned to the image's corner, e.g. an offline badge.
  final Widget? badge;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.width,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final count = artist.albumCount;
    final meta = count != null && count > 0
        ? '$count album${count != 1 ? 's' : ''}'
        : null;

    return MediaCard(
      title: artist.name,
      meta: meta,
      imageUrl: artist.imageUrl,
      shape: CoverArtShape.circle,
      fallbackIcon: OmnisonicIcons.person,
      width: width,
      badge: badge,
      onTap:
          onTap ??
          () => context.push(
            AppRouter.artistDetailLocation(artist.id),
            extra: artist,
          ),
    );
  }
}
