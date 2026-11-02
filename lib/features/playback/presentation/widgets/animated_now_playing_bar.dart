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
import '../../../ui/presentation/widgets/server_dot.dart';
import '../viewmodels/playback_view_model.dart';
import '../../../ui/presentation/pages/main_shell.dart';
import 'full_screen_player.dart' show NowPlayingPanel;
import '../../../../core/utils/haptics.dart';

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
  /// Material's disabled-content opacity. Lower reads as decoration rather
  /// than as a control that is merely unavailable right now.
  static const double _disabledAlpha = 0.38;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
    // Asking the shell which chrome it picked, rather than re-deriving it from
    // the screen width: this bar sits inside a column narrowed by the sidebar,
    // so the two answers disagree around the breakpoints.
    final isMobile = !ShellLayout.hasSidebar(context);

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

  /// Flick speed, in logical pixels per second, that counts as a gesture
  /// rather than a stray drag while scrolling the page behind.
  static const double _flickVelocity = 300;

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

    // The whole bar is tappable, so it needs to announce itself as one
    // control rather than as an unlabelled region containing others — a
    // screen reader otherwise reads "0", the progress indicator's value.
    return Semantics(
      button: true,
      label:
          'Now playing: ${track.title} by ${track.artist}. '
          'Open the full player.',
      child: GestureDetector(
        onTap: widget.onTap,
        // Flick up to expand, flick sideways to change track. The bar was
        // tap-only, which meant the one control always on screen did one
        // thing. Velocity rather than distance: the bar is 64px tall and
        // sits over the nav pills, so there is no room for a drag threshold.
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -_flickVelocity) {
            Haptics.impact();
            widget.onTap?.call();
          }
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < _flickVelocity) return;
          // Swiping left moves forward, matching the direction the queue
          // travels rather than the direction of the finger.
          if (velocity < 0 && vm.hasNext) {
            Haptics.selection();
            vm.skipToNext();
          } else if (velocity > 0 && vm.hasPrevious) {
            Haptics.selection();
            vm.skipToPrevious();
          }
        },
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
                              borderRadius: BorderRadius.circular(
                                OmnisonicRadius.xs,
                              ),
                              color: scheme.surfaceContainerHighest,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                OmnisonicRadius.xs,
                              ),
                              child: track.coverArtUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: SubsonicCoverArt.of(
                                        track.coverArtUrl!,
                                        128,
                                      ).url,
                                      cacheKey: SubsonicCoverArt.of(
                                        track.coverArtUrl!,
                                        128,
                                      ).cacheKey,
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
                                        fontSize: 12,
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
                                    ? OmnisonicIcons.favorite
                                    : OmnisonicIcons.favoriteOutline,
                                20,
                                isStarred
                                    ? OmnisonicColors.favoriteIndicator
                                    : scheme.onSurface.withValues(alpha: 0.7),
                                () {
                                  Haptics.success();
                                  vm.toggleFavorite(track);
                                },
                                label: isStarred
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                toggled: isStarred,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        _iconBtn(
                          OmnisonicIcons.skipPrevious,
                          22,
                          vm.hasPrevious
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(
                                  alpha: _disabledAlpha,
                                ),
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
                          OmnisonicIcons.skipNext,
                          22,
                          vm.hasNext
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(
                                  alpha: _disabledAlpha,
                                ),
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
      ),
    );
  }

  /// Full desktop 3-section bar: left (artwork+info), center
  /// (controls+scrubber), right (lyrics/queue/volume).
  ///
  /// A floating pill inset from the window edges, not a full-bleed footer —
  /// the art-tinted background has to stay visible around it.
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
    return GlassPanel(
      borderRadius: BorderRadius.circular(OmnisonicRadius.xxl),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 96,
        child: Stack(
          children: [
            const Positioned.fill(child: GlassSheen()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // The side sections are fixed-width so the centre controls stay
              // put as the track title changes; that only works while the
              // window is wide enough to hold them, so the trailing controls
              // drop out in order as it narrows.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final showTextActions = width >= 900;
                  final showVolumeSlider = width >= 1040;
                  return Row(
                    children: [
                      // === LEFT: Artwork + Track Info ===
                      _buildLeftSection(
                        track,
                        scheme,
                        width: showTextActions ? 260 : 180,
                      ),
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
                      _buildRightSection(
                        context,
                        scheme,
                        showTextActions: showTextActions,
                        showVolumeSlider: showVolumeSlider,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen-reader description of the bar's content: without it the artwork
  /// and the two truncated text lines are announced as disconnected fragments.
  String _nowPlayingLabel(Track track) {
    final base = 'Now playing: ${track.title} by ${track.artist}';
    return widget.onTap == null ? base : '$base. Open player';
  }

  Widget _buildLeftSection(
    Track track,
    ColorScheme scheme, {
    required double width,
  }) {
    return Semantics(
      button: widget.onTap != null,
      onTap: widget.onTap,
      label: _nowPlayingLabel(track),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: width,
          child: Row(
            children: [
              // Album artwork. Tag matches full_screen_player.dart's
              // artwork so opening the player animates the cover
              // continuously instead of a hard cut.
              Hero(
                tag: 'now-playing-artwork-${track.id}',
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(OmnisonicRadius.art),
                    color: scheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: -8,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(OmnisonicRadius.art),
                    child: track.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: SubsonicCoverArt.of(
                              track.coverArtUrl!,
                              128,
                            ).url,
                            cacheKey: SubsonicCoverArt.of(
                              track.coverArtUrl!,
                              128,
                            ).cacheKey,
                            cacheManager: OmnisonicImageCacheManager.instance,
                            fit: BoxFit.cover,
                            memCacheWidth: 116,
                            memCacheHeight: 116,
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
              const SizedBox(width: 13),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      style: OmnisonicTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: OmnisonicTypography.bold,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: OmnisonicTypography.bodySmall.copyWith(
                        fontWeight: OmnisonicTypography.medium,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Source + quality: the only place the multi-server
                    // machinery surfaces during ordinary playback.
                    Row(
                      children: [
                        ServerDot(serverId: track.serverId, size: 6),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            track.quality.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OmnisonicTypography.technical.copyWith(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
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
    Color tint,
  ) {
    final timeStyle = OmnisonicTypography.technical.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Playback controls row. Horizontally scrollable rather than a
        // plain Row: at narrower "desktop" widths (this section only gets
        // whatever's left after the fixed-width left/right sections) five
        // 44px touch targets don't always fit, so this degrades to a
        // scroll instead of a hard overflow.
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBtn(
                  OmnisonicIcons.shuffle,
                  18,
                  vm.shuffleEnabled
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  () => vm.toggleShuffleMode(),
                  label: vm.shuffleEnabled ? 'Shuffle on' : 'Shuffle off',
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  OmnisonicIcons.skipPrevious,
                  24,
                  vm.hasPrevious
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: _disabledAlpha),
                  vm.hasPrevious ? () => vm.skipToPrevious() : null,
                  label: 'Previous track',
                ),
                const SizedBox(width: 6),
                // Play/Pause - prominent circular button
                _playPauseBtn(vm, scheme),
                const SizedBox(width: 6),
                _iconBtn(
                  OmnisonicIcons.skipNext,
                  24,
                  vm.hasNext
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: _disabledAlpha),
                  vm.hasNext ? () => vm.skipToNext() : null,
                  label: 'Next track',
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  _repeatIcon(vm.repeatMode),
                  18,
                  vm.repeatMode != playback.RepeatMode.none
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  () => vm.toggleRepeatMode(),
                  label: _repeatLabel(vm.repeatMode),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Scrubber: a 4px hairline with mono timestamps either side, capped
        // at the design's 520px so it stays a line rather than a bar.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                  style: timeStyle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: _hairlineSliderTheme(
                    context,
                    activeColor: tint,
                    inactiveColor: scheme.onSurface.withValues(alpha: 0.14),
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
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _formatDuration(duration),
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: timeStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Thumbless 4px track — the redesign treats progress and volume as
  /// hairlines, not as Material sliders. The thumb is sized to zero rather
  /// than removed so [Slider]'s drag handling and semantics stay intact.
  SliderThemeData _hairlineSliderTheme(
    BuildContext context, {
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return SliderTheme.of(context).copyWith(
      trackHeight: 4,
      trackShape: const RoundedRectSliderTrackShape(),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 0,
        disabledThumbRadius: 0,
        pressedElevation: 0,
        elevation: 0,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      activeTrackColor: activeColor,
      inactiveTrackColor: inactiveColor,
      thumbColor: activeColor,
    );
  }

  /// Trailing controls. Sized to its content — a fixed width here overflows
  /// as soon as the controls total more than it, which is what the hard-coded
  /// 250 did.
  Widget _buildRightSection(
    BuildContext context,
    ColorScheme scheme, {
    required bool showTextActions,
    required bool showVolumeSlider,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showTextActions) ...[
          _textBtn(
            'Lyrics',
            scheme,
            () => GoRouter.of(
              context,
            ).push(AppRouter.nowPlaying, extra: NowPlayingPanel.lyrics),
          ),
          const SizedBox(width: 4),
          _textBtn(
            'Queue',
            scheme,
            () => GoRouter.of(context).push(AppRouter.queue),
          ),
          const SizedBox(width: 4),
        ],
        Consumer<PlaybackViewModel>(
          builder: (context, vm, child) {
            final track = vm.currentTrack;
            final isStarred = track?.isStarred ?? false;

            return _iconBtn(
              isStarred
                  ? OmnisonicIcons.favorite
                  : OmnisonicIcons.favoriteOutline,
              17,
              isStarred
                  ? OmnisonicColors.favoriteIndicator
                  : scheme.onSurfaceVariant,
              track != null ? () => vm.toggleFavorite(track) : null,
              label: isStarred ? 'Remove from favorites' : 'Add to favorites',
              toggled: isStarred,
            );
          },
        ),
        Consumer<PlaybackViewModel>(
          builder: (context, vm, child) {
            final volume = vm.volume.clamp(0.0, 1.0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBtn(
                  _volumeIcon(volume),
                  17,
                  scheme.onSurfaceVariant,
                  () => _toggleMute(vm),
                  label: volume > 0 ? 'Mute' : 'Unmute',
                ),
                // Below the threshold the icon alone stays as a mute toggle;
                // the slider is the first thing worth giving up.
                if (showVolumeSlider)
                  SizedBox(
                    width: 70,
                    child: SliderTheme(
                      data: _hairlineSliderTheme(
                        context,
                        activeColor: scheme.onSurface,
                        inactiveColor: scheme.onSurface.withValues(alpha: 0.14),
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
        const SizedBox(width: 8),
        // Expand: a soft-square chip rather than a bare icon, matching the
        // design's trailing control.
        Tooltip(
          message: 'Expand player',
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
              ),
              child: Icon(
                OmnisonicIcons.openInFull,
                size: OmnisonicIconSizes.inline,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Gabarito text action — the design's treatment for the bar's secondary
  /// destinations, which read better as words than as another icon.
  Widget _textBtn(String label, ColorScheme scheme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          label,
          style: OmnisonicTypography.glassButton.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
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

    /// Set for controls that are on/off — favourite, shuffle, repeat — so a
    /// screen reader announces their state, which a tooltip alone does not.
    bool? toggled,
  }) {
    final button = IconButton(
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

    if (toggled == null) return button;
    return Semantics(toggled: toggled, child: button);
  }

  /// Circular play/pause button, sized to the comfortable touch target.
  ///
  /// Solid ink rather than the brand accent: in the redesign this is the one
  /// element allowed to be fully opaque against the glass.
  Widget _playPauseBtn(PlaybackViewModel vm, ColorScheme scheme) {
    return Container(
      width: OmnisonicTouchTargets.iconButton,
      height: OmnisonicTouchTargets.iconButton,
      decoration: BoxDecoration(
        color: scheme.onSurface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: vm.isPlaying ? 'Pause' : 'Play',
        child: IconButton(
          icon: Icon(
            vm.isPlaying ? OmnisonicIcons.pause : OmnisonicIcons.playArrow,
            color: scheme.surface,
          ),
          iconSize: OmnisonicIconSizes.md,
          padding: EdgeInsets.zero,
          tooltip: vm.isPlaying ? 'Pause' : 'Play',
          onPressed: () {
            Haptics.impact();
            vm.togglePlayPause();
          },
        ),
      ),
    );
  }

  IconData _repeatIcon(playback.RepeatMode mode) {
    return mode == playback.RepeatMode.one
        ? OmnisonicIcons.repeatOne
        : OmnisonicIcons.repeat;
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
    if (volume <= 0) return OmnisonicIcons.volumeOff;
    if (volume < 0.5) return OmnisonicIcons.volumeDown;
    return OmnisonicIcons.volumeUp;
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
        OmnisonicIcons.musicNote,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: OmnisonicIconSizes.md,
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
