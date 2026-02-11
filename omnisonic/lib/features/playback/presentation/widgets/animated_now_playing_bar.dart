import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/animation_manager.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/typography.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../viewmodels/playback_view_model.dart';

/// Animated now-playing bar that slides up from the bottom
/// 
/// Features:
/// - Sliding animation with album artwork
/// - Smooth track information transitions
/// - Playback state visual indicators
/// - Tap to expand to full-screen player
class AnimatedNowPlayingBar extends StatefulWidget {
  const AnimatedNowPlayingBar({
    super.key,
    this.onTap,
    this.height = 72.0,
  });

  final VoidCallback? onTap;
  final double height;

  @override
  State<AnimatedNowPlayingBar> createState() => _AnimatedNowPlayingBarState();
}

class _AnimatedNowPlayingBarState extends State<AnimatedNowPlayingBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  Track? _previousTrack;
  bool _previousIsPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen to playback changes only once
    final playbackViewModel = Provider.of<PlaybackViewModel>(context);
    _handleTrackChange(playbackViewModel.currentTrack);
    _handlePlaybackStateChange(playbackViewModel.isPlaying);
  }

  void _initializeAnimations() {
    // Slide animation for showing/hiding the bar
    _slideController = AnimationController(
      duration: AnimationManager.normalDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AnimationManager.standardCurve,
    ));

    // Pulse animation for playing state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTrackChange(Track? currentTrack) {
    if (_previousTrack?.id != currentTrack?.id) {
      if (currentTrack != null) {
        // New track started - slide in
        _slideController.forward();
      } else {
        // No track - slide out
        _slideController.reverse();
      }
      _previousTrack = currentTrack;
    }
  }

  void _handlePlaybackStateChange(bool isPlaying) {
    if (_previousIsPlaying == isPlaying) return;
    
    _previousIsPlaying = isPlaying;
    if (isPlaying) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackViewModel>(
      builder: (context, playbackViewModel, child) {
        final currentTrack = playbackViewModel.currentTrack;
        final isPlaying = playbackViewModel.isPlaying;
        final progress = playbackViewModel.progress;

        if (currentTrack == null) {
          return const SizedBox.shrink();
        }

        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: OmnisonicColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // Progress bar at the top
                    _buildProgressBar(progress),
                    
                    // Main content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OmnisonicSpacing.md,
                        vertical: OmnisonicSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          _buildAlbumArtwork(currentTrack, isPlaying),
                          const SizedBox(width: OmnisonicSpacing.md),
                          Expanded(
                            child: _buildTrackInfo(currentTrack),
                          ),
                          const SizedBox(width: OmnisonicSpacing.md),
                          _buildPlaybackControls(playbackViewModel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double progress) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white.withOpacity(0.2),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        minHeight: 2,
      ),
    );
  }

  Widget _buildAlbumArtwork(Track track, bool isPlaying) {
    // Only animate when playing
    if (!isPlaying) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: track.coverArtUrl != null
              ? CachedNetworkImage(
                  imageUrl: track.coverArtUrl!,
                  cacheKey: track.coverArtUrl!.subsonicCacheKey,
                  fit: BoxFit.cover,
                  maxWidthDiskCache: 96,
                  maxHeightDiskCache: 96,
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                  placeholder: (context, url) => _buildFallbackArtwork(),
                  errorWidget: (context, url, error) {
                    return _buildFallbackArtwork();
                  },
                )
              : _buildFallbackArtwork(),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!,
                      cacheKey: track.coverArtUrl!.subsonicCacheKey,
                      fit: BoxFit.cover,
                      maxWidthDiskCache: 96,
                      maxHeightDiskCache: 96,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                      placeholder: (context, url) => _buildFallbackArtwork(),
                      errorWidget: (context, url, error) {
                        return _buildFallbackArtwork();
                      },
                    )
                  : _buildFallbackArtwork(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackArtwork() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            OmnisonicColors.primaryPurple.withOpacity(0.3),
            OmnisonicColors.primaryBlue.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: AnimationManager.fastDuration,
          child: Text(
            track.title,
            key: ValueKey('title_${track.id}'),
            style: OmnisonicTypography.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: AnimationManager.fastDuration,
          child: Text(
            track.artist,
            key: ValueKey('artist_${track.id}'),
            style: OmnisonicTypography.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(PlaybackViewModel playbackViewModel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: playbackViewModel.hasPrevious
              ? () => playbackViewModel.skipToPrevious()
              : null,
        ),
        const SizedBox(width: OmnisonicSpacing.sm),
        _buildPlayPauseButton(playbackViewModel),
        const SizedBox(width: OmnisonicSpacing.sm),
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: playbackViewModel.hasNext
              ? () => playbackViewModel.skipToNext()
              : null,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(PlaybackViewModel playbackViewModel) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: playbackViewModel.isPlaying ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => playbackViewModel.togglePlayPause(),
                child: Icon(
                  playbackViewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: OmnisonicColors.primaryPurple,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Icon(
            icon,
            color: onPressed != null 
                ? Colors.white 
                : Colors.white.withOpacity(0.5),
            size: 18,
          ),
        ),
      ),
    );
  }
}