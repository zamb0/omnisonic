import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import 'media_actions.dart';
import 'media_card.dart';
import 'server_dot.dart';

/// An album as a [MediaCard].
///
/// Works with no callbacks at all: tap opens the album, the overlay plays or
/// shuffles it, and long press / right-click opens [showAlbumActions]. Pass
/// [onTap], [onStar] or [onUnstar] to override.
class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onStar,
    this.onUnstar,
    this.isStarred,
    this.width,
    this.showArtist = true,
    this.showMeta = true,
    this.sourceServerIds,
    this.showActions = true,
    this.badge,
  });

  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onStar;
  final VoidCallback? onUnstar;

  /// Overrides [Album.isStarred] for optimistic UI updates.
  final bool? isStarred;
  final double? width;
  final bool showArtist;
  final bool showMeta;

  /// Servers this album is available on. With more than one, a stack of
  /// server dots badges the cover; with one (or none) there is no badge.
  final List<String>? sourceServerIds;

  /// Whether the play/shuffle overlay and the actions sheet are offered.
  final bool showActions;

  /// A custom badge for the cover; takes precedence over [sourceServerIds].
  final Widget? badge;

  /// Lines of text the card shows, for sizing grid cells.
  static double extentFor(
    BuildContext context,
    double width, {
    bool showArtist = true,
    bool showMeta = true,
  }) =>
      MediaCard.extentFor(context, width, subtitle: showArtist, meta: showMeta);

  @override
  Widget build(BuildContext context) {
    final starred = isStarred ?? album.isStarred;
    final sources = sourceServerIds;
    final meta = !showMeta
        ? null
        : album.year?.toString() ??
              (album.trackCount != null
                  ? '${album.trackCount} track${album.trackCount != 1 ? 's' : ''}'
                  : null);

    return MediaCard(
      title: album.title,
      subtitle: showArtist ? album.artist : null,
      meta: meta,
      imageUrl: album.coverArtUrl,
      fallbackIcon: OmnisonicIcons.album,
      width: width,
      onTap:
          onTap ??
          () => context.push(
            AppRouter.albumDetailLocation(album.id),
            extra: album,
          ),
      onPlay: showActions ? () => playAlbum(context, album) : null,
      onShuffle: showActions
          ? () => playAlbum(context, album, shuffle: true)
          : null,
      onStar: starred ? onUnstar : onStar,
      isStarred: starred,
      onShowActions: showActions
          ? () => showAlbumActions(context, album)
          : null,
      badge:
          badge ??
          // Only where it says something: one source is the default, and a
          // dot on every cover is noise. Several sources get the stack.
          (sources == null || sources.length < 2
              ? null
              : ServerDotStack(serverIds: sources, dotSize: 7)),
    );
  }
}
