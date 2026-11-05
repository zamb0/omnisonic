import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/presentation/widgets/widgets.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart' as playback;
import '../viewmodels/playback_view_model.dart';
import '../../../../core/utils/haptics.dart';
import '../widgets/transport_controls.dart';

/// Dedicated queue screen: a summary of what's playing now, and a
/// reorderable "up next" list for everything queued after it.
class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackViewModel>(
      builder: (context, vm, child) {
        final track = vm.currentTrack;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Queue'),
            actions: [
              if (vm.hasQueue)
                IconButton(
                  icon: const Icon(OmnisonicIcons.playlistRemove),
                  tooltip: 'Clear queue',
                  onPressed: () => _confirmClear(context, vm),
                ),
            ],
          ),
          // The skeleton only before the queue first loads: isLoading is
          // also set by every playTrack, and the whole queue used to flash
          // to placeholders, losing its scroll and any drag in progress.
          body: vm.isLoading && !vm.hasQueue
              ? const LoadingStateView(kind: SkeletonKind.list, itemCount: 6)
              : track == null
              ? const EmptyState(
                  icon: OmnisonicIcons.queueMusicOutline,
                  title: 'Nothing playing',
                  subtitle: 'Start a track and the queue will fill up here.',
                )
              : _buildBody(context, vm, track),
        );
      },
    );
  }

  /// Clearing the queue throws away an ordering the user may have built by
  /// hand, and there is no undo for it, so it asks first.
  Future<void> _confirmClear(BuildContext context, PlaybackViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear the queue?'),
        content: const Text(
          'The current track keeps playing. Everything queued after it is '
          'removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      Haptics.success();
      await vm.clearQueue();
    }
  }

  Widget _buildBody(BuildContext context, PlaybackViewModel vm, Track track) {
    final queue = vm.queue;
    final currentIndex = vm.currentIndex.clamp(0, queue.length - 1);
    final upNext = queue.sublist((currentIndex + 1).clamp(0, queue.length));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            PageGutter.of(context),
            OmnisonicSpacing.sm,
            PageGutter.of(context),
            0,
          ),
          child: _buildNowPlayingCard(context, vm, track),
        ),
        SectionHeader(title: 'Up next', meta: '${upNext.length}'),
        Expanded(
          child: upNext.isEmpty
              ? const EmptyState(
                  icon: OmnisonicIcons.queueMusicOutline,
                  title: 'Nothing queued next',
                  subtitle: 'Add tracks from an album or playlist.',
                )
              : ReorderableListView.builder(
                  // Only the row's own handle starts a drag: the default
                  // handles doubled it on desktop, and on touch a whole-row
                  // long-press drag fought with scrolling.
                  buildDefaultDragHandles: false,
                  // TrackRow lays itself out on the gutter.
                  padding: const EdgeInsets.only(bottom: OmnisonicSpacing.sm),
                  itemCount: upNext.length,
                  // onReorderItem (unlike the deprecated onReorder) already
                  // adjusts newIndex for the removed item, matching
                  // reorderQueueItem's post-removal-index contract exactly.
                  onReorderItem: (oldIndex, newIndex) {
                    Haptics.selection();
                    final absOld = currentIndex + 1 + oldIndex;
                    final absNew = currentIndex + 1 + newIndex;
                    vm.reorderQueueItem(absOld, absNew);
                  },
                  itemBuilder: (context, i) {
                    final upcomingTrack = upNext[i];
                    final absoluteIndex = currentIndex + 1 + i;
                    void play() => vm.playTrack(
                      upcomingTrack,
                      queue: queue,
                      startIndex: absoluteIndex,
                    );
                    return TrackRow(
                      key: ValueKey('queue-${upcomingTrack.id}-$absoluteIndex'),
                      track: upcomingTrack,
                      leading: TrackRowLeading.positionAndArt,
                      position: i + 1,
                      isCurrent: false,
                      onTap: play,
                      onShowActions: () => showTrackActions(
                        context,
                        upcomingTrack,
                        onPlay: play,
                      ),
                      trailing: IconButton(
                        icon: const Icon(OmnisonicIcons.close),
                        iconSize: OmnisonicIconSizes.sm,
                        tooltip: 'Remove from queue',
                        onPressed: () => vm.removeFromQueue(absoluteIndex),
                      ),
                      reorderIndex: i,
                    );
                  },
                ),
        ),
        _buildAutoplayFooter(context, vm),
      ],
    );
  }

  Widget _buildNowPlayingCard(
    BuildContext context,
    PlaybackViewModel vm,
    Track track,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.overlay),
      padding: const EdgeInsets.all(OmnisonicSpacing.ms),
      child: Row(
        children: [
          CoverArt(
            url: track.coverArtUrl,
            seed: track.albumId ?? track.id,
            size: 56,
            elevated: true,
          ),
          const SizedBox(width: OmnisonicSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW PLAYING',
                  style: OmnisonicTypography.eyebrow.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: OmnisonicSpacing.xxs),
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
              ],
            ),
          ),
          SkipPreviousButton(playback: vm),
          PlayPauseButton(playback: vm),
          SkipNextButton(playback: vm),
        ],
      ),
    );
  }

  /// Real hint about what happens when the queue runs out, derived from the
  /// actual repeat/shuffle state — there's no separate "autoplay" feature to
  /// report on.
  Widget _buildAutoplayFooter(BuildContext context, PlaybackViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    final String hint;
    switch (vm.repeatMode) {
      case playback.RepeatMode.one:
        hint = 'Repeating the current track';
        break;
      case playback.RepeatMode.all:
        hint = 'Repeating the queue when it ends';
        break;
      case playback.RepeatMode.none:
        hint = vm.shuffleEnabled
            ? 'Shuffled — playback stops when the queue ends'
            : 'Playback stops when the queue ends';
        break;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        OmnisonicSpacing.sm,
        PageGutter.of(context),
        OmnisonicSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            OmnisonicIcons.infoOutline,
            size: OmnisonicIconSizes.inline,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: OmnisonicSpacing.sm),
          Expanded(
            child: Text(
              hint,
              style: OmnisonicTypography.technicalSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
