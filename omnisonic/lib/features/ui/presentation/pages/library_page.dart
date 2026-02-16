import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../music/presentation/viewmodels/playlist_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../models/library_tab.dart';
import '../models/library_sort_state.dart';
import '../services/library_sort_service.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/utils/animation_utils.dart';

/// Library page displaying albums, artists, and playlists
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late LibrarySortState _sortState;

  @override
  void initState() {
    super.initState();
    _sortState = LibrarySortState();
  }

  @override
  Widget build(BuildContext context) {
    final tabName = GoRouterState.of(context).uri.queryParameters['tab'];
    final activeTab = LibraryTab.fromName(tabName) ?? LibraryTab.albums;

    return Scaffold(
      appBar: AppBar(
        title: Text(activeTab.label),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncLibrary,
            tooltip: 'Sync Library',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort Options',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AnimationConstants.quickAnimation,
        switchInCurve: AnimationConstants.smoothCurve,
        switchOutCurve: AnimationConstants.smoothCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(activeTab),
          child: _buildSectionForTab(activeTab),
        ),
      ),
    );
  }

  Widget _buildSectionForTab(LibraryTab tab) {
    switch (tab) {
      case LibraryTab.albums:
        return _buildAlbumsTab();
      case LibraryTab.artists:
        return _buildArtistsTab();
      case LibraryTab.playlists:
        return _buildPlaylistsTab();
    }
  }

  Widget _buildAlbumsTab() {
    return Consumer2<MusicLibraryViewModel, ServerManagementViewModel>(
      builder: (context, viewModel, serverViewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingGrid();
        }

        final albums = viewModel.albums;
        if (albums.isEmpty) {
          return EmptyState(
            icon: Icons.album,
            title: 'No Albums',
            subtitle: 'Connect to servers and sync your library to see albums here',
            action: ElevatedButton(
              onPressed: _syncLibrary,
              child: const Text('Sync Library'),
            ),
          );
        }

        final dedupedAlbums = _dedupeAlbumsByServer(albums);
        final sortOption = _sortState.getOption(LibraryTab.albums);
        final sortedAlbums = LibrarySortService.sortAlbums(dedupedAlbums, sortOption);

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: ResponsiveGridView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minItemWidth: 160,
            spacing: 20,
            childAspectRatio: 0.72,
            children: sortedAlbums.map((album) {
              return AlbumCard(
                album: album,
                onTap: () => _onAlbumTapped(album),
                showArtist: true,
                showMeta: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingGrid();
        }

        final artists = viewModel.artists;
        if (artists.isEmpty) {
          return EmptyState(
            icon: Icons.person,
            title: 'No Artists',
            subtitle: 'Connect to servers and sync your library to see artists here',
            action: ElevatedButton(
              onPressed: _syncLibrary,
              child: const Text('Sync Library'),
            ),
          );
        }

        final sortOption = _sortState.getOption(LibraryTab.artists);
        final sortedArtists = LibrarySortService.sortArtists(artists, sortOption);

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: ResponsiveGridView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minItemWidth: 150,
            spacing: 20,
            childAspectRatio: 0.72,
            children: sortedArtists.map((artist) {
              return ArtistCard(
                artist: artist,
                onTap: () => _onArtistTapped(artist),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    return Consumer<PlaylistViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingGrid();
        }

        final playlists = viewModel.playlists;
        if (playlists.isEmpty) {
          return EmptyState(
            icon: Icons.playlist_play,
            title: 'No Playlists',
            subtitle: 'Create your first playlist to organize your music',
            action: ElevatedButton.icon(
              onPressed: () => context.go('/playlist-management'),
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
            ),
          );
        }

        final sortOption = _sortState.getOption(LibraryTab.playlists);
        final sortedPlaylists = LibrarySortService.sortPlaylists(playlists, sortOption);

        return RefreshIndicator(
          onRefresh: viewModel.refreshPlaylists,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.playlist_play, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      '${sortedPlaylists.length} playlist${sortedPlaylists.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/playlist-management'),
                      icon: const Icon(Icons.settings),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ResponsiveGridView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  minItemWidth: 160,
                  spacing: 20,
                  childAspectRatio: 0.72,
                  children: sortedPlaylists.map((playlist) {
                    return PlaylistCard(
                      playlist: playlist,
                      onTap: () => _onPlaylistTapped(playlist),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return const ShimmerCard();
      },
    );
  }

  void _onAlbumTapped(Album album) {
    // Navigate to album detail page
    context.push('/album-detail', extra: album);
  }

  void _onArtistTapped(Artist artist) {
    // Navigate to artist detail page
    context.push('/artist-detail', extra: artist);
  }

  void _onPlaylistTapped(Playlist playlist) {
    context.go('/playlist-detail?id=${playlist.id}');
  }

  void _syncLibrary() {
    context.read<MusicLibraryViewModel>().syncCollection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing library...')),
    );
  }

  void _showSortOptions() {
    final tabName = GoRouterState.of(context).uri.queryParameters['tab'];
    final currentTab = LibraryTab.fromName(tabName) ?? LibraryTab.albums;
    final currentOption = _sortState.getOption(currentTab);

    AnimationUtils.showCustomBottomSheet(
      context: context,
      builder: (context) => SortOptionsSheet(
        currentOption: currentOption,
        onOptionSelected: (option) {
          setState(() {
            _sortState.setOption(currentTab, option);
          });
        },
      ),
    );
  }

  List<Album> _dedupeAlbumsByServer(List<Album> albums) {
    final grouped = <String, List<Album>>{};
    for (final album in albums) {
      final key = _albumGroupKey(album);
      grouped.putIfAbsent(key, () => []).add(album);
    }

    final deduped = <Album>[];
    for (final group in grouped.values) {
      group.sort((a, b) {
        final aTracks = a.trackCount ?? 0;
        final bTracks = b.trackCount ?? 0;
        if (aTracks != bTracks) {
          return bTracks.compareTo(aTracks);
        }
        return b.lastModified.compareTo(a.lastModified);
      });
      deduped.add(group.first);
    }
    return deduped;
  }

  String _albumGroupKey(Album album) {
    final title = _normalizeAlbumKey(album.title);
    final artist = album.artist; // Exact match for artist
    final year = album.year?.toString() ?? '';
    return '$title|$artist|$year';
  }

  String _normalizeAlbumKey(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

}