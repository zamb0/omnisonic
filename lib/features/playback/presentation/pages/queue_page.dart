import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/presentation/widgets/widgets.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart' as playback;
import '../viewmodels/playback_view_model.dart';
import '../../../../core/utils/haptics.dart';

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
          body: vm.isLoading
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildNowPlayingCard(context, vm, track),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Up Next (${upNext.length})',
              style: OmnisonicTypography.titleSmall.copyWith(
                fontWeight: OmnisonicTypography.semiBold,
              ),
            ),
          ),
        ),
        Expanded(
          child: upNext.isEmpty
              ? const EmptyState(
                  icon: OmnisonicIcons.queueMusicOutline,
                  title: 'Nothing queued next',
                  subtitle: 'Add tracks from an album or playlist.',
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                    return _QueueRow(
                      key: ValueKey('queue-${upcomingTrack.id}-$absoluteIndex'),
                      track: upcomingTrack,
                      position: i + 1,
                      onTap: () => vm.playTrack(
                        upcomingTrack,
                        queue: queue,
                        startIndex: absoluteIndex,
                      ),
                      onRemove: () => vm.removeFromQueue(absoluteIndex),
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
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      padding: const EdgeInsets.all(OmnisonicSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(OmnisonicRadius.md),
            child: SizedBox(
              width: 52,
              height: 52,
              child: CoverArt(url: track.coverArtUrl, radius: 0),
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now Playing',
                  style: OmnisonicTypography.overline.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
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
          IconButton(
            onPressed: vm.hasPrevious ? () => vm.skipToPrevious() : null,
            icon: const Icon(OmnisonicIcons.skipPrevious),
          ),
          IconButton(
            onPressed: () => vm.togglePlayPause(),
            icon: Icon(
              vm.isPlaying ? OmnisonicIcons.pause : OmnisonicIcons.playArrow,
            ),
          ),
          IconButton(
            onPressed: vm.hasNext ? () => vm.skipToNext() : null,
            icon: const Icon(OmnisonicIcons.skipNext),
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Icon(
            OmnisonicIcons.infoOutline,
            size: OmnisonicIconSizes.inline,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hint,
              style: OmnisonicTypography.metadata.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    super.key,
    required this.track,
    required this.position,
    required this.onTap,
    required this.onRemove,
  });

  final Track track;
  final int position;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$position',
                  textAlign: TextAlign.center,
                  style: OmnisonicTypography.metadata.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CoverArt(url: track.coverArtUrl, radius: 0),
                ),
              ),
            ],
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OmnisonicTypography.bodyMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
          subtitle: Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OmnisonicTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(OmnisonicIcons.close, size: 18),
                tooltip: 'Remove from queue',
                onPressed: onRemove,
              ),
              Icon(OmnisonicIcons.dragHandle, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
