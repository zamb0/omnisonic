import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/animation_utils.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';

enum FeishinImageShape { rounded, circle }

class FeishinCard extends StatefulWidget {
  const FeishinCard({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.imageUrl,
    this.onTap,
    this.onStar,
    this.isStarred = false,
    this.width,
    this.imageShape = FeishinImageShape.rounded,
    this.titleMaxLines = 1,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onStar;
  final bool isStarred;

  /// Fixed card width, for carousels where each item has to be the same
  /// size regardless of what its neighbours contain.
  ///
  /// Left null in grids, where the column count decides the width.
  final double? width;

  final FeishinImageShape imageShape;
  final int titleMaxLines;

  @override
  State<FeishinCard> createState() => _FeishinCardState();
}

class _FeishinCardState extends State<FeishinCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCircle = widget.imageShape == FeishinImageShape.circle;

    // `width` and `imageSize` were both declared and never read: the card
    // took its size entirely from its parent, so every `AlbumCard(width: 160)`
    // in a carousel was a no-op and the cards were whatever the surrounding
    // SizedBox happened to be. `width` is now honoured; `imageSize` is gone,
    // because the image is an AspectRatio of the card and has no size of its
    // own to set.
    final card = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // In a grid cell the image takes whatever height the text leaves.
            // In a Wrap or a scroll view there is no height to share, and an
            // Expanded there asserts — the image is then just a square.
            final bounded = constraints.hasBoundedHeight;
            final image = AspectRatio(
              aspectRatio: 1,
              child: AnimatedScale(
                scale: _isHovering ? 1.03 : 1.0,
                duration: AnimationUtils.adjustedDuration(
                  context,
                  AnimationManager.fastDuration,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: isCircle
                        ? BorderRadius.circular(OmnisonicRadius.full)
                        : BorderRadius.circular(OmnisonicRadius.art),
                    // `0 12px 24px -14px` from the design's cover-art spec:
                    // enough lift that the art floats over the tinted
                    // backdrop without casting a visible grey box.
                    boxShadow: OmnisonicShadows.art,
                  ),
                  child: ClipRRect(
                    borderRadius: isCircle
                        ? BorderRadius.circular(OmnisonicRadius.full)
                        : BorderRadius.circular(OmnisonicRadius.art),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(context, scheme),
                        // Hover overlay with play and star buttons. A
                        // transparent overlay still takes taps, so on touch
                        // it would star the album from an invisible button.
                        IgnorePointer(
                          ignoring: !_isHovering,
                          child: AnimatedOpacity(
                            opacity: _isHovering ? 1.0 : 0.0,
                            duration: AnimationUtils.adjustedDuration(
                              context,
                              AnimationManager.fastDuration,
                            ),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Star button
                                    if (widget.onStar != null)
                                      GestureDetector(
                                        onTap: widget.onStar,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: scheme.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            widget.isStarred
                                                ? OmnisonicIcons.star
                                                : OmnisonicIcons.starOutline,
                                            color: scheme.onSurface,
                                            size: OmnisonicIconSizes.smd,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    // Play button
                                    GestureDetector(
                                      onTap: widget.onTap,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: scheme.onSurface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          OmnisonicIcons.playArrow,
                                          color: scheme.surface,
                                          size: OmnisonicIconSizes.md,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return Column(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bounded) Expanded(child: image) else image,
                // Text area below the image
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: OmnisonicTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: OmnisonicTypography.bold,
                          color: scheme.onSurface,
                        ),
                        maxLines: widget.titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: OmnisonicTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: OmnisonicTypography.medium,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.meta != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.meta!,
                          style: OmnisonicTypography.technical.copyWith(
                            fontSize: 9.5,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final width = widget.width;
    return width == null ? card : SizedBox(width: width, child: card);
  }

  Widget _buildImage(BuildContext context, ColorScheme scheme) {
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        OmnisonicIcons.musicNote,
        color: scheme.onSurfaceVariant,
        size: 32,
      ),
    );

    if (widget.imageUrl == null) return placeholder;

    final art = SubsonicCoverArt.of(widget.imageUrl!, 400);

    return CachedNetworkImage(
      imageUrl: art.url,
      cacheKey: art.cacheKey,
      cacheManager: OmnisonicImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      memCacheHeight: 400,
      fadeInDuration: const Duration(milliseconds: 120),
      useOldImageOnUrlChange: true,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) =>
          coverArtErrorWidget(placeholder, url, error),
    );
  }
}
