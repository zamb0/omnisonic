import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../entities/album.dart';
import '../entities/artist.dart';
import '../entities/track.dart';
import '../services/subsonic_image_cache_manager.dart';
import 'spacing.dart';
import 'theme.dart';
import 'animation_manager.dart';
import 'platform_optimizations.dart';
import 'platform_theme_extensions.dart';
import 'platform_animations.dart';
import 'accessibility.dart';

/// Platform-optimized enhanced album card with platform-specific hover effects and interactions
/// Implements Requirements: 6.1, 6.2, 6.3, 2.4, 5.2
class PlatformEnhancedAlbumCard extends StatefulWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool showArtist;
  final bool isSelected;
  final PlatformCardLayout layout;

  const PlatformEnhancedAlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onLongPress,
    this.width,
    this.showArtist = true,
    this.isSelected = false,
    this.layout = PlatformCardLayout.grid,
  });

  @override
  State<PlatformEnhancedAlbumCard> createState() => _PlatformEnhancedAlbumCardState();
}

class _PlatformEnhancedAlbumCardState extends State<PlatformEnhancedAlbumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    final platformAnimations = PlatformAnimations();
    
    _animationController = AnimationController(
      duration: platformAnimations.durations.short,
      vsync: this,
    );
    
    // Platform-specific scale animation
    final scaleEnd = _getPlatformScaleEnd();
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: scaleEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
    
    // Platform-specific elevation animation
    final platformTheme = context.platformTheme;
    _elevationAnimation = Tween<double>(
      begin: platformTheme.elevation,
      end: platformTheme.elevation * 2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
    
    _colorAnimation = ColorTween(
      begin: null,
      end: PlatformOptimizations().getFocusHighlightColor(context),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
  }
  
  double _getPlatformScaleEnd() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return 0.98; // iOS subtle scale down
      case PlatformType.android:
        return 1.02; // Android subtle scale up
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 1.05; // Desktop more pronounced
      case PlatformType.unknown:
        return 1.02;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleHover(bool isHovering) {
    // Only handle hover on platforms that support it
    if (!PlatformOptimizations().supportsHover) return;
    
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  void _handleTap() {
    // Trigger platform-appropriate haptic feedback
    PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.light);
    widget.onTap?.call();
  }
  
  void _handleLongPress() {
    // Trigger platform-appropriate haptic feedback
    PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.medium);
    widget.onLongPress?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    final platformTheme = context.platformTheme;
    final cardWidth = widget.width ?? _getDefaultWidth();
    final semanticLabel = OmnisonicSemantics.albumSemanticLabel(
      title: widget.album.title,
      artist: widget.album.artist,
      trackCount: widget.album.trackCount,
      year: widget.album.year,
    );
    
    return Semantics(
      label: semanticLabel,
      hint: OmnisonicSemantics.interactionHint('play album'),
      button: true,
      selected: widget.isSelected,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(platformTheme.borderRadius),
                gradient: widget.isSelected ? context.primaryGradient : null,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Card(
                elevation: 0, // We handle elevation with custom shadow
                color: _colorAnimation.value ?? Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(platformTheme.borderRadius),
                  side: widget.isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: MouseRegion(
                  onEnter: (_) => _handleHover(true),
                  onExit: (_) => _handleHover(false),
                  cursor: platformTheme.interactiveCursor,
                  child: GestureDetector(
                    onTap: _handleTap,
                    onLongPress: _handleLongPress,
                    child: _buildCardContent(context, platformTheme),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCardContent(BuildContext context, PlatformThemeExtension platformTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Album artwork
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(platformTheme.borderRadius),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(platformTheme.borderRadius),
              ),
              child: _buildAlbumArtwork(context),
            ),
          ),
        ),
        
        // Album info
        Padding(
          padding: const EdgeInsets.all(OmnisonicSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.album.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.showArtist) ...[
                const SizedBox(height: OmnisonicSpacing.xs),
                Text(
                  widget.album.artist,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.album.year != null) ...[
                const SizedBox(height: OmnisonicSpacing.xs),
                Text(
                  widget.album.year.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAlbumArtwork(BuildContext context) {
    if (widget.album.coverArtUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.album.coverArtUrl!.withCoverArtSize(320),
        cacheKey: widget.album.coverArtUrl!.withCoverArtSize(320).subsonicCacheKey,
        cacheManager: OmnisonicImageCacheManager.instance,
        fit: BoxFit.cover,
        memCacheWidth: 320,
        memCacheHeight: 320,
        fadeInDuration: const Duration(milliseconds: 120),
        useOldImageOnUrlChange: true,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    } else {
      return _buildPlaceholder(context);
    }
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.album,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  double _getDefaultWidth() {
    switch (widget.layout) {
      case PlatformCardLayout.grid:
        return 160;
      case PlatformCardLayout.list:
        return double.infinity;
      case PlatformCardLayout.compact:
        return 120;
    }
  }
}

/// Platform-optimized enhanced artist card
class PlatformEnhancedArtistCard extends StatefulWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool isSelected;

  const PlatformEnhancedArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.onLongPress,
    this.width,
    this.isSelected = false,
  });

  @override
  State<PlatformEnhancedArtistCard> createState() => _PlatformEnhancedArtistCardState();
}

class _PlatformEnhancedArtistCardState extends State<PlatformEnhancedArtistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    final platformAnimations = PlatformAnimations();
    
    _animationController = AnimationController(
      duration: platformAnimations.durations.short,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _getPlatformScaleEnd(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
    
    final platformTheme = context.platformTheme;
    _elevationAnimation = Tween<double>(
      begin: platformTheme.elevation,
      end: platformTheme.elevation * 2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
  }
  
  double _getPlatformScaleEnd() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return 0.98;
      case PlatformType.android:
        return 1.02;
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 1.05;
      case PlatformType.unknown:
        return 1.02;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleHover(bool isHovering) {
    if (!PlatformOptimizations().supportsHover) return;
    
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  void _handleTap() {
    PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.light);
    widget.onTap?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    final platformTheme = context.platformTheme;
    final cardWidth = widget.width ?? 160;
    
    return Semantics(
      label: 'Artist ${widget.artist.name}',
      hint: 'Tap to view artist details',
      button: true,
      selected: widget.isSelected,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: cardWidth,
              child: Card(
                elevation: _elevationAnimation.value,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(platformTheme.borderRadius),
                ),
                child: MouseRegion(
                  onEnter: (_) => _handleHover(true),
                  onExit: (_) => _handleHover(false),
                  cursor: platformTheme.interactiveCursor,
                  child: GestureDetector(
                    onTap: _handleTap,
                    onLongPress: widget.onLongPress,
                    child: Column(
                      children: [
                        // Artist image (circular)
                        Padding(
                          padding: const EdgeInsets.all(OmnisonicSpacing.md),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: widget.artist.imageUrl != null
                                ? CachedNetworkImageProvider(widget.artist.imageUrl!)
                                : null,
                            child: widget.artist.imageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                        ),
                        
                        // Artist name
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmnisonicSpacing.md,
                            vertical: OmnisonicSpacing.sm,
                          ),
                          child: Text(
                            widget.artist.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(height: OmnisonicSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card layout options
enum PlatformCardLayout {
  grid,
  list,
  compact,
}