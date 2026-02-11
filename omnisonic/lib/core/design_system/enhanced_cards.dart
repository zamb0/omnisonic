import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../entities/album.dart';
import '../entities/artist.dart';
import '../entities/track.dart';
import '../services/subsonic_image_cache_manager.dart';
import 'spacing.dart';
import 'theme.dart';
import 'animation_manager.dart';
import 'micro_interactions.dart';
import 'accessibility.dart';
import 'accessibility_preferences.dart';
import 'platform_optimizations.dart';
import 'platform_theme_extensions.dart';

/// Enhanced album card with elevation and hover animations
/// Implements Requirements: 6.1, 6.2, 6.3
class EnhancedAlbumCard extends StatefulWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool showArtist;
  final bool isSelected;
  final CardLayout layout;
  final String? serverName;

  const EnhancedAlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onLongPress,
    this.width,
    this.showArtist = true,
    this.isSelected = false,
    this.layout = CardLayout.grid,
    this.serverName,
  });

  @override
  State<EnhancedAlbumCard> createState() => _EnhancedAlbumCardState();
}

class _EnhancedAlbumCardState extends State<EnhancedAlbumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationManager().createController(
      duration: AnimationManager.hoverDuration,
      vsync: this,
      debugLabel: 'EnhancedAlbumCard_${widget.album.id}',
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationManager.hoverCurve,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: OmnisonicElevation.card,
      end: OmnisonicElevation.cardHover,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationManager.hoverCurve,
    ));
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize color animation here since it needs Theme.of(context)
    _colorAnimation = ColorTween(
      begin: null,
      end: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationManager.hoverCurve,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
                borderRadius: BorderRadius.circular(OmnisonicRadius.card),
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
                  borderRadius: BorderRadius.circular(OmnisonicRadius.card),
                  side: widget.isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () {
                    AnimationManager().triggerHapticFeedback();
                    widget.onTap?.call();
                  },
                  onLongPress: () {
                    AnimationManager().triggerHapticFeedback(
                      type: HapticFeedbackType.medium,
                    );
                    widget.onLongPress?.call();
                  },
                  onHover: _handleHover,
                  borderRadius: BorderRadius.circular(OmnisonicRadius.card),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: OmnisonicTouchTargets.minimum,
                    ),
                    child: Padding(
                      padding: OmnisonicInsets.card,
                      child: _buildCardContent(cardWidth),
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
  
  Widget _buildCardContent(double cardWidth) {
    switch (widget.layout) {
      case CardLayout.grid:
        return _buildGridLayout(cardWidth);
      case CardLayout.list:
        return _buildListLayout(cardWidth);
      case CardLayout.compact:
        return _buildCompactLayout(cardWidth);
    }
  }
  
  Widget _buildGridLayout(double cardWidth) {
    final artSize = cardWidth - (OmnisonicSpacing.cardPadding * 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAlbumArt(artSize, artSize),
        const SizedBox(height: OmnisonicSpacing.sm),
        Flexible(
          child: _buildAlbumInfo(),
        ),
      ],
    );
  }
  
  Widget _buildListLayout(double cardWidth) {
    return Row(
      children: [
        _buildAlbumArt(60, 60),
        const SizedBox(width: OmnisonicSpacing.md),
        Expanded(child: _buildAlbumInfo()),
        if (widget.album.year != null) _buildYearChip(),
      ],
    );
  }
  
  Widget _buildCompactLayout(double cardWidth) {
    return Row(
      children: [
        _buildAlbumArt(40, 40),
        const SizedBox(width: OmnisonicSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.album.title,
                style: context.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.showArtist)
                Text(
                  widget.album.artist,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAlbumInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.album.title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.showArtist) ...[
          const SizedBox(height: 2),
          Text(
            widget.album.artist,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (widget.album.trackCount != null) ...[
          const SizedBox(height: 2),
          Text(
            '${widget.album.trackCount} track${widget.album.trackCount != 1 ? 's' : ''}',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
        if (widget.serverName != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.serverName!,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
  
  Widget _buildAlbumArt(double width, double height) {
    final altText = OmnisonicAlternativeText.albumArtworkAlt(
      albumTitle: widget.album.title,
      artistName: widget.album.artist,
      hasArtwork: widget.album.coverArtUrl != null,
    );
    
    return Semantics(
      label: altText,
      image: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OmnisonicRadius.albumArt),
          gradient: context.cardDepthGradient,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(OmnisonicRadius.albumArt),
          child: widget.album.coverArtUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.album.coverArtUrl!,
                  cacheKey: widget.album.coverArtUrl!.subsonicCacheKey,
                  fit: BoxFit.cover,
                  maxWidthDiskCache: 600,
                  maxHeightDiskCache: 600,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                  fadeInDuration: const Duration(milliseconds: 200),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: context.subtleGradient,
      ),
      child: Icon(
        Icons.album,
        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }
  
  Widget _buildYearChip() {
    if (widget.album.year == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.sm,
        vertical: OmnisonicSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      ),
      child: Text(
        widget.album.year.toString(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  double _getDefaultWidth() {
    switch (widget.layout) {
      case CardLayout.grid:
        return 160.0;
      case CardLayout.list:
        return double.infinity;
      case CardLayout.compact:
        return double.infinity;
    }
  }
}

/// Enhanced artist card with circular image and hover effects
class EnhancedArtistCard extends StatefulWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool isSelected;
  final CardLayout layout;

  const EnhancedArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.onLongPress,
    this.width,
    this.isSelected = false,
    this.layout = CardLayout.grid,
  });

  @override
  State<EnhancedArtistCard> createState() => _EnhancedArtistCardState();
}

class _EnhancedArtistCardState extends State<EnhancedArtistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationManager().createController(
      duration: AnimationManager.hoverDuration,
      vsync: this,
      debugLabel: 'EnhancedArtistCard_${widget.artist.id}',
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationManager.hoverCurve,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: OmnisonicElevation.card,
      end: OmnisonicElevation.cardHover,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationManager.hoverCurve,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? _getDefaultWidth();
    final semanticLabel = OmnisonicSemantics.artistSemanticLabel(
      name: widget.artist.name,
      albumCount: widget.artist.albumCount,
    );
    
    return Semantics(
      label: semanticLabel,
      hint: OmnisonicSemantics.interactionHint('view artist'),
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
                borderRadius: BorderRadius.circular(OmnisonicRadius.card),
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OmnisonicRadius.card),
                  side: widget.isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () {
                    AnimationManager().triggerHapticFeedback();
                    widget.onTap?.call();
                  },
                  onLongPress: () {
                    AnimationManager().triggerHapticFeedback(
                      type: HapticFeedbackType.medium,
                    );
                    widget.onLongPress?.call();
                  },
                  onHover: _handleHover,
                  borderRadius: BorderRadius.circular(OmnisonicRadius.card),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: OmnisonicTouchTargets.minimum,
                    ),
                    child: Padding(
                      padding: OmnisonicInsets.card,
                      child: _buildCardContent(cardWidth),
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
  
  Widget _buildCardContent(double cardWidth) {
    switch (widget.layout) {
      case CardLayout.grid:
        return _buildGridLayout(cardWidth);
      case CardLayout.list:
        return _buildListLayout();
      case CardLayout.compact:
        return _buildCompactLayout();
    }
  }
  
  Widget _buildGridLayout(double cardWidth) {
    final imageSize = cardWidth - (OmnisonicSpacing.cardPadding * 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildArtistImage(imageSize),
        const SizedBox(height: OmnisonicSpacing.md),
        _buildArtistInfo(),
      ],
    );
  }
  
  Widget _buildListLayout() {
    return Row(
      children: [
        _buildArtistImage(60),
        const SizedBox(width: OmnisonicSpacing.md),
        Expanded(child: _buildArtistInfo()),
        if (widget.artist.albumCount != null) _buildAlbumCountChip(),
      ],
    );
  }
  
  Widget _buildCompactLayout() {
    return Row(
      children: [
        _buildArtistImage(40),
        const SizedBox(width: OmnisonicSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.artist.name,
                style: context.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.artist.albumCount != null)
                Text(
                  '${widget.artist.albumCount} album${widget.artist.albumCount != 1 ? 's' : ''}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildArtistInfo() {
    return Column(
      crossAxisAlignment: widget.layout == CardLayout.grid 
          ? CrossAxisAlignment.center 
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.artist.name,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: widget.layout == CardLayout.grid 
              ? TextAlign.center 
              : TextAlign.start,
        ),
        if (widget.artist.albumCount != null && widget.artist.albumCount! > 0) ...[
          const SizedBox(height: OmnisonicSpacing.xs),
          Text(
            '${widget.artist.albumCount} album${widget.artist.albumCount != 1 ? 's' : ''}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: widget.layout == CardLayout.grid 
                ? TextAlign.center 
                : TextAlign.start,
          ),
        ],
      ],
    );
  }
  
  Widget _buildArtistImage(double size) {
    final altText = OmnisonicAlternativeText.artistImageAlt(
      artistName: widget.artist.name,
      hasImage: widget.artist.imageUrl != null,
    );
    
    return Semantics(
      label: altText,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: context.cardDepthGradient,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: widget.artist.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.artist.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.subtleGradient,
      ),
      child: Icon(
        Icons.person,
        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }
  
  Widget _buildAlbumCountChip() {
    if (widget.artist.albumCount == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.sm,
        vertical: OmnisonicSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      ),
      child: Text(
        '${widget.artist.albumCount}',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  double _getDefaultWidth() {
    switch (widget.layout) {
      case CardLayout.grid:
        return 140.0;
      case CardLayout.list:
        return double.infinity;
      case CardLayout.compact:
        return double.infinity;
    }
  }
}

/// Enhanced track card for displaying track information
class EnhancedTrackCard extends StatefulWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPlaying;
  final bool isSelected;
  final int? trackNumber;
  final CardLayout layout;

  const EnhancedTrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.onLongPress,
    this.isPlaying = false,
    this.isSelected = false,
    this.trackNumber,
    this.layout = CardLayout.list,
  });

  @override
  State<EnhancedTrackCard> createState() => _EnhancedTrackCardState();
}

class _EnhancedTrackCardState extends State<EnhancedTrackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationManager().createController(
      duration: AnimationManager.hoverDuration,
      vsync: this,
      debugLabel: 'EnhancedTrackCard_${widget.track.id}',
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationManager.hoverCurve,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final semanticLabel = OmnisonicSemantics.trackSemanticLabel(
      title: widget.track.title,
      artist: widget.track.artist,
      duration: widget.track.duration,
      isPlaying: widget.isPlaying,
    );
    
    return Semantics(
      label: semanticLabel,
      hint: OmnisonicSemantics.interactionHint('play track'),
      button: true,
      selected: widget.isSelected,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? context.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                border: widget.isPlaying
                    ? Border.all(
                        color: context.playingIndicatorColor,
                        width: 2,
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AnimationManager().triggerHapticFeedback();
                    widget.onTap?.call();
                  },
                  onLongPress: () {
                    AnimationManager().triggerHapticFeedback(
                      type: HapticFeedbackType.medium,
                    );
                    widget.onLongPress?.call();
                  },
                  onHover: _handleHover,
                  borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: OmnisonicTouchTargets.listItem,
                    ),
                    child: Padding(
                      padding: OmnisonicInsets.listItem,
                      child: _buildTrackContent(),
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
  
  Widget _buildTrackContent() {
    return Row(
      children: [
        _buildTrackNumber(),
        const SizedBox(width: OmnisonicSpacing.md),
        if (widget.track.coverArtUrl != null) ...[
          _buildTrackArt(),
          const SizedBox(width: OmnisonicSpacing.md),
        ],
        Expanded(child: _buildTrackInfo()),
        _buildDuration(),
        const SizedBox(width: OmnisonicSpacing.sm),
        _buildPlayingIndicator(),
      ],
    );
  }
  
  Widget _buildTrackNumber() {
    return SizedBox(
      width: 32,
      child: widget.isPlaying
          ? Icon(
              Icons.volume_up,
              color: context.playingIndicatorColor,
              size: 16,
            )
          : Text(
              (widget.trackNumber ?? widget.track.trackNumber ?? 0).toString(),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
  
  Widget _buildTrackArt() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
        child: CachedNetworkImage(
          imageUrl: widget.track.coverArtUrl!,
          cacheKey: widget.track.coverArtUrl!.subsonicCacheKey,
          fit: BoxFit.cover,
          maxWidthDiskCache: 80,
          maxHeightDiskCache: 80,
          memCacheWidth: 80,
          memCacheHeight: 80,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => Container(
            color: context.colorScheme.surface,
            child: Icon(
              Icons.music_note,
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 16,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: context.colorScheme.surface,
            child: Icon(
              Icons.music_note,
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.track.title,
          style: context.textTheme.titleSmall?.copyWith(
            color: widget.isPlaying 
                ? context.playingIndicatorColor 
                : null,
            fontWeight: widget.isPlaying 
                ? FontWeight.w600 
                : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.track.artist,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildDuration() {
    final duration = widget.track.duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return Text(
      '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
  
  Widget _buildPlayingIndicator() {
    if (!widget.isPlaying) return const SizedBox(width: 16);
    
    return SizedBox(
      width: 16,
      height: 16,
      child: MicroInteractions.pulseAnimation(
        enabled: widget.isPlaying,
        child: Container(
          decoration: BoxDecoration(
            color: context.playingIndicatorColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Card layout options for different display contexts
enum CardLayout {
  grid,    // Square cards in a grid
  list,    // Horizontal cards in a list
  compact, // Minimal horizontal cards
}