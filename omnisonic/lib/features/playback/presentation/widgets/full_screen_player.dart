import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/responsive_layout.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../viewmodels/playback_view_model.dart';
import 'audio_visualizer.dart';

/// Full-screen player with a clean Feishin-inspired layout
class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  bool _isDraggingSeek = false;
  double _seekValue = 0.0;
  _NowPlayingPanel _panel = _NowPlayingPanel.queue;

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
          return const Scaffold(
            body: Center(
              child: Text('No track playing'),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
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
                _buildArtwork(track),
                const SizedBox(height: OmnisonicSpacing.lg),
                _buildTrackInfo(context, track),
                const SizedBox(height: OmnisonicSpacing.lg),
                _buildSeekBar(playbackViewModel, position, duration, progress),
                const SizedBox(height: OmnisonicSpacing.md),
                _buildPrimaryControls(context, playbackViewModel),
                const SizedBox(height: OmnisonicSpacing.md),
                _buildSecondaryControls(context, playbackViewModel),
                const SizedBox(height: OmnisonicSpacing.lg),
                _buildPanel(context, playbackViewModel, compact: true),
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
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildArtwork(track),
                      const SizedBox(height: OmnisonicSpacing.lg),
                      _buildTrackInfo(context, track),
                      const SizedBox(height: OmnisonicSpacing.lg),
                      _buildSecondaryControls(context, playbackViewModel),
                    ],
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.lg),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSeekBar(playbackViewModel, position, duration, progress),
                      const SizedBox(height: OmnisonicSpacing.lg),
                      _buildPrimaryControls(context, playbackViewModel),
                    ],
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.lg),
                SizedBox(
                  width: 320,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
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
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.favorite_border, color: scheme.onSurfaceVariant),
          ),
          IconButton(
            onPressed: () => setState(() => _panel = _NowPlayingPanel.queue),
            icon: Icon(Icons.queue_music, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(Track track) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceVariant,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
                    imageUrl: track.coverArtUrl!,
                    cacheKey: track.coverArtUrl!.subsonicCacheKey,
                    fit: BoxFit.cover,
                    maxWidthDiskCache: 800,
                    maxHeightDiskCache: 800,
                    memCacheWidth: 800,
                    memCacheHeight: 800,
                    placeholder: (context, url) => _buildFallbackArtwork(),
                    errorWidget: (context, url, error) => _buildFallbackArtwork(),
                  )
                : _buildFallbackArtwork(),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackArtwork() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceVariant,
      child: Icon(
        Icons.music_note,
        color: scheme.onSurfaceVariant.withOpacity(0.5),
        size: 72,
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, Track track) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          track.artist,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (track.album.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            track.album,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSeekBar(
    PlaybackViewModel playbackViewModel,
    Duration position,
    Duration duration,
    double progress,
  ) {
    final scheme = Theme.of(context).colorScheme;
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.surfaceVariant,
            thumbColor: scheme.primary,
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
      ],
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
        IconButton(
          onPressed: playbackViewModel.hasPrevious
              ? () => playbackViewModel.skipToPrevious()
              : null,
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => playbackViewModel.togglePlayPause(),
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: scheme.primary,
          ),
          child: Icon(
            playbackViewModel.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 36,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed:
              playbackViewModel.hasNext ? () => playbackViewModel.skipToNext() : null,
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
        ),
      ],
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

  Widget _buildSecondaryControls(
    BuildContext context,
    PlaybackViewModel playbackViewModel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
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
        IconButton(
          onPressed: () => playbackViewModel.toggleRepeatMode(),
          icon: Icon(
            _getRepeatIcon(playbackViewModel.repeatMode),
            color: playbackViewModel.repeatMode != RepeatMode.none
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          tooltip: 'Repeat',
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.favorite_border, color: scheme.onSurfaceVariant),
          tooltip: 'Favorite',
        ),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => _panel = _NowPlayingPanel.queue),
          icon: Icon(Icons.queue_music, color: scheme.onSurfaceVariant),
          tooltip: 'Queue',
        ),
      ],
    );
  }

  Widget _buildPanel(
    BuildContext context,
    PlaybackViewModel playbackViewModel, {
    bool compact = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? OmnisonicSpacing.md : OmnisonicSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<_NowPlayingPanel>(
            segments: const [
              ButtonSegment(
                value: _NowPlayingPanel.queue,
                label: Text('Queue'),
              ),
              ButtonSegment(
                value: _NowPlayingPanel.lyrics,
                label: Text('Lyrics'),
              ),
              ButtonSegment(
                value: _NowPlayingPanel.visualizer,
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
              child: _buildPanelContent(context, playbackViewModel, key: _panel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(
    BuildContext context,
    PlaybackViewModel playbackViewModel, {
    required _NowPlayingPanel key,
  }) {
    switch (key) {
      case _NowPlayingPanel.queue:
        return _buildQueuePanel(context, playbackViewModel);
      case _NowPlayingPanel.lyrics:
        return _buildLyricsPanel(context);
      case _NowPlayingPanel.visualizer:
        return _buildVisualizerPanel(context, playbackViewModel);
    }
  }

  Widget _buildQueuePanel(BuildContext context, PlaybackViewModel playbackViewModel) {
    final queue = playbackViewModel.queue;
    final currentIndex = playbackViewModel.currentIndex;
    final scheme = Theme.of(context).colorScheme;

    if (queue.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.separated(
      itemCount: queue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final track = queue[index];
        final isCurrent = index == currentIndex;

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: scheme.surface,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!,
                      cacheKey: track.coverArtUrl!.subsonicCacheKey,
                      fit: BoxFit.cover,
                      memCacheWidth: 80,
                      memCacheHeight: 80,
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
                  playbackViewModel.isPlaying ? Icons.pause : Icons.play_arrow,
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
    );
  }

  Widget _buildLyricsPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'Lyrics will appear here',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
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

enum _NowPlayingPanel {
  queue,
  lyrics,
  visualizer,
}