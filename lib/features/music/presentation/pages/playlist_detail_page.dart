import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../ui/presentation/widgets/widgets.dart';
import '../viewmodels/playlist_view_model.dart';
import '../widgets/playlist_actions.dart';
import '../widgets/playlist_form_dialog.dart';

/// A playlist: header, play/shuffle, and its tracks, with reordering.
///
/// Built like the album page — art-led [DetailHeader] on the shell's tint,
/// [TrackRow]s — rather than the old primary-colour gradient app bar with
/// white-on-black text that read dark-on-primary in light mode.
///
/// Reordering: in reorder mode only the handle starts a drag, so the list
/// still scrolls on touch and a tap does not start playback; every row's
/// actions also offer Move up / Move down, so nothing needs a drag at all.
class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlaylistViewModel>().selectPlaylist(widget.playlistId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final playlist = viewModel.selectedPlaylist?.id == widget.playlistId
              ? viewModel.selectedPlaylist
              : null;

          if (playlist == null) {
            if (viewModel.isLoadingTracks || viewModel.isLoading) {
              return const SafeArea(
                child: LoadingStateView(kind: SkeletonKind.detailHeader),
              );
            }
            final error = viewModel.errorMessage;
            if (error != null) {
              return _withBackBar(
                ErrorStateView(
                  message: error,
                  onRetry: () => _reload(viewModel),
                ),
              );
            }
            return _withBackBar(
              EmptyState(
                icon: OmnisonicIcons.playlistPlay,
                title: 'Playlist not found',
                subtitle: 'It may have been deleted, or its server is offline.',
                action: FilledButton(
                  onPressed: () => context.go(AppRouter.playlistManagement),
                  child: const Text('All playlists'),
                ),
              ),
            );
          }

          final tracks = viewModel.selectedPlaylistTracks;
          return RefreshIndicator(
            onRefresh: () async => _reload(viewModel),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(playlist),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    PageGutter.of(context),
                    OmnisonicSpacing.sm,
                    PageGutter.of(context),
                    OmnisonicSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(playlist, tracks),
                  ),
                ),
                if (viewModel.errorMessage != null)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      PageGutter.of(context),
                      0,
                      PageGutter.of(context),
                      OmnisonicSpacing.ms,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: InlineBanner(
                        kind: BannerKind.warning,
                        message: viewModel.errorMessage!,
                        action: TextButton(
                          onPressed: () => _reload(viewModel),
                          child: const Text('Try again'),
                        ),
                      ),
                    ),
                  ),
                _buildTrackList(playlist, viewModel, tracks),
                const SliverToBoxAdapter(
                  child: SizedBox(height: OmnisonicLayout.pageBottom),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// A page with no content still needs a way out.
  Widget _withBackBar(Widget body) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(leading: BackButton(onPressed: _leave)),
    body: body,
  );

  void _leave() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRouter.playlistManagement);
    }
  }

  Future<void> _reload(PlaylistViewModel viewModel) {
    viewModel.clearError();
    return viewModel.selectPlaylist(widget.playlistId);
  }

  Widget _buildAppBar(Playlist playlist) {
    return SliverAppBar(
      pinned: true,
      leading: BackButton(onPressed: _leave),
      actions: [
        IconButton(
          icon: Icon(
            _isReorderMode ? OmnisonicIcons.check : OmnisonicIcons.reorder,
          ),
          isSelected: _isReorderMode,
          onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          tooltip: _isReorderMode ? 'Done reordering' : 'Reorder tracks',
        ),
        MenuAnchor(
          builder: (context, controller, child) => IconButton(
            icon: const Icon(OmnisonicIcons.moreVert),
            tooltip: 'Playlist actions',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(OmnisonicIcons.edit),
              onPressed: () =>
                  showPlaylistFormDialog(context, playlist: playlist),
              child: const Text('Edit'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(OmnisonicIcons.copy),
              onPressed: () => duplicatePlaylistFlow(context, playlist),
              child: const Text('Duplicate'),
            ),
            MenuItemButton(
              leadingIcon: Icon(
                OmnisonicIcons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _delete(playlist),
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
        const SizedBox(width: OmnisonicSpacing.xs),
      ],
    );
  }

  Widget _buildHeader(Playlist playlist, List<Track> tracks) {
    final total = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final canPlay = tracks.isNotEmpty;

    return DetailHeader(
      eyebrow: playlist.isPublic ? 'Public playlist' : 'Private playlist',
      title: playlist.name,
      artwork: CoverArt(
        url: playlist.coverArtUrl,
        fallbackIcon: OmnisonicIcons.playlistPlay,
        elevated: true,
      ),
      subtitle: playlist.description?.isNotEmpty == true
          ? Text(
              playlist.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      chips: [
        MetadataChip(
          icon: OmnisonicIcons.queueMusic,
          label: pluralize(
            tracks.isNotEmpty ? tracks.length : playlist.trackCount,
            'track',
          ),
        ),
        if (tracks.isNotEmpty)
          MetadataChip(
            icon: OmnisonicIcons.accessTime,
            label: formatTotalDuration(total),
          ),
        if (playlist.owner?.isNotEmpty == true)
          MetadataChip(icon: OmnisonicIcons.person, label: playlist.owner!),
      ],
      actions: [
        FilledButton.icon(
          onPressed: canPlay ? () => _play(tracks, 0) : null,
          icon: const Icon(OmnisonicIcons.playArrow),
          label: const Text('Play'),
        ),
        OutlinedButton.icon(
          onPressed: canPlay ? () => _play(tracks, 0, shuffle: true) : null,
          icon: const Icon(OmnisonicIcons.shuffle),
          label: const Text('Shuffle'),
        ),
      ],
    );
  }

  Widget _buildTrackList(
    Playlist playlist,
    PlaylistViewModel viewModel,
    List<Track> tracks,
  ) {
    if (tracks.isEmpty && viewModel.isLoadingTracks) {
      return LoadingStateView.sliver(kind: SkeletonKind.list, itemCount: 6);
    }

    if (tracks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: OmnisonicIcons.musicNote,
          title: 'No tracks yet',
          subtitle:
              'Add tracks from an album or from search with "Add to playlist".',
          action: OutlinedButton(
            onPressed: () => context.go(AppRouter.search),
            child: const Text('Search music'),
          ),
        ),
      );
    }

    Widget row(int index) {
      final track = tracks[index];
      return TrackRow(
        key: ValueKey('playlist-${track.id}-$index'),
        track: track,
        leading: TrackRowLeading.positionAndArt,
        position: index + 1,
        showAlbum: true,
        // In reorder mode a tap is not "play": the rows are being arranged.
        onTap: _isReorderMode ? null : () => _play(tracks, index),
        onShowActions: () => _showActions(playlist, tracks, index),
        reorderIndex: _isReorderMode ? index : null,
      );
    }

    if (_isReorderMode) {
      return SliverReorderableList(
        itemCount: tracks.length,
        onReorderItem: (oldIndex, newIndex) =>
            viewModel.moveTrackInPlaylist(playlist.id, oldIndex, newIndex),
        itemBuilder: (context, index) => row(index),
      );
    }
    return SliverList.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) => row(index),
    );
  }

  void _showActions(Playlist playlist, List<Track> tracks, int index) {
    final viewModel = context.read<PlaylistViewModel>();
    final track = tracks[index];
    showTrackActions(
      context,
      track,
      onPlay: () => _play(tracks, index),
      extra: [
        if (index > 0)
          MediaAction(
            'Move up',
            OmnisonicIcons.arrowUpward,
            (_) => viewModel.moveTrackInPlaylist(playlist.id, index, index - 1),
          ),
        if (index < tracks.length - 1)
          MediaAction(
            'Move down',
            OmnisonicIcons.arrowDownward,
            (_) => viewModel.moveTrackInPlaylist(playlist.id, index, index + 1),
          ),
        MediaAction(
          'Remove from playlist',
          OmnisonicIcons.remove,
          (context) => _remove(playlist, track, index),
        ),
      ],
    );
  }

  /// Removing is reversible, so it happens straight away with Undo rather
  /// than behind a confirmation dialog.
  Future<void> _remove(Playlist playlist, Track track, int index) async {
    final viewModel = context.read<PlaylistViewModel>();
    final ok = await viewModel.removeTrackFromPlaylist(playlist.id, track.id);
    if (!ok || !mounted) return;
    showFeedback(
      context,
      'Removed "${track.title}"',
      actionLabel: 'Undo',
      onAction: () async {
        final added = await viewModel.addTrackToPlaylist(playlist.id, track.id);
        if (!added) return;
        // Re-adding appends; put it back where it was.
        final last = viewModel.selectedPlaylistTracks.length - 1;
        if (index < last) {
          await viewModel.moveTrackInPlaylist(playlist.id, last, index);
        }
      },
    );
  }

  Future<void> _delete(Playlist playlist) async {
    final deleted = await confirmAndDeletePlaylist(context, playlist);
    // Opened from a deep link there is nothing to pop back to, and popping
    // the shell's only page would leave the user on a deleted playlist.
    if (deleted && mounted) _leave();
  }

  void _play(List<Track> tracks, int index, {bool shuffle = false}) {
    final queue = shuffle ? (List<Track>.of(tracks)..shuffle()) : tracks;
    context.read<PlaybackViewModel>().playTrack(
      queue[shuffle ? 0 : index],
      queue: queue,
      startIndex: shuffle ? 0 : index,
    );
  }
}
