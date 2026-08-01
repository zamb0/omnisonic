import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart' as playback;
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cover_palette_service.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../viewmodels/playback_view_model.dart';
import 'full_screen_player.dart' show NowPlayingPanel;

/// Feishin-style now-playing bar at the bottom of the screen
///
/// Layout:
/// - Left: album artwork + track info (title, artist, album)
/// - Center: playback controls + progress slider with timestamps
/// - Right: utility icons (queue, favorite, volume)
class AnimatedNowPlayingBar extends StatefulWidget {
  const AnimatedNowPlayingBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<AnimatedNowPlayingBar> createState() => _AnimatedNowPlayingBarState();
}

class _AnimatedNowPlayingBarState extends State<AnimatedNowPlayingBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  /// Drives the desktop bar's glass sheen sweep. Runs continuously and
  /// cheaply (a single translating gradient), so it's fine to leave
  /// repeating for the bar's whole lifetime.
  late AnimationController _sheenController;

  Track? _previousTrack;

  /// Volume to restore when un-muting from the bar's volume icon.
  double _volumeBeforeMute = 1.0;

  /// Progress being dragged on the desktop scrubber, or null when not dragging.
  /// While dragging we show the local value and only seek on release, so a drag
  /// costs one seek instead of one per pointer move.
  double? _draggingProgress;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AnimationManager.normalDuration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AnimationManager.standardCurve,
          ),
        );
    _sheenController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slideController.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AnimationManager.normalDuration;
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

  /// Dominant color extracted from the current track's cover art, used to
  /// tint the progress indicator. Null (falls back to `scheme.primary`)
  /// until extraction finishes or if it fails.
  Color? _tintColor;
  String? _tintedCoverUrl;

  void _updateTint(String? coverArtUrl) {
    if (coverArtUrl == _tintedCoverUrl) return;
    _tintedCoverUrl = coverArtUrl;
    CoverPaletteService.instance.extractColor(coverArtUrl).then((color) {
      if (mounted && _tintedCoverUrl == coverArtUrl) {
        setState(() => _tintColor = color);
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _sheenController.dispose();
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
    // Same threshold the shell uses to switch between the bottom bar and the
    // sidebar, so the compact bar and the phone shell always appear together.
    final isMobile = screenWidth < ResponsiveBreakpoints.tablet;

    return Consumer<PlaybackViewModel>(
      builder: (context, vm, child) {
        final track = vm.currentTrack;

        if (track == null) {
          return const SizedBox.shrink();
        }

        _updateTint(track.coverArtUrl);
        final tint = _tintColor ?? scheme.primary;

        final position = vm.position;
        final duration = vm.duration;
        final progress = vm.progress;

        return SlideTransition(
          position: _slideAnimation,
          child: isMobile
              ? _buildMobileBar(
                  context,
                  vm,
                  track,
                  scheme,
                  position,
                  duration,
                  progress,
                  tint,
                )
              : _buildDesktopBar(
                  context,
                  vm,
                  track,
                  scheme,
                  position,
                  duration,
                  progress,
                  tint,
                ),
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
    Color tint,
  ) {
    // Below this width four 44px targets plus artwork leave the title unreadable.
    final showFavorite = MediaQuery.of(context).size.width >= 380;

    return GestureDetector(
      onTap: widget.onTap,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(OmnisonicRadius.xxl),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Column(
            children: [
              // Thin progress bar at top
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(OmnisonicRadius.xxl),
                ),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(tint),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Artwork. Tag matches full_screen_player.dart's
                      // artwork so opening the player animates the cover
                      // continuously instead of a hard cut.
                      Hero(
                        tag: 'now-playing-artwork-${track.id}',
                        child: Container(
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
                                    imageUrl: track.coverArtUrl!
                                        .withCoverArtSize(128),
                                    cacheKey: track.coverArtUrl!
                                        .withCoverArtSize(128)
                                        .subsonicCacheKey,
                                    cacheManager:
                                        OmnisonicImageCacheManager.instance,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 88,
                                    memCacheHeight: 88,
                                    fadeInDuration: const Duration(
                                      milliseconds: 120,
                                    ),
                                    useOldImageOnUrlChange: true,
                                    placeholder: (context, url) =>
                                        _buildFallbackArtwork(),
                                    errorWidget: (context, url, error) =>
                                        _buildFallbackArtwork(),
                                  )
                                : _buildFallbackArtwork(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Title + Artist
                      Expanded(
                        child: Semantics(
                          button: true,
                          onTap: widget.onTap,
                          label: _nowPlayingLabel(track),
                          excludeSemantics: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                track.title,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Compact controls. Every target is at least 44x44 with an
                      // 8px gap, so on the narrowest phones the favourite button
                      // is dropped rather than squeezing the track title away.
                      if (showFavorite) ...[
                        Consumer<PlaybackViewModel>(
                          builder: (context, vm, child) {
                            final isStarred = track.isStarred;
                            return _iconBtn(
                              isStarred
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              20,
                              isStarred
                                  ? OmnisonicColors.favoriteIndicator
                                  : scheme.onSurface.withValues(alpha: 0.7),
                              () => vm.toggleFavorite(track),
                              label: isStarred
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      _iconBtn(
                        Icons.skip_previous,
                        22,
                        vm.hasPrevious
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.3),
                        vm.hasPrevious ? () => vm.skipToPrevious() : null,
                        label: 'Previous track',
                      ),
                      const SizedBox(width: 8),
                      _playPauseBtn(vm, scheme),
                      if (showFavorite) ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 18,
                          height: 16,
                          // AudioVisualizer's equalizer bars assume a ~300px
                          // wide layout (fixed bar-width formula), so at
                          // this icon size it overflows badly — a small
                          // dedicated widget instead.
                          child: Center(
                            child: _MiniEqualizer(
                              isPlaying: vm.isPlaying,
                              color: tint,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _iconBtn(
                        Icons.skip_next,
                        22,
                        vm.hasNext
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.3),
                        vm.hasNext ? () => vm.skipToNext() : null,
                        label: 'Next track',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    Color tint,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
        child: Stack(
          children: [
            GlassPanel(
              borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 88,
                child: Row(
                  children: [
                    // === LEFT: Artwork + Track Info ===
                    _buildLeftSection(track, scheme),
                    // === CENTER: Controls + Progress ===
                    Expanded(
                      child: _buildCenterSection(
                        vm,
                        scheme,
                        position,
                        duration,
                        progress,
                        tint,
                      ),
                    ),
                    // === RIGHT: Utility Icons ===
                    _buildRightSection(context, scheme),
                  ],
                ),
              ),
            ),
            Positioned.fill(child: IgnorePointer(child: _buildSheenOverlay())),
          ],
        ),
      ),
    );
  }

  /// Slow diagonal light sweep across the glass bar — purely decorative,
  /// wrapped in [IgnorePointer] (by the caller) so it never intercepts taps.
  Widget _buildSheenOverlay() {
    return AnimatedBuilder(
      animation: _sheenController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final dx = -width * 0.5 + _sheenController.value * width * 1.6;
            return ClipRect(
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    width: width * 0.2,
                    height: height * 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Screen-reader description of the bar's content: without it the artwork
  /// and the two truncated text lines are announced as disconnected fragments.
  String _nowPlayingLabel(Track track) {
    final base = 'Now playing: ${track.title} by ${track.artist}';
    return widget.onTap == null ? base : '$base. Open player';
  }

  Widget _buildLeftSection(Track track, ColorScheme scheme) {
    return Semantics(
      button: widget.onTap != null,
      onTap: widget.onTap,
      label: _nowPlayingLabel(track),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Album artwork. Tag matches full_screen_player.dart's
                // artwork so opening the player animates the cover
                // continuously instead of a hard cut.
                Hero(
                  tag: 'now-playing-artwork-${track.id}',
                  child: Container(
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
                              imageUrl: track.coverArtUrl!.withCoverArtSize(
                                128,
                              ),
                              cacheKey: track.coverArtUrl!
                                  .withCoverArtSize(128)
                                  .subsonicCacheKey,
                              cacheManager: OmnisonicImageCacheManager.instance,
                              fit: BoxFit.cover,
                              memCacheWidth: 112,
                              memCacheHeight: 112,
                              fadeInDuration: const Duration(milliseconds: 120),
                              useOldImageOnUrlChange: true,
                              placeholder: (context, url) =>
                                  _buildFallbackArtwork(),
                              errorWidget: (context, url, error) =>
                                  _buildFallbackArtwork(),
                            )
                          : _buildFallbackArtwork(),
                    ),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
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
      ),
    );
  }

  Widget _buildCenterSection(
    PlaybackViewModel vm,
    ColorScheme scheme,
    Duration position,
    Duration duration,
    double progress,
    Color tint,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Playback controls row. Horizontally scrollable rather than a
        // plain Row: at narrower "desktop" widths (this section only gets
        // whatever's left after the fixed-width left/right sections) six
        // 44px touch targets don't always fit, so this degrades to a
        // scroll instead of a hard overflow.
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBtn(
                  Icons.stop,
                  18,
                  scheme.onSurfaceVariant,
                  () => vm.stop(),
                  label: 'Stop',
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  Icons.shuffle,
                  18,
                  vm.shuffleEnabled ? scheme.primary : scheme.onSurfaceVariant,
                  () => vm.toggleShuffleMode(),
                  label: vm.shuffleEnabled ? 'Shuffle on' : 'Shuffle off',
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  Icons.skip_previous,
                  22,
                  vm.hasPrevious
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.3),
                  vm.hasPrevious ? () => vm.skipToPrevious() : null,
                  label: 'Previous track',
                ),
                const SizedBox(width: 8),
                // Play/Pause - prominent circular button
                _playPauseBtn(vm, scheme),
                const SizedBox(width: 8),
                _iconBtn(
                  Icons.skip_next,
                  22,
                  vm.hasNext
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.3),
                  vm.hasNext ? () => vm.skipToNext() : null,
                  label: 'Next track',
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  _repeatIcon(vm.repeatMode),
                  18,
                  vm.repeatMode != playback.RepeatMode.none
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  () => vm.toggleRepeatMode(),
                  label: _repeatLabel(vm.repeatMode),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Progress bar with timestamps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Flexible (not a bare Text) so at narrow desktop widths this
              // shrinks instead of forcing a hard overflow alongside the
              // Expanded slider.
              Flexible(
                child: Text(
                  _formatDuration(
                    _draggingProgress == null
                        ? position
                        : duration * _draggingProgress!,
                  ),
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: tint,
                    inactiveTrackColor: scheme.surfaceContainerHighest,
                    thumbColor: tint,
                  ),
                  child: Slider(
                    value: _draggingProgress ?? progress.clamp(0.0, 1.0),
                    label: _formatDuration(
                      duration * (_draggingProgress ?? progress),
                    ),
                    onChanged: (value) {
                      setState(() => _draggingProgress = value);
                    },
                    onChangeEnd: (value) {
                      setState(() => _draggingProgress = null);
                      vm.seekToProgress(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _formatDuration(duration),
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSection(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(
            Icons.lyrics_outlined,
            18,
            scheme.onSurfaceVariant,
            () => GoRouter.of(
              context,
            ).push(AppRouter.nowPlaying, extra: NowPlayingPanel.lyrics),
            label: 'Lyrics',
          ),
          const SizedBox(width: 8),
          _iconBtn(
            Icons.queue_music,
            18,
            scheme.onSurfaceVariant,
            () => GoRouter.of(context).push(AppRouter.queue),
            label: 'Queue',
          ),
          const SizedBox(width: 8),
          _iconBtn(
            Icons.open_in_full,
            16,
            scheme.onSurfaceVariant,
            widget.onTap,
            label: 'Expand player',
          ),
          const SizedBox(width: 12),
          Consumer<PlaybackViewModel>(
            builder: (context, vm, child) {
              final track = vm.currentTrack;
              final isStarred = track?.isStarred ?? false;

              return _iconBtn(
                isStarred ? Icons.favorite : Icons.favorite_border,
                18,
                isStarred
                    ? OmnisonicColors.favoriteIndicator
                    : scheme.onSurfaceVariant,
                track != null ? () => vm.toggleFavorite(track) : null,
                label: isStarred ? 'Remove from favorites' : 'Add to favorites',
              );
            },
          ),
          const SizedBox(width: 8),
          Consumer<PlaybackViewModel>(
            builder: (context, vm, child) {
              final volume = vm.volume.clamp(0.0, 1.0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(
                    _volumeIcon(volume),
                    18,
                    scheme.onSurfaceVariant,
                    () => _toggleMute(vm),
                    label: volume > 0 ? 'Mute' : 'Unmute',
                  ),
                  const SizedBox(width: 8),
                  // Volume slider
                  SizedBox(
                    width: 80,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 4,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 8,
                        ),
                        activeTrackColor: scheme.onSurfaceVariant,
                        inactiveTrackColor: scheme.surfaceContainerHighest,
                        thumbColor: scheme.onSurfaceVariant,
                      ),
                      child: Slider(
                        value: volume,
                        label: '${(volume * 100).round()}%',
                        semanticFormatterCallback: (value) =>
                            'Volume ${(value * 100).round()}%',
                        onChanged: (value) => vm.setVolume(value),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Icon control sized to the WCAG minimum touch target.
  ///
  /// [label] is required: it is both the tooltip and the screen-reader label,
  /// so every control in the bar is announced by name.
  Widget _iconBtn(
    IconData icon,
    double size,
    Color color,
    VoidCallback? onPressed, {
    required String label,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size, color: color),
      iconSize: size,
      tooltip: label,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(
        minWidth: OmnisonicTouchTargets.minimum,
        minHeight: OmnisonicTouchTargets.minimum,
      ),
    );
  }

  /// Circular play/pause button, sized to the comfortable touch target.
  Widget _playPauseBtn(PlaybackViewModel vm, ColorScheme scheme) {
    return Container(
      width: OmnisonicTouchTargets.iconButton,
      height: OmnisonicTouchTargets.iconButton,
      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(
          vm.isPlaying ? Icons.pause : Icons.play_arrow,
          color: scheme.onPrimary,
        ),
        iconSize: 24,
        padding: EdgeInsets.zero,
        tooltip: vm.isPlaying ? 'Pause' : 'Play',
        onPressed: () => vm.togglePlayPause(),
      ),
    );
  }

  IconData _repeatIcon(playback.RepeatMode mode) {
    return mode == playback.RepeatMode.one ? Icons.repeat_one : Icons.repeat;
  }

  String _repeatLabel(playback.RepeatMode mode) {
    switch (mode) {
      case playback.RepeatMode.none:
        return 'Repeat off';
      case playback.RepeatMode.all:
        return 'Repeat all';
      case playback.RepeatMode.one:
        return 'Repeat one';
    }
  }

  IconData _volumeIcon(double volume) {
    if (volume <= 0) return Icons.volume_off;
    if (volume < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }

  /// Mutes to zero, remembering the previous level so the icon can restore it.
  void _toggleMute(PlaybackViewModel vm) {
    if (vm.volume > 0) {
      _volumeBeforeMute = vm.volume;
      vm.setVolume(0);
    } else {
      vm.setVolume(_volumeBeforeMute);
    }
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

/// Tiny 3-bar equalizer indicator, sized for an icon-sized slot next to the
/// play/pause button (unlike [AudioVisualizer]'s equalizer mode, which
/// assumes a much wider layout).
class _MiniEqualizer extends StatefulWidget {
  const _MiniEqualizer({required this.isPlaying, required this.color});

  final bool isPlaying;
  final Color color;

  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with TickerProviderStateMixin {
  static const _barCount = 3;
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _barCount,
      (i) => AnimationController(
        duration: Duration(milliseconds: 320 + i * 90),
        vsync: this,
      ),
    );
    if (widget.isPlaying) _start();
  }

  void _start() {
    for (final controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stop() {
    for (final controller in _controllers) {
      controller.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _MiniEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _start() : _stop();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _barCount; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, child) {
              final height = 4 + _controllers[i].value * 10;
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
