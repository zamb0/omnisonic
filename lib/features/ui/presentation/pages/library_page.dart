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
import '../../../../core/design_system/responsive_layout.dart';
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
    // The sidebar shell already exposes one entry per tab; the TabBar is the
    // only way into Artists and Playlists when there is no sidebar.
    final showTabBar =
        MediaQuery.of(context).size.width < ResponsiveBreakpoints.tablet;

    return Scaffold(
      appBar: AppBar(
        title: Text(showTabBar ? 'Library' : activeTab.label),
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
        bottom: showTabBar ? _buildTabBar(activeTab) : null,
      ),
      body: AnimatedSwitcher(
        duration: AnimationConstants.quickAnimation,
        switchInCurve: AnimationConstants.smoothCurve,
        switchOutCurve: AnimationConstants.smoothCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(activeTab),
          child: _buildSectionForTab(activeTab),
        ),
      ),
    );
  }

  /// Tab strip driven by the `?tab=` query parameter, so the sidebar, the tab
  /// strip and deep links all read and write the same piece of state and the
  /// back button steps through tab changes.
  PreferredSizeWidget _buildTabBar(LibraryTab activeTab) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      // Keyed on the active tab so the controller is rebuilt whenever the query
      // parameter changes from elsewhere (sidebar, deep link, back button)
      // instead of drifting out of sync with it.
      child: DefaultTabController(
        key: ValueKey(activeTab),
        length: LibraryTab.count,
        initialIndex: activeTab.index,
        child: TabBar(
          tabs: LibraryTab.values.map((tab) => Tab(text: tab.label)).toList(),
          onTap: (index) => _onTabSelected(LibraryTab.fromIndex(index)),
        ),
      ),
    );
  }

  void _onTabSelected(LibraryTab tab) {
    context.go('/library?tab=${tab.name}');
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

        final albums = viewModel.filteredAlbums;
        if (albums.isEmpty &&
            !viewModel.showStarredOnly &&
            viewModel.selectedGenre == null) {
          return EmptyState(
            icon: Icons.album,
            title: 'No Albums',
            subtitle:
                'Connect to servers and sync your library to see albums here',
            action: ElevatedButton(
              onPressed: _syncLibrary,
              child: const Text('Sync Library'),
            ),
          );
        }

        final dedupedAlbums = _dedupeAlbumsByServer(albums);
        final sortOption = _sortState.getOption(LibraryTab.albums);
        final sortedAlbums = LibrarySortService.sortAlbums(
          dedupedAlbums,
          sortOption,
        );

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: Column(
            children: [
              _buildFilterSection(viewModel),
              Expanded(
                child: sortedAlbums.isEmpty
                    ? EmptyState(
                        icon: Icons.filter_alt_off,
                        title: 'No Results',
                        subtitle: 'No albums match your current filters',
                        action: TextButton(
                          onPressed: () => viewModel.clearFilters(),
                          child: const Text('Clear Filters'),
                        ),
                      )
                    : ResponsiveGridView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        minItemWidth: 160,
                        spacing: 20,
                        childAspectRatio: 0.72,
                        children: sortedAlbums.map((album) {
                          final isStarred = viewModel.isAlbumStarred(album);
                          return AlbumCard(
                            album: album,
                            onTap: () => _onAlbumTapped(album),
                            onStar: !isStarred
                                ? () => viewModel.starAlbum(album)
                                : null,
                            onUnstar: isStarred
                                ? () => viewModel.unstarAlbum(album)
                                : null,
                            isStarred: isStarred,
                            showArtist: true,
                            showMeta: true,
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
            subtitle:
                'Connect to servers and sync your library to see artists here',
            action: ElevatedButton(
              onPressed: _syncLibrary,
              child: const Text('Sync Library'),
            ),
          );
        }

        final sortOption = _sortState.getOption(LibraryTab.artists);
        final sortedArtists = LibrarySortService.sortArtists(
          artists,
          sortOption,
        );

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
        final sortedPlaylists = LibrarySortService.sortPlaylists(
          playlists,
          sortOption,
        );

        return RefreshIndicator(
          onRefresh: viewModel.refreshPlaylists,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.playlist_play,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

  Widget _buildFilterSection(MusicLibraryViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Text('Filters', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (viewModel.showStarredOnly || viewModel.selectedGenre != null)
                TextButton.icon(
                  onPressed: () => viewModel.clearFilters(),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Starred filter chip
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16),
                    SizedBox(width: 4),
                    Text('Starred'),
                  ],
                ),
                selected: viewModel.showStarredOnly,
                onSelected: (_) => viewModel.toggleStarredFilter(),
              ),
              // Genre filter chips
              if (viewModel.genres.isNotEmpty)
                PopupMenuButton<String>(
                  child: Chip(
                    avatar: Icon(
                      Icons.music_note,
                      size: 16,
                      color: viewModel.selectedGenre != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    label: Text(viewModel.selectedGenre ?? 'All Genres'),
                    deleteIcon: viewModel.selectedGenre != null
                        ? const Icon(Icons.close, size: 16)
                        : null,
                    onDeleted: viewModel.selectedGenre != null
                        ? () => viewModel.setGenreFilter(null)
                        : null,
                    backgroundColor: viewModel.selectedGenre != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: null,
                      child: Text('All Genres'),
                    ),
                    const PopupMenuDivider(),
                    ...viewModel.genres.map((genre) {
                      return PopupMenuItem<String>(
                        value: genre.name,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                genre.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${genre.albumCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onSelected: (value) => viewModel.setGenreFilter(value),
                ),
            ],
          ),
        ],
      ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Syncing library...')));
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
