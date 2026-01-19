import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/animation_manager.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/typography.dart';
import '../../../../core/design_system/responsive_layout.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart';
import '../viewmodels/playback_view_model.dart';

/// Full-screen player with enhanced UI and animations
/// 
/// Features:
/// - Large album artwork display with animations
/// - Prominent playback controls with smooth interactions
/// - Precise seek bar with scrubbing animations
/// - Responsive layout for different screen sizes
class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with TickerProviderStateMixin {
  late AnimationController _artworkController;
  late AnimationController _controlsController;
  late AnimationController _seekController;
  late AnimationController _rotationController;
  
  late Animation<double> _artworkScaleAnimation;
  late Animation<double> _controlsOpacityAnimation;
  late Animation<double> _seekScaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isDraggingSeek = false;
  double _seekValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Artwork animation
    _artworkController = AnimationController(
      duration: AnimationManager.slowDuration,
      vsync: this,
    );
    
    _artworkScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _artworkController,
      curve: AnimationManager.standardCurve,
    ));

    // Controls animation
    _controlsController = AnimationController(
      duration: AnimationManager.normalDuration,
      vsync: this,
    );
    
    _controlsOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeInOut,
    ));

    // Seek bar animation
    _seekController = AnimationController(
      duration: AnimationManager.fastDuration,
      vsync: this,
    );
    
    _seekScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _seekController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for playing state
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start entrance animations
    _artworkController.forward();
    _controlsController.forward();
  }

  @override
  void dispose() {
    _artworkController.dispose();
    _controlsController.dispose();
    _seekController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handlePlaybackStateChange(bool isPlaying) {
    if (isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackViewModel>(
      builder: (context, playbackViewModel, child) {
        final currentTrack = playbackViewModel.currentTrack;
        final isPlaying = playbackViewModel.isPlaying;
        final position = playbackViewModel.position;
        final duration = playbackViewModel.duration;
        final progress = playbackViewModel.progress;

        _handlePlaybackStateChange(isPlaying);

        if (currentTrack == null) {
          return const Scaffold(
            body: Center(
              child: Text('No track playing'),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OmnisonicColors.backgroundDark,
                  OmnisonicColors.surfaceDark,
                ],
              ),
            ),
            child: SafeArea(
              child: ResponsiveLayout(
                mobile: _buildMobileLayout(
                  context,
                  currentTrack,
                  playbackViewModel,
                  position,
                  duration,
                  progress,
                  isPlaying,
                ),
                tablet: _buildTabletLayout(
                  context,
                  currentTrack,
                  playbackViewModel,
                  position,
                  duration,
                  progress,
                  isPlaying,
                ),
                desktop: _buildDesktopLayout(
                  context,
                  currentTrack,
                  playbackViewModel,
                  position,
                  duration,
                  progress,
                  isPlaying,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Track track,
    PlaybackViewModel playbackViewModel,
    Duration position,
    Duration duration,
    double progress,
    bool isPlaying,
  ) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(OmnisonicSpacing.xl),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildAlbumArtwork(track, isPlaying),
                ),
                const SizedBox(height: OmnisonicSpacing.xl),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildTrackInfo(track),
                      const SizedBox(height: OmnisonicSpacing.xl),
                      _buildSeekBar(playbackViewModel, position, duration, progress),
                      const SizedBox(height: OmnisonicSpacing.xl),
                      _buildPlaybackControls(playbackViewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    Track track,
    PlaybackViewModel playbackViewModel,
    Duration position,
    Duration duration,
    double progress,
    bool isPlaying,
  ) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(OmnisonicSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildAlbumArtwork(track, isPlaying),
                ),
                const SizedBox(width: OmnisonicSpacing.xl),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTrackInfo(track),
                      const SizedBox(height: OmnisonicSpacing.xl),
                      _buildSeekBar(playbackViewModel, position, duration, progress),
                      const SizedBox(height: OmnisonicSpacing.xl),
                      _buildPlaybackControls(playbackViewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Track track,
    PlaybackViewModel playbackViewModel,
    Duration position,
    Duration duration,
    double progress,
    bool isPlaying,
  ) {
    return _buildTabletLayout(
      context,
      track,
      playbackViewModel,
      position,
      duration,
      progress,
      isPlaying,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Implement queue view
            },
            icon: const Icon(
              Icons.queue_music,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement more options
            },
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtwork(Track track, bool isPlaying) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _artworkScaleAnimation,
        _rotationAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _artworkScaleAnimation.value,
          child: Transform.rotate(
            angle: isPlaying ? _rotationAnimation.value * 0.1 : 0,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 400,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: OmnisonicColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: track.coverArtUrl != null
                      ? Image.network(
                          track.coverArtUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackArtwork();
                          },
                        )
                      : _buildFallbackArtwork(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackArtwork() {
    return Container(
      decoration: BoxDecoration(
        gradient: OmnisonicColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.music_note,
          color: Colors.white,
          size: 120,
        ),
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return FadeTransition(
      opacity: _controlsOpacityAnimation,
      child: Column(
        children: [
          Text(
            track.title,
            style: OmnisonicTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: OmnisonicSpacing.sm),
          Text(
            track.artist,
            style: OmnisonicTypography.headlineMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (track.album.isNotEmpty) ...[
            const SizedBox(height: OmnisonicSpacing.xs),
            Text(
              track.album,
              style: OmnisonicTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeekBar(
    PlaybackViewModel playbackViewModel,
    Duration position,
    Duration duration,
    double progress,
  ) {
    return FadeTransition(
      opacity: _controlsOpacityAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_isDraggingSeek 
                    ? Duration(milliseconds: (_seekValue * duration.inMilliseconds).round())
                    : position),
                style: OmnisonicTypography.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: OmnisonicTypography.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: OmnisonicSpacing.sm),
          AnimatedBuilder(
            animation: _seekScaleAnimation,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
                overlayColor: Colors.white.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _isDraggingSeek ? _seekValue : progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  setState(() {
                    _isDraggingSeek = true;
                    _seekValue = value;
                  });
                },
                onChangeStart: (value) {
                  _seekController.forward();
                },
                onChangeEnd: (value) {
                  _seekController.reverse();
                  playbackViewModel.seekToProgress(value);
                  setState(() {
                    _isDraggingSeek = false;
                  });
                },
              ),
            ),
            builder: (context, child) {
              return Transform.scale(
                scale: _seekScaleAnimation.value,
                child: child,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(PlaybackViewModel playbackViewModel) {
    return FadeTransition(
      opacity: _controlsOpacityAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: playbackViewModel.shuffleEnabled 
                ? Icons.shuffle 
                : Icons.shuffle,
            isActive: playbackViewModel.shuffleEnabled,
            onPressed: () => playbackViewModel.toggleShuffleMode(),
          ),
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: playbackViewModel.hasPrevious
                ? () => playbackViewModel.skipToPrevious()
                : null,
            size: 40,
          ),
          _buildPlayPauseButton(playbackViewModel),
          _buildControlButton(
            icon: Icons.skip_next,
            onPressed: playbackViewModel.hasNext
                ? () => playbackViewModel.skipToNext()
                : null,
            size: 40,
          ),
          _buildControlButton(
            icon: _getRepeatIcon(playbackViewModel.repeatMode),
            isActive: playbackViewModel.repeatMode != RepeatMode.none,
            onPressed: () => playbackViewModel.toggleRepeatMode(),
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(RepeatMode repeatMode) {
    switch (repeatMode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  Widget _buildPlayPauseButton(PlaybackViewModel playbackViewModel) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => playbackViewModel.togglePlayPause(),
          child: Icon(
            playbackViewModel.isPlaying ? Icons.pause : Icons.play_arrow,
            color: OmnisonicColors.primaryPurple,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    double size = 32,
  }) {
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular((size + 16) / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: onPressed != null 
                ? (isActive ? Colors.white : Colors.white.withOpacity(0.8))
                : Colors.white.withOpacity(0.3),
            size: size,
          ),
        ),
      ),
    );
  }
}