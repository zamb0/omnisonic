import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';

/// Page displaying all starred (favorited) content
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  /// The tab the user was on, kept across visits: the shell rebuilds this
  /// page on every tab switch, and it used to come back on Albums.
  static int _lastTab = 0;

  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
    initialIndex: _lastTab,
  )..addListener(() => _lastTab = _tabController.index);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeaderAppBar(
        title: 'Starred',
        bottom: PageHeaderAppBar.tabBar(
          context,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Tracks'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<MusicLibraryViewModel>().refreshSmartCollections(),
        child: TabBarView(
          controller: _tabController,
          children: [_buildAlbumsTab(), _buildArtistsTab(), _buildTracksTab()],
        ),
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final starredAlbums = viewModel.starredAlbums;

        return AsyncStateSwitcher(
          isLoading: viewModel.isLoading,
          error: viewModel.errorMessage,
          onRetry: () => _retry(viewModel),
          isEmpty: starredAlbums.isEmpty,
          skeleton: SkeletonKind.grid,
          empty: const EmptyState(
            icon: OmnisonicIcons.starOutline,
            title: 'No Starred Albums',
            subtitle: 'Star your favorite albums to see them here',
          ),
          builder: (context) => ResponsiveGridView.media(
            padding: const EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
            meta: true,
            itemCount: starredAlbums.length,
            itemBuilder: (context, index) {
              final album = starredAlbums[index];
              final isStarred = viewModel.isAlbumStarred(album);
              return AlbumCard(
                key: ValueKey(album.id),
                album: album,
                onTap: () => _onAlbumTapped(album),
                onStar: () => viewModel.starAlbum(album),
                onUnstar: () => viewModel.unstarAlbum(album),
                isStarred: isStarred,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final starredArtists = viewModel.starredArtists;

        return AsyncStateSwitcher(
          isLoading: viewModel.isLoading,
          error: viewModel.errorMessage,
          onRetry: () => _retry(viewModel),
          isEmpty: starredArtists.isEmpty,
          skeleton: SkeletonKind.grid,
          empty: const EmptyState(
            icon: OmnisonicIcons.starOutline,
            title: 'No Starred Artists',
            subtitle: 'Star your favorite artists to see them here',
          ),
          builder: (context) => ResponsiveGridView.media(
            padding: const EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
            subtitle: false,
            meta: true,
            itemCount: starredArtists.length,
            itemBuilder: (context, index) {
              final artist = starredArtists[index];
              return ArtistCard(
                key: ValueKey(artist.id),
                artist: artist,
                onTap: () => _onArtistTapped(artist),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTracksTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final starredTracks = viewModel.starredTracks;

        return AsyncStateSwitcher(
          isLoading: viewModel.isLoading,
          error: viewModel.errorMessage,
          onRetry: () => _retry(viewModel),
          isEmpty: starredTracks.isEmpty,
          empty: const EmptyState(
            icon: OmnisonicIcons.starOutline,
            title: 'No Starred Tracks',
            subtitle: 'Star your favorite tracks to see them here',
          ),
          builder: (context) => ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
            itemCount: starredTracks.length,
            itemBuilder: (context, index) {
              final track = starredTracks[index];
              return TrackRow(
                key: ValueKey(track.id),
                track: track,
                serverId: track.serverId,
                onTap: () => _onTrackTapped(track, starredTracks),
                onShowActions: () => showTrackActions(
                  context,
                  track,
                  onPlay: () => _onTrackTapped(track, starredTracks),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _retry(MusicLibraryViewModel viewModel) {
    viewModel.clearError();
    viewModel.refreshSmartCollections();
  }

  void _onAlbumTapped(Album album) {
    context.push(AppRouter.albumDetailLocation(album.id), extra: album);
  }

  void _onArtistTapped(Artist artist) {
    context.push(AppRouter.artistDetailLocation(artist.id), extra: artist);
  }

  void _onTrackTapped(Track track, List<Track> queue) {
    final startIndex = queue.indexOf(track);
    context.read<PlaybackViewModel>().playTrack(
      track,
      queue: queue,
      startIndex: startIndex < 0 ? 0 : startIndex,
    );
  }
}
