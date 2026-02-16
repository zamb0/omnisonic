import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/animation_manager.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../viewmodels/playback_view_model.dart';

/// Feishin-style now-playing bar at the bottom of the screen
/// 
/// Layout:
/// - Left: album artwork + track info (title, artist, album)
/// - Center: playback controls + progress slider with timestamps
/// - Right: utility icons (queue, favorite, volume)
class AnimatedNowPlayingBar extends StatefulWidget {
  const AnimatedNowPlayingBar({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  State<AnimatedNowPlayingBar> createState() => _AnimatedNowPlayingBarState();
}

class _AnimatedNowPlayingBarState extends State<AnimatedNowPlayingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  Track? _previousTrack;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playbackViewModel = Provider.of<PlaybackViewModel>(context);
    _handleTrackChange(playbackViewModel.currentTrack);
  }

  void _handleTrackChange(Track? currentTrack) {
    if (_previousTrack?.id != currentTrack?.id) {
      if (currentTrack != null) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
      _previousTrack = currentTrack;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Consumer<PlaybackViewModel>(
      builder: (context, vm, child) {
        final track = vm.currentTrack;

        if (track == null) {
          return const SizedBox.shrink();
        }

        final position = vm.position;
        final duration = vm.duration;
        final progress = vm.progress;

        return SlideTransition(
          position: _slideAnimation,
          child: isMobile
              ? _buildMobileBar(context, vm, track, scheme, position, duration, progress)
              : _buildDesktopBar(context, vm, track, scheme, position, duration, progress),
        );
      },
    );
  }

  /// Compact mobile bar: artwork + info + controls, with a thin progress bar on top
  Widget _buildMobileBar(
    BuildContext context,
    PlaybackViewModel vm,
    Track track,
    ColorScheme scheme,
    Duration position,
    Duration duration,
    double progress,
  ) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Thin progress bar at top
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Artwork
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: scheme.surfaceContainerHighest,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: track.coverArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: track.coverArtUrl!.withCoverArtSize(128),
                                cacheKey: track.coverArtUrl!.withCoverArtSize(128).subsonicCacheKey,
                                cacheManager: OmnisonicImageCacheManager.instance,
                                fit: BoxFit.cover,
                                memCacheWidth: 88,
                                memCacheHeight: 88,
                                fadeInDuration: const Duration(milliseconds: 120),
                                useOldImageOnUrlChange: true,
                                placeholder: (context, url) => _buildFallbackArtwork(),
                                errorWidget: (context, url, error) => _buildFallbackArtwork(),
                              )
                            : _buildFallbackArtwork(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title + Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            track.title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Compact controls
                    _iconBtn(
                      Icons.skip_previous,
                      22,
                      vm.hasPrevious ? scheme.onSurface : scheme.onSurface.withOpacity(0.3),
                      vm.hasPrevious ? () => vm.skipToPrevious() : null,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          vm.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: scheme.onPrimary,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        onPressed: () => vm.togglePlayPause(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _iconBtn(
                      Icons.skip_next,
                      22,
                      vm.hasNext ? scheme.onSurface : scheme.onSurface.withOpacity(0.3),
                      vm.hasNext ? () => vm.skipToNext() : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full desktop 3-section bar: left (artwork+info), center (controls+progress), right (volume)
  Widget _buildDesktopBar(
    BuildContext context,
    PlaybackViewModel vm,
    Track track,
    ColorScheme scheme,
    Duration position,
    Duration duration,
    double progress,
  ) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // === LEFT: Artwork + Track Info ===
          _buildLeftSection(track, scheme),
          // === CENTER: Controls + Progress ===
          Expanded(
            child: _buildCenterSection(vm, scheme, position, duration, progress),
          ),
          // === RIGHT: Utility Icons ===
          _buildRightSection(scheme),
        ],
      ),
    );
  }

  Widget _buildLeftSection(Track track, ColorScheme scheme) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Album artwork
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: scheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: track.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.coverArtUrl!.withCoverArtSize(128),
                          cacheKey: track.coverArtUrl!.withCoverArtSize(128).subsonicCacheKey,
                          cacheManager: OmnisonicImageCacheManager.instance,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          fadeInDuration: const Duration(milliseconds: 120),
                          useOldImageOnUrlChange: true,
                          placeholder: (context, url) => _buildFallbackArtwork(),
                          errorWidget: (context, url, error) => _buildFallbackArtwork(),
                        )
                      : _buildFallbackArtwork(),
                ),
              ),
              const SizedBox(width: 10),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track.album.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        track.album,
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
      ),
    );
  }

  Widget _buildCenterSection(
    PlaybackViewModel vm,
    ColorScheme scheme,
    Duration position,
    Duration duration,
    double progress,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Playback controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconBtn(Icons.stop, 18, scheme.onSurfaceVariant, () => vm.stop()),
            const SizedBox(width: 8),
            _iconBtn(Icons.shuffle, 18, scheme.onSurfaceVariant, () {}),
            const SizedBox(width: 8),
            _iconBtn(
              Icons.skip_previous,
              22,
              vm.hasPrevious ? scheme.onSurface : scheme.onSurface.withOpacity(0.3),
              vm.hasPrevious ? () => vm.skipToPrevious() : null,
            ),
            const SizedBox(width: 8),
            // Play/Pause - prominent circular button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  vm.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: scheme.onPrimary,
                ),
                iconSize: 20,
                padding: EdgeInsets.zero,
                onPressed: () => vm.togglePlayPause(),
              ),
            ),
            const SizedBox(width: 8),
            _iconBtn(
              Icons.skip_next,
              22,
              vm.hasNext ? scheme.onSurface : scheme.onSurface.withOpacity(0.3),
              vm.hasNext ? () => vm.skipToNext() : null,
            ),
            const SizedBox(width: 8),
            _iconBtn(Icons.repeat, 18, scheme.onSurfaceVariant, () {}),
            const SizedBox(width: 8),
            _iconBtn(Icons.queue_music, 18, scheme.onSurfaceVariant, widget.onTap),
          ],
        ),
        const SizedBox(height: 4),
        // Progress bar with timestamps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                _formatDuration(position),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.surfaceContainerHighest,
                    thumbColor: scheme.primary,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      vm.seekToProgress(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSection(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(Icons.favorite_border, 18, scheme.onSurfaceVariant, () {}),
          const SizedBox(width: 4),
          _iconBtn(Icons.volume_up, 18, scheme.onSurfaceVariant, () {}),
          const SizedBox(width: 4),
          // Volume slider
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: scheme.onSurfaceVariant,
                inactiveTrackColor: scheme.surfaceContainerHighest,
                thumbColor: scheme.onSurfaceVariant,
              ),
              child: Slider(
                value: 0.7,
                onChanged: (value) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, double size, Color color, VoidCallback? onPressed) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }

  Widget _buildFallbackArtwork() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}