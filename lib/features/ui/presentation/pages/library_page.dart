import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../music/presentation/viewmodels/playlist_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../models/library_tab.dart';
import '../models/library_sort_state.dart';
import '../models/sort_option.dart';
import '../services/library_sort_service.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../../core/utils/animation_utils.dart';

/// Library page displaying albums, artists, and playlists
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  // 3 columns fit comfortably down to ~360px-wide phones; wider layouts
  // (tablet/desktop sidebar shell) scale up from here same as before.
  static const double _albumGridMinItemWidth = 80;
  static const double _albumGridSpacing = 12;

  late LibrarySortState _sortState;
  late TextEditingController _searchController;
  String _searchQuery = '';

  // Dedupe + sort are O(n log n) over the whole collection; memoized here so
  // they only re-run when the view model hands back a different album list
  // (viewModel.filteredAlbums is itself cached and reference-stable unless
  // the source data or filters actually changed) or the sort option changes,
  // instead of on every rebuild the Consumer2 triggers.
  List<Album>? _albumsSortInputCache;
  SortOption? _sortOptionCache;
  List<Album> _sortedAlbumsCache = const [];
  int _originalAlbumCountCache = 0;
  Map<String, List<String>> _albumSourceServerIdsCache = const {};

  @override
  void initState() {
    super.initState();
    _sortState = LibrarySortState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Album> _getSortedAlbums(List<Album> albums, SortOption sortOption) {
    if (identical(albums, _albumsSortInputCache) &&
        sortOption == _sortOptionCache) {
      return _sortedAlbumsCache;
    }

    final deduped = dedupeAlbumsByServer(albums);
    final sortedAlbums = LibrarySortService.sortAlbums(
      deduped.albums,
      sortOption,
    );

    _albumsSortInputCache = albums;
    _sortOptionCache = sortOption;
    _sortedAlbumsCache = sortedAlbums;
    _originalAlbumCountCache = albums.length;
    _albumSourceServerIdsCache = deduped.sourceServerIds;
    return sortedAlbums;
  }

  List<Album> _filterBySearch(List<Album> albums) {
    if (_searchQuery.isEmpty) return albums;
    return albums
        .where(
          (album) =>
              album.title.toLowerCase().contains(_searchQuery) ||
              album.artist.toLowerCase().contains(_searchQuery),
        )
        .toList();
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
        // Oversized Gabarito title on a transparent bar: the art-tinted
        // background has to run behind the header, not stop at it.
        toolbarHeight: 72,
        titleSpacing: 4,
        title: Text(
          showTabBar ? 'Library' : activeTab.label,
          style: OmnisonicTypography.pageTitle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
        duration: AnimationUtils.adjustedDuration(
          context,
          AnimationConstants.quickAnimation,
        ),
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
          return _buildLoadingGrid(minItemWidth: _albumGridMinItemWidth);
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

        final sortOption = _sortState.getOption(LibraryTab.albums);
        final sortedAlbums = _getSortedAlbums(albums, sortOption);
        final displayedAlbums = _filterBySearch(sortedAlbums);

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: Column(
            children: [
              _buildSearchPill(),
              _buildAlbumCountLine(
                _sortedAlbumsCache.length,
                _originalAlbumCountCache,
              ),
              _buildFilterSection(viewModel),
              Expanded(
                child: displayedAlbums.isEmpty
                    ? EmptyState(
                        icon: Icons.filter_alt_off,
                        title: 'No Results',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'No albums match "$_searchQuery"'
                            : 'No albums match your current filters',
                        action: TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            viewModel.clearFilters();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      )
                    : ResponsiveGridView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        minItemWidth: _albumGridMinItemWidth,
                        spacing: _albumGridSpacing,
                        childAspectRatio: 0.72,
                        itemCount: displayedAlbums.length,
                        itemBuilder: (context, index) {
                          final album = displayedAlbums[index];
                          final isStarred = viewModel.isAlbumStarred(album);
                          final sources =
                              _albumSourceServerIdsCache[album.id] ?? const [];
                          return Stack(
                            children: [
                              AlbumCard(
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
                              ),
                              if (sources.length > 1)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: ServerDotStack(serverIds: sources),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchPill() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: OmnisonicTypography.bodyMedium.copyWith(
                  color: scheme.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search albums',
                  isDense: true,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCountLine(int dedupedCount, int originalCount) {
    final scheme = Theme.of(context).colorScheme;
    final albumWord = dedupedCount == 1 ? 'album' : 'albums';
    final text = originalCount > dedupedCount
        ? '$dedupedCount $albumWord · deduplicated from $originalCount'
        : '$dedupedCount $albumWord';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: OmnisonicTypography.metadata.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
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
            itemCount: sortedArtists.length,
            itemBuilder: (context, index) {
              final artist = sortedArtists[index];
              return ArtistCard(
                artist: artist,
                onTap: () => _onArtistTapped(artist),
              );
            },
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
                  itemCount: sortedPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = sortedPlaylists[index];
                    return PlaylistCard(
                      playlist: playlist,
                      onTap: () => _onPlaylistTapped(playlist),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Same geometry as the real content grids (minItemWidth/padding/aspect
  // ratio) so the shimmer collapses into the final layout instead of a
  // visible jump when the two-column skeleton gives way to up to six.
  Widget _buildLoadingGrid({double minItemWidth = 160}) {
    return ResponsiveGridView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      minItemWidth: minItemWidth,
      spacing: 20,
      childAspectRatio: 0.72,
      itemCount: 8,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }

  Widget _buildFilterSection(MusicLibraryViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                if (viewModel.showStarredOnly ||
                    viewModel.selectedGenre != null)
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

  Future<void> _syncLibrary() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Syncing library...')));

    final success = await context
        .read<MusicLibraryViewModel>()
        .syncCollection();
    if (!mounted) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Library synced' : 'Sync failed'),
        action: success
            ? null
            : SnackBarAction(label: 'Retry', onPressed: _syncLibrary),
      ),
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
}
