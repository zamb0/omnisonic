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
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/formatters.dart';
import '../../../ui/presentation/widgets/cover_art.dart';
import '../../../ui/presentation/widgets/now_playing_equalizer.dart';
import 'remote_playback_bar.dart';
import 'transport_controls.dart';
import '../../data/datasources/handoff_service.dart';
import '../../../ui/presentation/widgets/art_tint.dart';

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
    this.spacing = EdgeInsets.zero,
  });

  final VoidCallback? onTap;

  /// Space around the bar that belongs to it — and so collapses with it when
  /// nothing is playing. The shells used to put this gap outside the bar,
  /// which left an empty strip above the nav pills with no track loaded.
  final EdgeInsets spacing;

  @override
  State<AnimatedNowPlayingBar> createState() => _AnimatedNowPlayingBarState();
}

class _AnimatedNowPlayingBarState extends State<AnimatedNowPlayingBar>
    with TickerProviderStateMixin, ArtTintMixin {
  bool _hoveringVolume = false;
  late final AnimationController _revealController = AnimationController(
    duration: AnimationManager.normalDuration,
    vsync: this,
  )..addStatusListener(_onRevealStatus);
  late final CurvedAnimation _reveal = CurvedAnimation(
    parent: _revealController,
    curve: AnimationManager.standardCurve,
  );

  /// The track the bar is drawing. Outlives `currentTrack` by the length of
  /// the exit animation, so the bar collapses showing what was playing
  /// instead of vanishing the moment the queue is cleared.
  Track? _displayedTrack;
  bool _revealInitialised = false;

  /// Volume to restore when un-muting from the bar's volume icon.
  double _volumeBeforeMute = 1.0;

  /// Position under the finger on the desktop scrubber, or null when not
  /// dragging.
  /// While dragging we show the local value and only seek on release, so a drag
  /// costs one seek instead of one per pointer move.
  Duration? _scrub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _revealController.duration = AnimationUtils.adjustedDuration(
      context,
      AnimationManager.normalDuration,
    );
  }

  /// Grows the bar in when a track arrives and collapses it when playback is
  /// cleared.
  ///
  /// The bar used to slide up from below its own slot. On the phone that
  /// slot is right above the nav pills, so the bar slid in *over* them while
  /// the pills had already jumped to make room; and on the way out it skipped
  /// the animation altogether, because the build returned an empty box as
  /// soon as the track was gone.
  void _handleTrackChange(Track? currentTrack) {
    if (!_revealInitialised) {
      _revealInitialised = true;
      // Already playing when the bar mounts — the window crossed a breakpoint
      // and the other shell built a fresh bar. Nothing arrived, so nothing
      // animates.
      if (currentTrack != null) {
        _displayedTrack = currentTrack;
        _revealController.value = 1;
        return;
      }
    }
    if (currentTrack != null) {
      _displayedTrack = currentTrack;
      if (!_revealController.isForwardOrCompleted) _revealController.forward();
    } else if (_displayedTrack != null &&
        _revealController.isForwardOrCompleted) {
      _revealController.reverse();
    }
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() => _displayedTrack = null);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _revealController.dispose();
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

    // Only what the bar's chrome shows. The position ticks four times a
    // second while playing, and the bar used to rebuild — glass, artwork,
    // every control — on each tick, twice over: a listening Provider.of in
    // didChangeDependencies and a Consumer. The progress line and the
    // scrubber follow the position on their own.
    final currentTrack = context.select<PlaybackViewModel, Track?>(
      (vm) => vm.currentTrack,
    );
    context.select<PlaybackViewModel, Object>(
      (vm) => (
        vm.isPlaying,
        vm.hasNext,
        vm.hasPrevious,
        vm.shuffleEnabled,
        vm.repeatMode,
        vm.volume,
      ),
    );
    // Another device playing while this one does not takes the bar over:
    // its track and progress, and "Continue here" instead of the controls.
    final remote = context.select<PlaybackViewModel, RemoteNowPlaying?>(
      (vm) => vm.isPlaying ? null : vm.remoteNowPlaying,
    );
    final vm = context.read<PlaybackViewModel>();

    _handleTrackChange(remote?.track ?? currentTrack);
    final track = remote?.track ?? currentTrack ?? _displayedTrack;
    if (track == null) {
      return const SizedBox.shrink();
    }

    updateArtTint(track.coverArtUrl);
    final tint = artTint ?? scheme.primary;

    final bar = remote != null
        ? RemotePlaybackBar(
            remote: remote,
            onContinue: vm.continueRemoteSession,
            compact: isMobile,
          )
        : isMobile
        ? _buildMobileBar(context, vm, track, scheme, tint)
        // The bar's own width, not the window's: beside a sidebar the
        // two differ by up to 234pt.
        : LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth < _desktopBarMinWidth
                ? _buildTabletBar(context, vm, track, scheme, tint)
                : _buildDesktopBar(context, vm, track, scheme),
          );

    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, child) {
        final t = _reveal.value.clamp(0.0, 1.0);
        // Clipped only while growing or collapsing: at rest the glass pane's
        // shadow reaches past the bar's bounds and a permanent clip would cut
        // it off. Only the clip behaviour changes, never the widgets, so the
        // subtree is kept.
        return ClipRect(
          clipBehavior: t >= 1 ? Clip.none : Clip.hardEdge,
          child: Align(
            // Anchored to the edge nearest the nav: the bar rises out of it.
            alignment: Alignment.bottomCenter,
            heightFactor: t,
            child: Opacity(opacity: t, child: child),
          ),
        );
      },
      child: Padding(padding: widget.spacing, child: bar),
    );
  }

  /// Window heights below this get the compact one-row bar.
  static const double _compactBarMaxHeight = 500;

  /// Below this bar width (an iPad, a narrow Mac window) the three-column
  /// transport bar gives way to the tablet bar: one row, like the phone's
  /// mini player, with scrubbing left to Now Playing. Squeezed into ~690pt
  /// the three columns lost their alignment and the scrubber shrank to
  /// ~100pt.
  static const double _desktopBarMinWidth = 900;

  /// Height of the tablet bar's row, progress line excluded.
  static const double _tabletBarHeight = 72;

  /// Height of the desktop bar.
  static const double _desktopBarHeight = 96;

  /// Space between the desktop bar's top edge and the play disc.
  ///
  /// The centre column used to be centred by its box, but the bottom half
  /// of the scrubber's hit area is invisible: the disc sat 4 px under the
  /// bar's top edge with ~18 px of empty glass under the seek line. This
  /// puts the disc's top and the line's bottom equally far from the edges.
  static const double _desktopTopInset =
      (_desktopBarHeight - _desktopVisibleCentre) / 2;

  /// From the play disc's top to the seek line's bottom edge.
  static const double _desktopVisibleCentre =
      _transportHeight +
      OmnisonicSpacing.xs +
      (AuroraProgress.hitHeight + AuroraProgress.trackHeight) / 2;

  /// The transport row: as tall as the play disc ([PlayDiscSize.s48]).
  static const double _transportHeight = 48;

  /// How far the side sections are lifted so their icons share the transport
  /// row's centre line instead of the bar's.
  static const double _sideLift =
      _desktopBarHeight - 2 * (_desktopTopInset + _transportHeight / 2);

  /// Flick speed, in logical pixels per second, that counts as a gesture
  /// rather than a stray drag while scrolling the page behind.
  static const double _flickVelocity = 300;

  /// Compact mobile bar: artwork + info + controls, with a thin progress bar on top
  Widget _buildMobileBar(
    BuildContext context,
    PlaybackViewModel vm,
    Track track,
    ColorScheme scheme,
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
                  const _LiveProgressLine(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tablet bar: the phone's mini player, wider. One row on one centre line —
  /// track, transport, actions — with the Aurora progress line on the bottom
  /// edge. Equal flex either side keeps Play on the bar's centre whatever the
  /// title's length.
  Widget _buildTabletBar(
    BuildContext context,
    PlaybackViewModel vm,
    Track track,
    ColorScheme scheme,
    Color tint,
  ) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
      padding: EdgeInsets.zero,
      child: ColoredBox(
        // The cover's colour tints the glass at 12 %, as on the phone.
        color: tint.withValues(alpha: 0.12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _tabletBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OmnisonicSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTrackInfo(
                        track,
                        scheme,
                        artworkSize: 48,
                        showQuality: false,
                      ),
                    ),
                    const SizedBox(width: OmnisonicSpacing.md),
                    _buildTransport(vm, withModes: false),
                    const SizedBox(width: OmnisonicSpacing.md),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildRightSection(
                          context,
                          scheme,
                          showTextActions: false,
                          showVolume: false,
                          showVolumeSlider: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _LiveProgressLine(),
          ],
        ),
      ),
    );
  }

  /// Desktop bar: three columns, the outer two of equal width so the
  /// transport is centred on the bar. The centre column is the transport row
  /// over a scrubber as wide as the column; the side sections are lifted to
  /// the transport row's centre line.
  ///
  /// A floating pill inset from the window edges, not a full-bleed footer —
  /// the art-tinted background has to stay visible around it.
  Widget _buildDesktopBar(
    BuildContext context,
    PlaybackViewModel vm,
    Track track,
    ColorScheme scheme,
  ) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: _desktopBarHeight,
        child: Stack(
          children: [
            const Positioned.fill(child: GlassSheen()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OmnisonicSpacing.md,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final centre = (width * 0.42).clamp(340.0, 560.0);
                  // What each side section actually gets: the trailing
                  // controls drop out in order as it narrows.
                  final side = (width - centre) / 2 - OmnisonicSpacing.md;
                  final showTextActions = side >= 330;
                  final showVolumeSlider =
                      side >= (showTextActions ? 420 : 320);
                  const lift = EdgeInsets.only(bottom: _sideLift);
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: lift,
                          child: _buildTrackInfo(
                            track,
                            scheme,
                            artworkSize: 48,
                            showQuality: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: OmnisonicSpacing.md),
                      SizedBox(
                        width: centre,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: _desktopTopInset,
                            ),
                            child: _buildCenterSection(vm, scheme),
                          ),
                        ),
                      ),
                      const SizedBox(width: OmnisonicSpacing.md),
                      Expanded(
                        child: Padding(
                          padding: lift,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildRightSection(
                              context,
                              scheme,
                              showTextActions: showTextActions,
                              showVolume: true,
                              showVolumeSlider: showVolumeSlider,
                            ),
                          ),
                        ),
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

  /// Artwork and track text; the whole block opens the full player.
  Widget _buildTrackInfo(
    Track track,
    ColorScheme scheme, {
    required double artworkSize,
    required bool showQuality,
  }) {
    return Semantics(
      button: widget.onTap != null,
      onTap: widget.onTap,
      label: _nowPlayingLabel(track),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            // Tag matches full_screen_player.dart's artwork so opening the
            // player animates the cover continuously instead of a hard cut.
            Hero(
              tag: 'now-playing-artwork-${track.id}',
              child: CoverArt(
                url: track.coverArtUrl,
                seed: track.albumId ?? track.id,
                size: artworkSize,
                radius: OmnisonicRadius.md,
                elevated: true,
              ),
            ),
            const SizedBox(width: OmnisonicSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.title,
                    style: OmnisonicTypography.cardTitle.copyWith(
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: OmnisonicSpacing.xxs),
                  Text(
                    track.artist,
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showQuality) ...[
                    const SizedBox(height: OmnisonicSpacing.xxs),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Previous, Play, Next; with [withModes] also Shuffle and Repeat outside
  /// them. Every target 44 or more, 8 apart.
  Widget _buildTransport(PlaybackViewModel vm, {required bool withModes}) {
    const gap = SizedBox(width: OmnisonicSpacing.sm);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (withModes) ...[
          ShuffleModeButton(playback: vm, size: OmnisonicIconSizes.smd),
          gap,
        ],
        SkipPreviousButton(playback: vm),
        gap,
        PlayPauseButton(playback: vm),
        gap,
        SkipNextButton(playback: vm),
        if (withModes) ...[
          gap,
          RepeatModeButton(playback: vm, size: OmnisonicIconSizes.smd),
        ],
      ],
    );
  }

  /// Transport row over a scrubber as wide as the column, its timestamps in
  /// fixed slots so the line does not shift as the numbers change.
  Widget _buildCenterSection(PlaybackViewModel vm, ColorScheme scheme) {
    final timeStyle = OmnisonicTypography.technical.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget time(Duration value, Alignment alignment) => SizedBox(
      width: _timeSlotWidth,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatDuration(value), maxLines: 1, style: timeStyle),
        ),
      ),
    );

    // Top-aligned: the desktop bar places it with [_desktopTopInset].
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTransport(vm, withModes: true),
        const SizedBox(height: OmnisonicSpacing.xs),
        // The only part of the bar that follows the position, so the only
        // part that listens for it.
        Builder(
          builder: (context) {
            final (position, duration) = context
                .select<PlaybackViewModel, (Duration, Duration)>(
                  (vm) => (vm.position, vm.duration),
                );
            return Row(
              children: [
                time(_scrub ?? position, Alignment.centerRight),
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
                time(duration, Alignment.centerLeft),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Room for "59:59"; longer times scale down rather than shift the line.
  static const double _timeSlotWidth = 44;

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
      trackHeight: AuroraProgress.trackHeight,
      trackShape: const _EvenSliderTrackShape(),
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
    required bool showVolume,
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
        // Hardware buttons own the volume on a tablet.
        if (showVolume)
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
                          // The icons' grey, not ink: at full volume a solid
                          // onSurface bar was the heaviest thing in the bar.
                          // The empty part is the seek line's track.
                          data: _hairlineSliderTheme(
                            context,
                            activeColor: scheme.onSurfaceVariant,
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
        // Expand: a plain icon like its neighbours — the well-filled disc it
        // had was the one control in the row with a different weight.
        _iconBtn(
          OmnisonicIcons.openInFull,
          OmnisonicIconSizes.smd,
          scheme.onSurfaceVariant,
          widget.onTap,
          label: 'Expand player',
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

/// The bar's 2 px Aurora progress line: the one part of the phone and tablet
/// bars that changes with the position, so the only part that listens for it.
class _LiveProgressLine extends StatelessWidget {
  const _LiveProgressLine();

  @override
  Widget build(BuildContext context) {
    final progress = context.select<PlaybackViewModel, double>(
      (vm) => vm.progress,
    );
    return RepaintBoundary(child: AuroraProgressLine(fraction: progress));
  }
}

/// [RoundedRectSliderTrackShape] with the filled part as thick as the rest.
///
/// Material draws the active track 2 px taller, so the volume slider's fill
/// was 6 px beside the seek line's 4 and read as a solid black pill.
class _EvenSliderTrackShape extends RoundedRectSliderTrackShape {
  const _EvenSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: 0,
    );
  }
}
