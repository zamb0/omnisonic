import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    this.imageSize,
    this.titleMaxLines = 1,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onStar;
  final bool isStarred;
  final double? width;
  final FeishinImageShape imageShape;
  final double? imageSize;
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area - expands to fill available width
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedScale(
                  scale: _isHovering ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: ClipRRect(
                    borderRadius: isCircle
                        ? BorderRadius.circular(999)
                        : BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(context, scheme),
                        // Hover overlay with play and star buttons
                        AnimatedOpacity(
                          opacity: _isHovering ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            color: Colors.black.withOpacity(0.4),
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
                                          color: scheme.tertiary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          widget.isStarred
                                              ? Icons.star
                                              : Icons.star_outline,
                                          color: scheme.onTertiary,
                                          size: 20,
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
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.play_arrow,
                                        color: scheme.onPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Text area below the image
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    maxLines: widget.titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.meta != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      widget.meta!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme scheme) {
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, color: scheme.onSurfaceVariant, size: 32),
    );

    if (widget.imageUrl == null) return placeholder;

    final sizedUrl = widget.imageUrl!.withCoverArtSize(400);

    return CachedNetworkImage(
      imageUrl: sizedUrl,
      cacheKey: sizedUrl.subsonicCacheKey,
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
