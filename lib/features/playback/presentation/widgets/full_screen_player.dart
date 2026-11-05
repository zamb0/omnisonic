import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/animation_utils.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/entities/entities.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../ui/presentation/widgets/widgets.dart';
import '../viewmodels/playback_view_model.dart';
import '../../../lyrics/presentation/widgets/lyrics_panel.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/formatters.dart';
import '../pages/player_page.dart';
import 'transport_controls.dart';
import 'package:flutter/services.dart';

/// Full-screen player with a clean Feishin-inspired layout
class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key, this.initialPanel});

  /// Strength of the Aurora mesh over the cover tint (§9.6: 30 %).
  static const double meshOpacity = 0.3;

  /// Which of Queue/Lyrics/Visualizer to open on, so callers (e.g. the
  /// desktop transport bar's Lyrics quick action) can deep-link straight to
  /// a panel instead of always landing on Queue.
  final NowPlayingPanel? initialPanel;

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> with ArtTintMixin {
  /// Position under the finger while scrubbing, or null.
  Duration? _scrub;
  late NowPlayingPanel _panel;

  /// Accumulated downward drag on the header, used to swipe-dismiss the
  /// player the way a full-screen modal is expected to close on iOS/Android.
  double _dismissDragExtent = 0.0;

  /// Set when the player was opened on a specific panel; on the mobile
  /// layout that panel lives in a sheet, which is opened after first build.
  NowPlayingPanel? _pendingPanel;

  @override
  void initState() {
    super.initState();
    _panel = widget.initialPanel ?? NowPlayingPanel.queue;
    _pendingPanel = widget.initialPanel;
  }

  /// Closes the player. Falls back to Home when there's nothing to pop
  /// (e.g. the player was opened as the initial route via a deep link),
  /// so the chevron and swipe-down always do something.
  void _closePlayer() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackViewModel>(
      builder: (context, playbackViewModel, child) {
        final currentTrack = playbackViewModel.currentTrack;
        final position = playbackViewModel.position;
        final duration = playbackViewModel.duration;
        final progress = playbackViewModel.progress;

        if (currentTrack == null) {
          return const NothingPlayingView();
        }

        updateArtTint(currentTrack.coverArtUrl);
        final darkScheme = OmnisonicColors.darkColorScheme;

        // Now Playing always renders as a dark, art-driven surface regardless
        // of the app's light/dark setting — every descendant reading
        // Theme.of(context).colorScheme (this file, LyricsPanel, the queue
        // list) picks up dark-appropriate colors automatically.
        // The surface is always dark, so the status bar icons have to be
        // light whatever the app theme is.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Theme(
            data: Theme.of(context).copyWith(
              brightness: Brightness.dark,
              colorScheme: darkScheme,
              textTheme: OmnisonicTypography.textTheme.apply(
                bodyColor: darkScheme.onSurface,
                displayColor: darkScheme.onSurface,
              ),
            ),
            // A fresh context, positioned below the Theme above, so every
            // Theme.of(context) call made further down (including inside this
            // class's own helper methods, which aren't separate widgets and
            // would otherwise see the ambient app theme instead) resolves to
            // the dark scheme.
            child: Builder(
              builder: (context) {
                // Esc closes the player, like any modal on desktop.
                return CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape):
                        _closePlayer,
                  },
                  child: Focus(
                    autofocus: true,
                    child: AnimatedSlide(
                      offset: Offset(
                        0,
                        _dismissDragExtent /
                            MediaQuery.sizeOf(context).height.clamp(1, 1e9),
                      ),
                      duration: _dismissDragExtent == 0
                          ? AnimationUtils.adjustedDuration(
                              context,
                              AnimationManager.fastDuration,
                            )
                          : Duration.zero,
                      child: Scaffold(
                        backgroundColor: darkScheme.surface,
                        // The cover's tint fills the screen, with the Aurora mesh
                        // over it at 30 % so a dark or flat cover still has a
                        // glow behind it.
                        body: ArtTintBackground(
                          seed: artTint,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Without a cover tint the background already
                              // is the (drifting) mesh: do not double it.
                              if (artTint != null)
                                Positioned.fill(
                                  child: AuroraMesh(
                                    brand: OmnisonicBrand.dark,
                                    opacity: FullScreenPlayer.meshOpacity,
                                  ),
                                ),
                              SafeArea(
                                // Two columns from the shell's tablet breakpoint (768),
                                // not ResponsiveLayout's 480: between the two, the side
                                // panel was 85–200px wide and its tabs overflowed.
                                child: LayoutBuilder(
                                  builder: (context, constraints) =>
                                      constraints.maxWidth >=
                                          ResponsiveBreakpoints.tablet
                                      ? _buildDesktopLayout(
                                          context,
                                          currentTrack,
                                          playbackViewModel,
                                          position,
                                          duration,
                                          progress,
                                        )
                                      : _buildMobileLayout(
                                          context,
                                          currentTrack,
                                          playbackViewModel,
                                          position,
                                          duration,
                                          progress,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
  ) {
    return Column(
      children: [
        _buildHeader(context, title: 'Now Playing'),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(OmnisonicSpacing.lg),
              child: Column(
                children: [
                  // Sized against the height too: at a fixed 360 the cover
                  // pushed shuffle, repeat and the panel launcher below the
                  // fold on a 390x844 phone.
                  _buildArtwork(
                    context,
                    track,
                    maxSize: (constraints.maxHeight * 0.42).clamp(160.0, 360.0),
                  ),
                  const SizedBox(height: OmnisonicSpacing.lg),
                  _buildTrackInfo(context, track),
                  const SizedBox(height: OmnisonicSpacing.lg),
                  _buildSeekBar(
                    context,
                    playbackViewModel,
                    position,
                    duration,
                    progress,
                  ),
                  const SizedBox(height: OmnisonicSpacing.md),
                  _buildPrimaryControls(context, playbackViewModel),
                  const SizedBox(height: OmnisonicSpacing.md),
                  _buildSecondaryControls(context, playbackViewModel),
                  const SizedBox(height: OmnisonicSpacing.md),
                  _buildSourceInfoPanel(context, track, playbackViewModel),
                  const SizedBox(height: OmnisonicSpacing.lg),
                  // The queue, lyrics and visualizer open in a sheet: embedded
                  // here, the lyrics list scrolled inside this scroll view and
                  // the two fought over every vertical drag.
                  _buildPanelLauncher(context),
                ],
              ),
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
  ) {
    return Column(
      children: [
        _buildHeader(context, title: 'Now Playing'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(OmnisonicSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  // Scrolls instead of overflowing on short windows — this
                  // column stacks fixed-size content (360px artwork, seek
                  // bar, two control rows, the source-info panel) that
                  // doesn't always fit a short desktop window's height.
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildArtwork(context, track),
                        const SizedBox(height: OmnisonicSpacing.lg),
                        _buildTrackInfo(context, track),
                        const SizedBox(height: OmnisonicSpacing.lg),
                        _buildSeekBar(
                          context,
                          playbackViewModel,
                          position,
                          duration,
                          progress,
                        ),
                        const SizedBox(height: OmnisonicSpacing.lg),
                        _buildPrimaryControls(context, playbackViewModel),
                        const SizedBox(height: OmnisonicSpacing.md),
                        _buildSecondaryControls(context, playbackViewModel),
                        const SizedBox(height: OmnisonicSpacing.md),
                        _buildSourceInfoPanel(
                          context,
                          track,
                          playbackViewModel,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.xl),
                Expanded(
                  flex: 1,
                  child: _buildPanel(context, playbackViewModel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Wraps [child] in the swipe-down-to-dismiss gesture.
  ///
  /// Applied to the header and the artwork, and deliberately not to the
  /// content between them: the seek bar, lyrics panel and queue list all
  /// want the vertical drag for themselves.
  /// Wraps [child] — the header — in the swipe-down-to-dismiss gesture.
  ///
  /// Only the header: on the artwork, inside the page's scroll view, it
  /// blocked vertical scrolling, and a downward swipe after scrolling closed
  /// the player. The whole player now follows the finger, so the gesture is
  /// visible before it commits.
  Widget _dismissible({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        final delta = details.primaryDelta ?? 0;
        setState(
          () => _dismissDragExtent = (_dismissDragExtent + delta).clamp(
            0.0,
            double.infinity,
          ),
        );
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dismissDragExtent > 120 || velocity > 700) {
          Haptics.impact();
          _closePlayer();
        } else {
          setState(() => _dismissDragExtent = 0);
        }
      },
      onVerticalDragCancel: () => setState(() => _dismissDragExtent = 0),
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context, {required String title}) {
    final scheme = Theme.of(context).colorScheme;
    return _dismissible(
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OmnisonicSpacing.sm,
              OmnisonicSpacing.sm,
              OmnisonicSpacing.ms,
              OmnisonicSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _closePlayer,
                  tooltip: 'Close player',
                  icon: const Icon(OmnisonicIcons.keyboardArrowDown),
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                Text(
                  title.toUpperCase(),
                  style: OmnisonicTypography.eyebrow.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Consumer<PlaybackViewModel>(
                  builder: (context, viewModel, child) {
                    final track = viewModel.currentTrack;
                    final isStarred = track?.isStarred ?? false;

                    return IconButton(
                      onPressed:
                          track != null &&
                              !viewModel.isFavoritePending(track.id)
                          ? () => viewModel.toggleFavorite(track)
                          : null,
                      icon: Icon(
                        isStarred
                            ? OmnisonicIcons.favorite
                            : OmnisonicIcons.favoriteOutline,
                        color: isStarred
                            ? OmnisonicBrand.of(context).heat
                            : scheme.onSurfaceVariant,
                      ),
                      tooltip: isStarred
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(
    BuildContext context,
    Track track, {
    double maxSize = 360,
  }) {
    return _artworkSwipe(
      child: Center(
        child: Hero(
          tag: 'now-playing-artwork-${track.id}',
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
            child: AspectRatio(
              aspectRatio: 1,
              // The cover lights the screen around it.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OmnisonicRadius.artHero),
                  boxShadow: OmnisonicShadows.artGlow(
                    artTint ?? OmnisonicColors.primaryDark,
                  ),
                ),
                child: CoverArt(
                  url: track.coverArtUrl,
                  seed: track.albumId ?? track.id,
                  radius: OmnisonicRadius.artHero,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal flick over the artwork skips tracks.
  ///
  /// Swiping left moves forward, matching the direction the queue travels
  /// rather than the direction of the finger.
  Widget _artworkSwipe({required Widget child}) {
    return Consumer<PlaybackViewModel>(
      builder: (context, vm, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 300) return;
          if (velocity < 0 && vm.hasNext) {
            Haptics.selection();
            vm.skipToNext();
          } else if (velocity > 0 && vm.hasPrevious) {
            Haptics.selection();
            vm.skipToPrevious();
          }
        },
        child: child,
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, Track track) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          track.title,
          // sectionTitle (28) with room, sectionTitleSmall (22) on a phone.
          style:
              (MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.tablet
                      ? OmnisonicTypography.sectionTitle
                      : OmnisonicTypography.sectionTitleSmall)
                  .copyWith(color: scheme.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        Text(
          track.artist,
          style: OmnisonicTypography.bodyLarge.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (track.album.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.xxs),
          Text(
            track.album,
            style: OmnisonicTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSeekBar(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
    Duration position,
    Duration duration,
    double progress,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (playbackViewModel.isRestoring && position == Duration.zero) {
      return const SizedBox(height: 56);
    }
    final elapsed = _scrub ?? position;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatDuration(elapsed),
              style: OmnisonicTypography.duration.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              formatDuration(duration),
              style: OmnisonicTypography.duration.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        AuroraProgress(
          position: position,
          duration: duration,
          onChanged: (value) => setState(() => _scrub = value),
          onSeek: playbackViewModel.seek,
        ),
        const SizedBox(height: OmnisonicSpacing.xs),
        _buildQualityIndicator(context, playbackViewModel),
      ],
    );
  }

  /// What is streaming, without numbers: the tiers' bitrates are nominal,
  /// not what the file or the stream actually has, so showing them
  /// presented invented figures as fact.
  Widget _buildQualityIndicator(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final quality = playbackViewModel.currentQuality;
    final maxQuality = playbackViewModel.maxQuality;
    final reduced = quality.qualityScore < maxQuality.qualityScore;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: OmnisonicSpacing.sm,
        runSpacing: OmnisonicSpacing.xs,
        children: [
          if (reduced)
            Text(
              'reduced from ${maxQuality.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmnisonicTypography.technicalSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          QualityBadge(quality: quality),
        ],
      ),
    );
  }

  Widget _buildPrimaryControls(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassCircle(SkipPreviousButton(playback: playbackViewModel, size: 28)),
        const SizedBox(width: OmnisonicSpacing.lg),
        PlayPauseButton(playback: playbackViewModel, prominent: true),
        const SizedBox(width: OmnisonicSpacing.lg),
        _glassCircle(SkipNextButton(playback: playbackViewModel, size: 28)),
      ],
    );
  }

  /// Circular glass backing for the prev/next buttons either side of the
  /// solid play/pause button.
  Widget _glassCircle(Widget button, {double size = 56}) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(size / 2),
      padding: EdgeInsets.zero,
      child: SizedBox.square(
        dimension: size,
        child: Center(child: button),
      ),
    );
  }

  Widget _buildSecondaryControls(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    // The favourite toggle lives in the header only; it used to be here as
    // well, so the same action showed twice on one screen.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShuffleModeButton(
          playback: playbackViewModel,
          size: OmnisonicIconSizes.md,
        ),
        const SizedBox(width: OmnisonicSpacing.xl),
        RepeatModeButton(
          playback: playbackViewModel,
          size: OmnisonicIconSizes.md,
        ),
      ],
    );
  }

  /// Bottom glass panel showing where the current track is streaming from:
  /// source server, quality, whether the server is transcoding it, and
  /// whether it's been scrobbled yet.
  Widget _buildSourceInfoPanel(
    BuildContext context,
    Track track,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final serverName = context.watch<ServerManagementViewModel>().serverNameFor(
      track.serverId,
    );

    final quality = playbackViewModel.currentQuality;
    final maxQuality = playbackViewModel.maxQuality;
    final isDirect = quality.qualityScore >= maxQuality.qualityScore;
    final scrobbled = playbackViewModel.hasScrobbledCurrentTrack;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.md,
        vertical: OmnisonicSpacing.sm,
      ),
      child: Row(
        children: [
          ServerDot(serverId: track.serverId, size: 8),
          const SizedBox(width: OmnisonicSpacing.sm),
          Expanded(
            child: Text(
              '$serverName · ${quality.displayName} · '
              '${isDirect ? 'Direct' : 'Transcoded'}',
              style: OmnisonicTypography.technicalSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.sm),
          Icon(
            scrobbled ? OmnisonicIcons.checkCircle : OmnisonicIcons.history,
            size: OmnisonicIconSizes.inline,
            color: scrobbled
                ? OmnisonicColors.success
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: OmnisonicSpacing.xs),
          Text(
            scrobbled ? 'Scrobbled' : 'Not scrobbled yet',
            style: OmnisonicTypography.technicalSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile entry points to the panels that the desktop layout shows inline.
  ///
  /// A [Builder], because [ResponsiveLayout] is handed every layout eagerly:
  /// only a builder that actually mounts knows the mobile layout is the one
  /// on screen, and so may open the requested panel's sheet.
  Widget _buildPanelLauncher(BuildContext context) {
    return Builder(
      builder: (context) {
        final pending = _pendingPanel;
        if (pending != null) {
          _pendingPanel = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) _openPanelSheet(context, pending);
          });
        }
        return _buildPanelLauncherRow(context);
      },
    );
  }

  Widget _buildPanelLauncherRow(BuildContext context) {
    return Row(
      children: [
        for (final panel in NowPlayingPanel.values) ...[
          if (panel != NowPlayingPanel.values.first)
            const SizedBox(width: OmnisonicSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openPanelSheet(context, panel),
              icon: Icon(panel.icon, size: OmnisonicIconSizes.smd),
              label: Text(panel.label, maxLines: 1),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openPanelSheet(BuildContext context, NowPlayingPanel panel) {
    _panel = panel;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(OmnisonicSpacing.sm),
            child: _buildPanel(
              sheetContext,
              // Watched here: the sheet is its own route, so the player's
              // rebuilds do not reach it.
              sheetContext.watch<PlaybackViewModel>(),
              compact: true,
              onPanelChanged: (value) => setSheetState(() => _panel = value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    PlaybackViewModel playbackViewModel, {
    bool compact = false,
    ValueChanged<NowPlayingPanel>? onPanelChanged,
  }) {
    return GlassSurface(
      padding: EdgeInsets.all(
        compact ? OmnisonicSpacing.md : OmnisonicSpacing.lg,
      ),
      borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Icons alone where the labels would not fit.
              final iconsOnly = constraints.maxWidth < 220;
              return SegmentedButton<NowPlayingPanel>(
                showSelectedIcon: false,
                segments: [
                  for (final panel in NowPlayingPanel.values)
                    ButtonSegment(
                      value: panel,
                      icon: Icon(panel.icon),
                      tooltip: iconsOnly ? panel.label : null,
                      label: iconsOnly ? null : Text(panel.label),
                    ),
                ],
                selected: {_panel},
                onSelectionChanged: (value) {
                  if (onPanelChanged != null) {
                    onPanelChanged(value.first);
                  } else {
                    setState(() => _panel = value.first);
                  }
                },
              );
            },
          ),
          const SizedBox(height: OmnisonicSpacing.md),
          Expanded(
            child: AnimatedSwitcher(
              duration: AnimationUtils.adjustedDuration(
                context,
                AnimationManager.fastDuration,
              ),
              child: _buildPanelContent(
                context,
                playbackViewModel,
                key: _panel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(
    BuildContext context,
    PlaybackViewModel playbackViewModel, {
    required NowPlayingPanel key,
  }) {
    switch (key) {
      case NowPlayingPanel.queue:
        return _buildQueuePanel(context, playbackViewModel);
      case NowPlayingPanel.lyrics:
        return _buildLyricsPanel(context, playbackViewModel);
    }
  }

  Widget _buildQueuePanel(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final queue = playbackViewModel.queue;
    final currentIndex = playbackViewModel.currentIndex;
    final scheme = Theme.of(context).colorScheme;

    if (queue.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    // The current track and everything that plays after it — not the head
    // of the queue, which is mostly tracks that have already played. The
    // whole rest of the queue, not a preview: there is no "Open full queue"
    // link to reach the remainder any more.
    final start = currentIndex.clamp(0, queue.length - 1);

    // The app's TrackRow, as in every other list. Inside the panel the
    // rows sit on the panel's own padding, with the ink reaching into it.
    return PageGutter(
      value: OmnisonicSpacing.sm,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: queue.length - start,
        itemBuilder: (context, i) {
          final index = start + i;
          final track = queue[index];
          return TrackRow(
            // The same track can sit in the queue twice, so the position
            // is part of the key, as on the queue page.
            key: ValueKey('queue-${track.id}-$index'),
            track: track,
            isCurrent: index == currentIndex,
            showDuration: false,
            onTap: () => playbackViewModel.playTrack(
              track,
              queue: queue,
              startIndex: index,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLyricsPanel(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    return LyricsPanel(
      track: playbackViewModel.currentTrack,
      position: playbackViewModel.position,
    );
  }
}

/// The panels beside (or, on phones, below) the player.
///
/// There used to be a third, "Visualizer": a random animation with no
/// connection to the audio, presented as a feature. It is gone.
enum NowPlayingPanel {
  queue('Queue', OmnisonicIcons.queueMusic),
  lyrics('Lyrics', OmnisonicIcons.lyrics);

  const NowPlayingPanel(this.label, this.icon);

  final String label;
  final IconData icon;
}
