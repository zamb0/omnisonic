import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../ui/presentation/widgets/server_dot.dart';
import '../viewmodels/playback_view_model.dart';
import '../../../ui/presentation/pages/main_shell.dart';
import 'full_screen_player.dart' show NowPlayingPanel;
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/formatters.dart';
import '../../../ui/presentation/widgets/cover_art.dart';
import '../../../ui/presentation/widgets/now_playing_equalizer.dart';
import 'transport_controls.dart';
import '../../../ui/presentation/widgets/art_tint.dart';

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
    with TickerProviderStateMixin, ArtTintMixin {
  bool _hoveringVolume = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  Track? _previousTrack;

  /// Volume to restore when un-muting from the bar's volume icon.
  double _volumeBeforeMute = 1.0;

  /// Position under the finger on the desktop scrubber, or null when not
  /// dragging.
  /// While dragging we show the local value and only seek on release, so a drag
  /// costs one seek instead of one per pointer move.
  Duration? _scrub;

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

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Asking the shell which chrome it picked, rather than re-deriving it from
    // the screen width: this bar sits inside a column narrowed by the sidebar,
    // so the two answers disagree around the breakpoints.
    //
    // A phone on its side gets the sidebar but is only ~390pt tall: the 96pt
    // three-section bar took a quarter of it and squeezed the scrubber to
    // ~25pt. Short windows use the compact one-row bar instead; the full
    // player still has the seek bar.
    final isMobile =
        !ShellLayout.hasSidebar(context) ||
        MediaQuery.sizeOf(context).height < _compactBarMaxHeight;

    return Consumer<PlaybackViewModel>(
      builder: (context, vm, child) {
        final track = vm.currentTrack;

        if (track == null) {
          return const SizedBox.shrink();
        }

        updateArtTint(track.coverArtUrl);
        final tint = artTint ?? scheme.primary;

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

  /// Window heights below this get the compact one-row bar.
  static const double _compactBarMaxHeight = 500;

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
    final width = MediaQuery.sizeOf(context).width;
    final showFavorite = width >= 380;
    // Below ~420 the title got ~70px and truncated to five characters.
    // Previous and the visualizer go first: swipe right still skips back.
    final roomy = width >= 420;

    // The whole bar is tappable, so it announces itself as one control
    // rather than as an unlabelled region — a screen reader otherwise reads
    // "0", the progress indicator's value. The track info inside used to be
    // a second button with the same label, so the bar was announced twice;
    // it is now plain, excluded text.
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
          borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 64,
            // The cover's colour tints the glass at 12 %.
            child: ColoredBox(
              color: tint.withValues(alpha: 0.12),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OmnisonicSpacing.ms,
                      ),
                      child: Row(
                        children: [
                          // Artwork. Tag matches full_screen_player.dart's
                          // artwork so opening the player animates the cover
                          // continuously instead of a hard cut.
                          Hero(
                            tag: 'now-playing-artwork-${track.id}',
                            child: CoverArt(
                              url: track.coverArtUrl,
                              seed: track.albumId ?? track.id,
                              size: 44,
                              radius: OmnisonicRadius.sm,
                            ),
                          ),
                          const SizedBox(width: OmnisonicSpacing.ms),
                          // Title + Artist
                          Expanded(
                            child: ExcludeSemantics(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    track.title,
                                    style: OmnisonicTypography.cardTitle
                                        .copyWith(color: scheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: OmnisonicSpacing.xxs),
                                  Text(
                                    track.artist,
                                    style: OmnisonicTypography.bodySmall
                                        .copyWith(
                                          color: scheme.onSurfaceVariant,
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
                                // Read the live track: the one captured above
                                // predates the optimistic flip.
                                final live = vm.currentTrack ?? track;
                                final isStarred = live.isStarred;
                                final pending = vm.isFavoritePending(live.id);
                                return _iconBtn(
                                  isStarred
                                      ? OmnisonicIcons.favorite
                                      : OmnisonicIcons.favoriteOutline,
                                  OmnisonicIconSizes.smd,
                                  isStarred
                                      ? OmnisonicBrand.of(context).heat
                                      : scheme.onSurfaceVariant,
                                  pending
                                      ? null
                                      : () {
                                          Haptics.success();
                                          vm.toggleFavorite(live);
                                        },
                                  label: isStarred
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                  toggled: isStarred,
                                );
                              },
                            ),
                            const SizedBox(width: OmnisonicSpacing.sm),
                          ],
                          if (roomy) ...[
                            SkipPreviousButton(playback: vm, size: 22),
                            const SizedBox(width: OmnisonicSpacing.sm),
                          ],
                          PlayPauseButton(playback: vm, size: PlayDiscSize.s44),
                          // Hidden while paused: three still bars read as an
                          // overflow menu.
                          if (roomy && vm.isPlaying) ...[
                            const SizedBox(
                              width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
                            ),
                            SizedBox(
                              width: 18,
                              height: 16,
                              // A small equalizer sized for an icon slot.
                              child: Center(
                                child: NowPlayingEqualizer(
                                  playing: vm.isPlaying,
                                  color: tint,
                                  excludeSemantics: true,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: OmnisonicSpacing.sm),
                          SkipNextButton(playback: vm, size: 22),
                        ],
                      ),
                    ),
                  ),
                  // Progress on the bottom edge, 2 px, Aurora.
                  AuroraProgressLine(fraction: progress),
                ],
              ),
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
      borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 88,
        child: Stack(
          children: [
            const Positioned.fill(child: GlassSheen()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OmnisonicSpacing.md,
              ),
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
                      // Without a gap the quality label ran into the
                      // elapsed time at ~800px.
                      const SizedBox(width: OmnisonicSpacing.md),
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
                child: CoverArt(
                  url: track.coverArtUrl,
                  seed: track.albumId ?? track.id,
                  size: 56,
                  radius: OmnisonicRadius.md,
                  elevated: true,
                ),
              ),
              const SizedBox(width: OmnisonicSpacing.ms),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      style: OmnisonicTypography.titleSmall.copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: OmnisonicTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: OmnisonicSpacing.xs),
                    // Source + quality: the only place the multi-server
                    // machinery surfaces during ordinary playback.
                    Row(
                      children: [
                        ServerDot(serverId: track.serverId, size: 6),
                        const SizedBox(
                          width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
                        ),
                        Flexible(
                          child: Text(
                            track.quality.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OmnisonicTypography.technicalSmall.copyWith(
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
      color: scheme.onSurfaceVariant,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Playback controls row. This section only gets what is left after
        // the fixed-width side sections, and on a portrait tablet that is
        // less than five touch targets with 8px gaps: the gaps tighten
        // first, and only then does the row scale down. It used to scroll
        // instead, which clipped Repeat out of view with no sign it was there.
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 280
                ? OmnisonicSpacing.xxs
                : OmnisonicSpacing.sm;
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShuffleModeButton(playback: vm, size: OmnisonicIconSizes.smd),
                  SizedBox(width: gap),
                  SkipPreviousButton(playback: vm),
                  SizedBox(width: gap),
                  PlayPauseButton(playback: vm),
                  SizedBox(width: gap),
                  SkipNextButton(playback: vm),
                  SizedBox(width: gap),
                  RepeatModeButton(playback: vm, size: OmnisonicIconSizes.smd),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: OmnisonicSpacing.xs),
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
                  formatDuration(_scrub ?? position),
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: timeStyle,
                ),
              ),
              const SizedBox(width: OmnisonicSpacing.ms),
              Expanded(
                child: AuroraProgress(
                  position: position,
                  duration: duration,
                  onChanged: (value) => setState(() => _scrub = value),
                  onSeek: vm.seek,
                ),
              ),
              const SizedBox(width: OmnisonicSpacing.ms),
              Flexible(
                child: Text(
                  formatDuration(duration),
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

  /// The volume slider's hairline: 4 px, with a thumb only while the pointer
  /// is over it or dragging. (The seek bar is [AuroraProgress]; a generic
  /// slider token replaces this in D3.)
  SliderThemeData _hairlineSliderTheme(
    BuildContext context, {
    required Color activeColor,
    required Color inactiveColor,
    bool active = false,
  }) {
    final radius = active ? 6.0 : 0.0;
    return SliderTheme.of(context).copyWith(
      trackHeight: 4,
      trackShape: const RoundedRectSliderTrackShape(),
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: radius,
        disabledThumbRadius: radius,
        pressedElevation: 0,
        elevation: 0,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      overlayColor: activeColor.withValues(alpha: 0.12),
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
        // Words where there is room, icons where there is not — they used to
        // disappear below 900px with no other way in from the bar.
        if (showTextActions) ...[
          _textBtn('Lyrics', scheme, () => _openLyrics(context)),
          _textBtn('Queue', scheme, () => _openQueue(context)),
          const SizedBox(width: OmnisonicSpacing.xs),
        ] else ...[
          _iconBtn(
            OmnisonicIcons.lyrics,
            OmnisonicIconSizes.smd,
            scheme.onSurfaceVariant,
            () => _openLyrics(context),
            label: 'Lyrics',
          ),
          _iconBtn(
            OmnisonicIcons.queueMusic,
            OmnisonicIconSizes.smd,
            scheme.onSurfaceVariant,
            () => _openQueue(context),
            label: 'Queue',
          ),
        ],
        Consumer<PlaybackViewModel>(
          builder: (context, vm, child) {
            final track = vm.currentTrack;
            final isStarred = track?.isStarred ?? false;

            return _iconBtn(
              isStarred
                  ? OmnisonicIcons.favorite
                  : OmnisonicIcons.favoriteOutline,
              OmnisonicIconSizes.smd,
              isStarred
                  ? OmnisonicBrand.of(context).heat
                  : scheme.onSurfaceVariant,
              track != null && !vm.isFavoritePending(track.id)
                  ? () => vm.toggleFavorite(track)
                  : null,
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
                  OmnisonicIconSizes.smd,
                  scheme.onSurfaceVariant,
                  () => _toggleMute(vm),
                  label: volume > 0 ? 'Mute' : 'Unmute',
                ),
                // Below the threshold the icon alone stays as a mute toggle;
                // the slider is the first thing worth giving up.
                if (showVolumeSlider)
                  SizedBox(
                    width: 80,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveringVolume = true),
                      onExit: (_) => setState(() => _hoveringVolume = false),
                      child: SliderTheme(
                        data: _hairlineSliderTheme(
                          context,
                          activeColor: scheme.onSurface,
                          inactiveColor: scheme.onSurface.withValues(
                            alpha: 0.14,
                          ),
                          active: _hoveringVolume,
                        ),
                        child: Slider(
                          value: volume,
                          semanticFormatterCallback: (value) =>
                              'Volume ${(value * 100).round()}%',
                          onChanged: (value) => vm.setVolume(value),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: OmnisonicSpacing.sm),
        // Expand: a well-filled disc rather than a bare icon — drawn at
        // 32px, hit-tested at 44.
        IconButton(
          onPressed: widget.onTap,
          tooltip: 'Expand player',
          icon: const Icon(OmnisonicIcons.openInFull),
          iconSize: OmnisonicIconSizes.sm,
          color: scheme.onSurface,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(32),
            minimumSize: const Size.square(32),
            tapTargetSize: MaterialTapTargetSize.padded,
            backgroundColor: OmnisonicSurfaces.of(context).well,
            side: BorderSide(color: OmnisonicSurfaces.of(context).hairline),
          ),
        ),
      ],
    );
  }

  /// Opens the queue, unless it is already the page on screen — repeated
  /// clicks used to stack duplicate queue pages.
  void _openQueue(BuildContext context) {
    if (GoRouterState.of(context).uri.path == AppRouter.queue) return;
    GoRouter.of(context).push(AppRouter.queue);
  }

  void _openLyrics(BuildContext context) => GoRouter.of(
    context,
  ).push(AppRouter.nowPlaying, extra: NowPlayingPanel.lyrics);

  /// Gabarito text action — the design's treatment for the bar's secondary
  /// destinations, which read better as words than as another icon.
  Widget _textBtn(String label, ColorScheme scheme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.ms,
          vertical: OmnisonicSpacing.ms,
        ),
        child: Text(
          label,
          style: OmnisonicTypography.glassButton.copyWith(
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
}
