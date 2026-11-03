import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../../core/utils/animation_utils.dart';

/// Shape of a [CoverArt] tile.
enum CoverArtShape { rounded, circle }

/// Album, track, artist or playlist artwork, with one placeholder and one
/// error state for the whole app.
///
/// Every screen used to build its own `CachedNetworkImage` with its own
/// placeholder — some with none, so a slow server showed a blank square, and
/// some with an `errorWidget` that differed from the placeholder.
///
/// With [size] the art is a fixed square; without it, it fills its parent
/// (wrap it in an `AspectRatio` for a square that follows the width).
/// Artwork is decorative: the surrounding row or card carries the label, so
/// it is excluded from semantics.
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.url,
    this.size,
    this.requestSize,
    this.shape = CoverArtShape.rounded,
    this.radius,
    this.fallbackIcon = OmnisonicIcons.musicNote,
    this.elevated = false,
  });

  final String? url;

  /// Fixed edge length. Null fills the parent.
  final double? size;

  /// Pixel size asked of the server and kept in memory. Defaults from [size]
  /// and the device pixel ratio, or 400 when filling.
  final int? requestSize;

  final CoverArtShape shape;

  /// Corner radius for [CoverArtShape.rounded]. Defaults to the art radius
  /// at card size and scales down for small thumbnails.
  final double? radius;

  final IconData fallbackIcon;

  /// Adds the cover-art drop shadow, for art that floats over the backdrop.
  final bool elevated;

  /// Server-side sizes worth asking for: the cache key includes the size, so
  /// rounding up to a few buckets keeps one cached copy per bucket rather
  /// than one per layout width.
  static const _buckets = [64, 128, 300, 400, 600, 1000];

  int _resolveRequestSize(BuildContext context, double? edge) {
    if (requestSize != null) return requestSize!;
    if (edge == null || !edge.isFinite) return 400;
    final needed = edge * MediaQuery.devicePixelRatioOf(context);
    return _buckets.firstWhere((b) => b >= needed, orElse: () => 1000);
  }

  BorderRadius get _borderRadius {
    if (shape == CoverArtShape.circle) {
      return BorderRadius.circular(OmnisonicRadius.full);
    }
    final edge = size;
    final r =
        radius ??
        (edge == null || edge >= 96
            ? OmnisonicRadius.art
            : edge >= 48
            ? OmnisonicRadius.sm
            : OmnisonicRadius.xs);
    return BorderRadius.circular(r);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = _borderRadius;
    final edge = size;

    Widget placeholder() => LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final iconSize = shortest.isFinite
            ? (shortest * 0.4).clamp(16.0, 48.0)
            : 32.0;
        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: Icon(
              fallbackIcon,
              color: scheme.onSurfaceVariant,
              size: iconSize,
            ),
          ),
        );
      },
    );

    Widget network(String source, double? edge) {
      final px = _resolveRequestSize(context, edge);
      final art = SubsonicCoverArt.of(source, px);
      return CachedNetworkImage(
        imageUrl: art.url,
        cacheKey: art.cacheKey,
        cacheManager: OmnisonicImageCacheManager.instance,
        fit: BoxFit.cover,
        memCacheWidth: px,
        memCacheHeight: px,
        fadeInDuration: AnimationUtils.adjustedDuration(
          context,
          AnimationManager.fastDuration,
        ),
        useOldImageOnUrlChange: true,
        placeholder: (context, url) => placeholder(),
        errorWidget: (context, url, error) =>
            coverArtErrorWidget(placeholder(), url, error),
      );
    }

    final source = url;
    final Widget image;
    if (source == null || source.isEmpty) {
      image = placeholder();
    } else if (edge != null || requestSize != null) {
      image = network(source, edge);
    } else {
      // Filling the parent: size the request from the slot it lands in, so
      // a 44px thumbnail does not download a 400px cover.
      image = LayoutBuilder(
        builder: (context, constraints) =>
            network(source, constraints.biggest.shortestSide),
      );
    }

    Widget result = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox.expand(child: image),
    );
    if (elevated) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: OmnisonicShadows.art,
        ),
        child: result,
      );
    }
    result = ExcludeSemantics(child: result);
    return edge == null
        ? result
        : SizedBox(width: edge, height: edge, child: result);
  }
}
