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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Oversized display title on a transparent bar, matching Library: the
        // art tint has to run behind the header rather than stop at it.
        toolbarHeight: 72,
        titleSpacing: OmnisonicSpacing.xs,
        title: Text(
          'Starred',
          style: OmnisonicTypography.pageTitle.copyWith(
            color: scheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: OmnisonicTypography.navLabel,
          unselectedLabelStyle: OmnisonicTypography.navLabel,
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          tabs: const [
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Tracks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAlbumsTab(), _buildArtistsTab(), _buildTracksTab()],
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final starredAlbums = viewModel.starredAlbums;

        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (starredAlbums.isEmpty) {
          return EmptyState(
            icon: Icons.star_outline,
            title: 'No Starred Albums',
            subtitle: 'Star your favorite albums to see them here',
          );
        }

        return ResponsiveGridView(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.lg,
            vertical: OmnisonicSpacing.md,
          ),
          minItemWidth: 160,
          spacing: 20,
          childAspectRatio: 0.72,
          itemCount: starredAlbums.length,
          itemBuilder: (context, index) {
            final album = starredAlbums[index];
            final isStarred = viewModel.isAlbumStarred(album);
            return AlbumCard(
              album: album,
              onTap: () => _onAlbumTapped(album),
              onUnstar: isStarred ? () => viewModel.unstarAlbum(album) : null,
              isStarred: isStarred,
              showArtist: true,
              showMeta: true,
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final starredArtists = viewModel.starredArtists;

        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (starredArtists.isEmpty) {
          return EmptyState(
            icon: Icons.star_outline,
            title: 'No Starred Artists',
            subtitle: 'Star your favorite artists to see them here',
          );
        }

        return ResponsiveGridView(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.lg,
            vertical: OmnisonicSpacing.md,
          ),
          minItemWidth: 150,
          spacing: 20,
          childAspectRatio: 0.72,
          itemCount: starredArtists.length,
          itemBuilder: (context, index) {
            final artist = starredArtists[index];
            return ArtistCard(
              artist: artist,
              onTap: () => _onArtistTapped(artist),
            );
          },
        );
      },
    );
  }

  Widget _buildTracksTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final starredTracks = viewModel.starredTracks;

        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (starredTracks.isEmpty) {
          return EmptyState(
            icon: Icons.star_outline,
            title: 'No Starred Tracks',
            subtitle: 'Star your favorite tracks to see them here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.lg,
            vertical: OmnisonicSpacing.md,
          ),
          itemCount: starredTracks.length,
          itemBuilder: (context, index) {
            final track = starredTracks[index];
            return TrackTile(
              track: track,
              onTap: () => _onTrackTapped(track, starredTracks),
            );
          },
        );
      },
    );
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
