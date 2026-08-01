import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart' as playback;
import '../../../../core/services/cover_palette_service.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../ui/presentation/widgets/server_dot.dart';
import '../viewmodels/playback_view_model.dart';
import 'audio_visualizer.dart';
import '../../../lyrics/presentation/widgets/lyrics_panel.dart';

/// Full-screen player with a clean Feishin-inspired layout
class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key, this.initialPanel});

  /// Which of Queue/Lyrics/Visualizer to open on, so callers (e.g. the
  /// desktop transport bar's Lyrics quick action) can deep-link straight to
  /// a panel instead of always landing on Queue.
  final NowPlayingPanel? initialPanel;

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  bool _isDraggingSeek = false;
  double _seekValue = 0.0;
  late NowPlayingPanel _panel;

  /// Accumulated downward drag on the header, used to swipe-dismiss the
  /// player the way a full-screen modal is expected to close on iOS/Android.
  double _dismissDragExtent = 0.0;

  /// Dominant color extracted from the current track's cover art, used to
  /// tint the background. Null until extraction finishes (or if it fails),
  /// in which case [OmnisonicColors.nowPlayingGradient] is used instead.
  Color? _tintColor;
  String? _tintedCoverUrl;

  @override
  void initState() {
    super.initState();
    _panel = widget.initialPanel ?? NowPlayingPanel.queue;
  }

  void _updateTint(String? coverArtUrl) {
    if (coverArtUrl == _tintedCoverUrl) return;
    _tintedCoverUrl = coverArtUrl;
    CoverPaletteService.instance.extractColor(coverArtUrl).then((color) {
      if (mounted && _tintedCoverUrl == coverArtUrl) {
        setState(() => _tintColor = color);
      }
    });
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
        final position = playbackViewModel.position;
        final duration = playbackViewModel.duration;
        final progress = playbackViewModel.progress;

        if (currentTrack == null) {
          return const Scaffold(body: Center(child: Text('No track playing')));
        }

        _updateTint(currentTrack.coverArtUrl);
        final tint =
            _tintColor ?? OmnisonicColors.nowPlayingGradient.colors.first;
        final darkScheme = OmnisonicColors.darkColorScheme;

        // Now Playing always renders as a dark, art-driven surface regardless
        // of the app's light/dark setting — every descendant reading
        // Theme.of(context).colorScheme (this file, LyricsPanel, the queue
        // list) picks up dark-appropriate colors automatically.
        return Theme(
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
              return Scaffold(
                backgroundColor: darkScheme.surface,
                body: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.4),
                      radius: 1.3,
                      colors: [
                        tint.withValues(alpha: 0.55),
                        darkScheme.surface,
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
                      ),
                      tablet: _buildDesktopLayout(
                        context,
                        currentTrack,
                        playbackViewModel,
                        position,
                        duration,
                        progress,
                      ),
                      desktop: _buildDesktopLayout(
                        context,
                        currentTrack,
                        playbackViewModel,
                        position,
                        duration,
                        progress,
                      ),
                    ),
                  ),
                ),
              );
            },
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OmnisonicSpacing.lg),
            child: Column(
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
                const SizedBox(height: OmnisonicSpacing.md),
                _buildPrimaryControls(context, playbackViewModel),
                const SizedBox(height: OmnisonicSpacing.md),
                _buildSecondaryControls(context, playbackViewModel),
                const SizedBox(height: OmnisonicSpacing.md),
                _buildSourceInfoPanel(context, track, playbackViewModel),
                const SizedBox(height: OmnisonicSpacing.lg),
                SizedBox(
                  height: 400,
                  child: _buildPanel(context, playbackViewModel, compact: true),
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

  Widget _buildHeader(BuildContext context, {required String title}) {
    final scheme = Theme.of(context).colorScheme;
    // The drag handle + header row (not the scrollable content below) is
    // the swipe-down target, so it doesn't fight the seek bar, lyrics panel
    // or queue list for the vertical-drag gesture.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        final delta = details.primaryDelta;
        if (delta != null && delta > 0) {
          _dismissDragExtent += delta;
        }
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dismissDragExtent > 80 || velocity > 600) {
          _closePlayer();
        }
        _dismissDragExtent = 0;
      },
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
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _closePlayer,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Consumer<PlaybackViewModel>(
                  builder: (context, viewModel, child) {
                    final track = viewModel.currentTrack;
                    final isStarred = track?.isStarred ?? false;

                    return IconButton(
                      onPressed: track != null
                          ? () {
                              viewModel.toggleFavorite(track);
                            }
                          : null,
                      icon: Icon(
                        isStarred ? Icons.favorite : Icons.favorite_border,
                        color: isStarred
                            ? OmnisonicColors.favoriteIndicator
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

  Widget _buildArtwork(BuildContext context, Track track) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Hero(
        tag: 'now-playing-artwork-${track.id}',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!.withCoverArtSize(800),
                      cacheKey: track.coverArtUrl!
                          .withCoverArtSize(800)
                          .subsonicCacheKey,
                      cacheManager: OmnisonicImageCacheManager.instance,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      memCacheHeight: 800,
                      fadeInDuration: const Duration(milliseconds: 120),
                      useOldImageOnUrlChange: true,
                      placeholder: (context, url) =>
                          _buildFallbackArtwork(context),
                      errorWidget: (context, url, error) =>
                          _buildFallbackArtwork(context),
                    )
                  : _buildFallbackArtwork(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackArtwork(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 72,
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          track.artist,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (track.album.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            track.album,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
    final activeValue = _isDraggingSeek ? _seekValue : progress.clamp(0.0, 1.0);
    final elapsed = _isDraggingSeek
        ? Duration(milliseconds: (_seekValue * duration.inMilliseconds).round())
        : position;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(elapsed),
              style: OmnisonicTypography.duration.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: OmnisonicTypography.duration.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scheme.primary,
            inactiveTrackColor: OmnisonicColors.glassDark(1),
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: activeValue,
            onChanged: (value) {
              setState(() {
                _isDraggingSeek = true;
                _seekValue = value;
              });
            },
            onChangeEnd: (value) {
              playbackViewModel.seekToProgress(value);
              setState(() {
                _isDraggingSeek = false;
              });
            },
          ),
        ),
        const SizedBox(height: 4),
        _buildQualityIndicator(context, playbackViewModel),
      ],
    );
  }

  Widget _buildQualityIndicator(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final quality = playbackViewModel.currentQuality;
    final maxQuality = playbackViewModel.maxQuality;
    final ratio = (playbackViewModel.streamingQualityRatio * 100)
        .clamp(0, 100)
        .round();

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '${quality.format} ${quality.bitrate} kbps • $ratio% of max ${maxQuality.bitrate}',
        style: OmnisonicTypography.metadata.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPrimaryControls(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassCircleButton(
          context,
          icon: Icons.skip_previous,
          onPressed: playbackViewModel.hasPrevious
              ? () => playbackViewModel.skipToPrevious()
              : null,
        ),
        const SizedBox(width: 16),
        FilledButton(
          onPressed: () => playbackViewModel.togglePlayPause(),
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            backgroundColor: scheme.primary,
          ),
          child: Icon(
            playbackViewModel.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 36,
          ),
        ),
        const SizedBox(width: 16),
        _glassCircleButton(
          context,
          icon: Icons.skip_next,
          onPressed: playbackViewModel.hasNext
              ? () => playbackViewModel.skipToNext()
              : null,
        ),
      ],
    );
  }

  /// Circular glass transport button, used for prev/next around the solid
  /// primary-colored play/pause button.
  Widget _glassCircleButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 56,
    double iconSize = 28,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      borderRadius: BorderRadius.circular(size / 2),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: iconSize),
          color: onPressed != null
              ? scheme.onSurface
              : scheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  IconData _getRepeatIcon(playback.RepeatMode repeatMode) {
    switch (repeatMode) {
      case playback.RepeatMode.none:
        return Icons.repeat;
      case playback.RepeatMode.all:
        return Icons.repeat;
      case playback.RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  Widget _buildSecondaryControls(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => playbackViewModel.toggleShuffleMode(),
          icon: Icon(
            Icons.shuffle,
            color: playbackViewModel.shuffleEnabled
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => playbackViewModel.toggleRepeatMode(),
          icon: Icon(
            _getRepeatIcon(playbackViewModel.repeatMode),
            color: playbackViewModel.repeatMode != playback.RepeatMode.none
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          tooltip: 'Repeat',
        ),
        const SizedBox(width: 8),
        Consumer<PlaybackViewModel>(
          builder: (context, viewModel, child) {
            final track = viewModel.currentTrack;
            final isStarred = track?.isStarred ?? false;

            return IconButton(
              onPressed: track != null
                  ? () {
                      viewModel.toggleFavorite(track);
                    }
                  : null,
              icon: Icon(
                isStarred ? Icons.favorite : Icons.favorite_border,
                color: isStarred
                    ? OmnisonicColors.favoriteIndicator
                    : scheme.onSurfaceVariant,
              ),
              tooltip: isStarred ? 'Remove from favorites' : 'Add to favorites',
            );
          },
        ),
      ],
    );
  }

  /// Sleep timer / output device / EQ row. None of these have a backing
  /// feature yet, so they're rendered disabled rather than wired up to fake
  /// behavior — visual placeholders for the mockup's control cluster.
  Widget _buildUnimplementedControls(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mutedColor = scheme.onSurfaceVariant.withValues(alpha: 0.4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: null,
          icon: Icon(Icons.bedtime_outlined, color: mutedColor),
          tooltip: 'Sleep timer — not available yet',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: null,
          icon: Icon(Icons.speaker_outlined, color: mutedColor),
          tooltip: 'Output device — not available yet',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: null,
          icon: Icon(Icons.equalizer, color: mutedColor),
          tooltip: 'Equalizer — not available yet',
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
    final serverViewModel = context.watch<ServerManagementViewModel>();
    final matches = serverViewModel.servers.where(
      (s) => s.id == track.serverId,
    );
    final serverName = matches.isEmpty ? track.serverId : matches.first.name;

    final quality = playbackViewModel.currentQuality;
    final maxQuality = playbackViewModel.maxQuality;
    final isDirect = quality.qualityScore >= maxQuality.qualityScore;
    final scrobbled = playbackViewModel.hasScrobbledCurrentTrack;

    return Column(
      children: [
        GlassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.md,
            vertical: OmnisonicSpacing.sm,
          ),
          child: Row(
            children: [
              ServerDot(serverId: track.serverId, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$serverName · ${quality.format} ${quality.bitrate}kbps · '
                  '${isDirect ? 'Direct' : 'Transcoded'}',
                  style: OmnisonicTypography.metadata.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                scrobbled ? Icons.check_circle : Icons.history,
                size: 14,
                color: scrobbled
                    ? OmnisonicColors.successAccessible
                    : scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                scrobbled ? 'Scrobbled' : 'Not scrobbled yet',
                style: OmnisonicTypography.metadata.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        _buildUnimplementedControls(context),
      ],
    );
  }

  Widget _buildPanel(
    BuildContext context,
    PlaybackViewModel playbackViewModel, {
    bool compact = false,
  }) {
    return GlassSurface(
      padding: EdgeInsets.all(
        compact ? OmnisonicSpacing.md : OmnisonicSpacing.lg,
      ),
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<NowPlayingPanel>(
            segments: const [
              ButtonSegment(value: NowPlayingPanel.queue, label: Text('Queue')),
              ButtonSegment(
                value: NowPlayingPanel.lyrics,
                label: Text('Lyrics'),
              ),
              ButtonSegment(
                value: NowPlayingPanel.visualizer,
                label: Text('Visualizer'),
              ),
            ],
            selected: {_panel},
            onSelectionChanged: (value) {
              setState(() => _panel = value.first);
            },
          ),
          const SizedBox(height: OmnisonicSpacing.md),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
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
      case NowPlayingPanel.visualizer:
        return _buildVisualizerPanel(context, playbackViewModel);
    }
  }

  /// Preview length for the inline queue list; the full, reorderable queue
  /// lives on its own screen (see [QueuePage]).
  static const int _queuePreviewCount = 6;

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

    final previewCount = queue.length.clamp(0, _queuePreviewCount);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: previewCount,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final track = queue[index];
              final isCurrent = index == currentIndex;

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: OmnisonicColors.glassDark(1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.coverArtUrl!.withCoverArtSize(128),
                            cacheKey: track.coverArtUrl!
                                .withCoverArtSize(128)
                                .subsonicCacheKey,
                            cacheManager: OmnisonicImageCacheManager.instance,
                            fit: BoxFit.cover,
                            memCacheWidth: 80,
                            memCacheHeight: 80,
                            fadeInDuration: const Duration(milliseconds: 120),
                            useOldImageOnUrlChange: true,
                          )
                        : Icon(
                            Icons.music_note,
                            color: scheme.onSurfaceVariant,
                            size: 18,
                          ),
                  ),
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: isCurrent
                    ? Icon(
                        playbackViewModel.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: scheme.primary,
                      )
                    : null,
                onTap: () => playbackViewModel.playTrack(
                  track,
                  queue: queue,
                  startIndex: index,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(OmnisonicRadius.md),
          onTap: () => GoRouter.of(context).push(AppRouter.queue),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Open full queue (${queue.length})',
                  style: OmnisonicTypography.labelMedium.copyWith(
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: scheme.primary),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildVisualizerPanel(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: AudioVisualizer(
        isPlaying: playbackViewModel.isPlaying,
        type: AudioVisualizerType.equalizer,
        height: 120,
        color: scheme.primary,
      ),
    );
  }
}

enum NowPlayingPanel { queue, lyrics, visualizer }
