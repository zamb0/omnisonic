import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../models/library_tab.dart';
import '../models/library_sort_state.dart';
import '../models/sort_option.dart';
import '../services/library_sort_service.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/debouncer.dart';
import 'main_shell.dart';
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

  late LibrarySortState _sortState;
  late TextEditingController _searchController;

  /// Filtering runs over the whole sorted album list, so it waits for a pause
  /// in typing rather than running on every keystroke.
  final Debouncer _searchDebouncer = Debouncer();
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
    _searchDebouncer.dispose();
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
    // only way into Artists and Playlists when there is no sidebar. Asking the
    // shell rather than MediaQuery, because the shell decides from its own
    // constraints — on a 1000px window it shows the icon-only rail while the
    // screen still reads as tablet-wide, which used to hide the TabBar and
    // leave both tabs unreachable.
    final showTabBar = !ShellLayout.hasSidebar(context);

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
            icon: const Icon(OmnisonicIcons.sync),
            onPressed: _syncLibrary,
            tooltip: 'Sync Library',
          ),
          IconButton(
            icon: const Icon(OmnisonicIcons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort Options',
          ),
        ],
        bottom: showTabBar ? _buildTabBar(activeTab) : null,
      ),
      body: AnimatedSwitcher(
        duration: AnimationUtils.adjustedDuration(
          context,
          AnimationManager.quickDuration,
        ),
        switchInCurve: AnimationManager.standardCurve,
        switchOutCurve: AnimationManager.standardCurve,
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
    }
  }

  Widget _buildAlbumsTab() {
    return Consumer2<MusicLibraryViewModel, ServerManagementViewModel>(
      builder: (context, viewModel, serverViewModel, child) {
        if (viewModel.isLoading) {
          return const LoadingStateView(kind: SkeletonKind.grid);
        }

        // A sync failure used to surface only as a SnackBar, which is gone
        // three seconds later and leaves an empty grid behind it.
        final error = viewModel.errorMessage;
        if (error != null) {
          return ErrorStateView(message: error, onRetry: _syncLibrary);
        }

        final albums = viewModel.filteredAlbums;
        if (albums.isEmpty &&
            !viewModel.showStarredOnly &&
            viewModel.selectedGenre == null) {
          return EmptyState(
            icon: OmnisonicIcons.album,
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
                        icon: OmnisonicIcons.filterAltOff,
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
                    : ResponsiveGridView.media(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        meta: true,
                        itemCount: displayedAlbums.length,
                        itemBuilder: (context, index) {
                          final album = displayedAlbums[index];
                          final isStarred = viewModel.isAlbumStarred(album);
                          final sources =
                              _albumSourceServerIdsCache[album.id] ?? const [];
                          return AlbumCard(
                            key: ValueKey(album.id),
                            album: album,
                            onTap: () => _onAlbumTapped(album),
                            onStar: () => viewModel.starAlbum(album),
                            onUnstar: () => viewModel.unstarAlbum(album),
                            isStarred: isStarred,
                            sourceServerIds: sources.length > 1
                                ? sources
                                : null,
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
            Icon(
              OmnisonicIcons.search,
              size: OmnisonicIconSizes.smd,
              color: scheme.onSurfaceVariant,
            ),
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
                onChanged: (value) => _searchDebouncer.run(() {
                  if (!mounted) return;
                  setState(() => _searchQuery = value.trim().toLowerCase());
                }),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(OmnisonicIcons.close, size: 18),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  _searchDebouncer.cancel();
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
          return const LoadingStateView(kind: SkeletonKind.grid);
        }

        final error = viewModel.errorMessage;
        if (error != null) {
          return ErrorStateView(message: error, onRetry: _syncLibrary);
        }

        final artists = viewModel.artists;
        if (artists.isEmpty) {
          return EmptyState(
            icon: OmnisonicIcons.person,
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
          child: ResponsiveGridView.media(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            subtitle: false,
            meta: true,
            itemCount: sortedArtists.length,
            itemBuilder: (context, index) {
              final artist = sortedArtists[index];
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
                  OmnisonicIcons.filterList,
                  size: OmnisonicIconSizes.smd,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Text('Filters', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (viewModel.showStarredOnly ||
                    viewModel.selectedGenre != null)
                  TextButton.icon(
                    onPressed: () => viewModel.clearFilters(),
                    icon: const Icon(OmnisonicIcons.clear, size: 16),
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
                      Icon(OmnisonicIcons.star, size: 16),
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
                        OmnisonicIcons.musicNote,
                        size: OmnisonicIconSizes.sm,
                        color: viewModel.selectedGenre != null
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      label: Text(viewModel.selectedGenre ?? 'All Genres'),
                      deleteIcon: viewModel.selectedGenre != null
                          ? const Icon(OmnisonicIcons.close, size: 16)
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
    context.push(AppRouter.albumDetailLocation(album.id), extra: album);
  }

  void _onArtistTapped(Artist artist) {
    // Navigate to artist detail page
    context.push(AppRouter.artistDetailLocation(artist.id), extra: artist);
  }

  Future<void> _syncLibrary() async {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<MusicLibraryViewModel>();

    viewModel.clearError();
    messenger.showSnackBar(const SnackBar(content: Text('Syncing library...')));

    final success = await viewModel.syncCollection();
    if (!mounted) return;

    messenger.hideCurrentSnackBar();
    // Only the success case is a SnackBar now. A failure renders inline
    // through ErrorStateView, which stays on screen and keeps its Retry
    // rather than disappearing after three seconds.
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('Library synced')));
    }
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
