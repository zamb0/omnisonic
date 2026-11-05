import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../servers/presentation/widgets/server_form_dialog.dart';
import '../models/library_sort_state.dart';
import '../models/library_tab.dart';
import '../models/sort_option.dart';
import '../services/library_sort_service.dart';
import '../widgets/widgets.dart';
import 'main_shell.dart';

/// What the Library page remembers while the user is on another tab.
///
/// The shell rebuilds a tab's page each time it is selected, so the sort,
/// the search and the scroll position used to be lost on every switch.
class _LibraryMemory {
  static final sort = LibrarySortState();
  static final queries = <LibraryTab, String>{};
  static final offsets = <LibraryTab, double>{};
}

/// The library: albums and artists, searchable, sortable and filterable.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final LibrarySortState _sortState = _LibraryMemory.sort;
  final Map<LibraryTab, TextEditingController> _searchControllers = {
    for (final tab in LibraryTab.values)
      tab: TextEditingController(text: _LibraryMemory.queries[tab] ?? ''),
  };
  final Map<LibraryTab, ScrollController> _scrollControllers = {
    for (final tab in LibraryTab.values)
      tab: ScrollController(
        initialScrollOffset: _LibraryMemory.offsets[tab] ?? 0,
      ),
  };

  /// Filtering runs over the whole sorted list, so it waits for a pause in
  /// typing rather than running on every keystroke.
  final Debouncer _searchDebouncer = Debouncer();

  // Dedupe + sort are O(n log n) over the whole collection; memoized so they
  // only re-run when the view model hands back a different album list or the
  // sort changes, not on every rebuild.
  List<Album>? _albumsSortInputCache;
  SortOption? _sortOptionCache;
  List<Album> _sortedAlbumsCache = const [];
  int _originalAlbumCountCache = 0;
  Map<String, List<String>> _albumSourceServerIdsCache = const {};

  String _query(LibraryTab tab) =>
      (_LibraryMemory.queries[tab] ?? '').trim().toLowerCase();

  @override
  void dispose() {
    for (final entry in _scrollControllers.entries) {
      if (entry.value.hasClients) {
        _LibraryMemory.offsets[entry.key] = entry.value.offset;
      }
      entry.value.dispose();
    }
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    _searchDebouncer.dispose();
    super.dispose();
  }

  List<Album> _getSortedAlbums(List<Album> albums, SortOption sortOption) {
    if (identical(albums, _albumsSortInputCache) &&
        sortOption == _sortOptionCache) {
      return _sortedAlbumsCache;
    }

    final deduped = dedupeAlbumsByServer(albums);
    _albumsSortInputCache = albums;
    _sortOptionCache = sortOption;
    _sortedAlbumsCache = LibrarySortService.sortAlbums(
      deduped.albums,
      sortOption,
    );
    _originalAlbumCountCache = albums.length;
    _albumSourceServerIdsCache = deduped.sourceServerIds;
    return _sortedAlbumsCache;
  }

  @override
  Widget build(BuildContext context) {
    final tabName = GoRouterState.of(context).uri.queryParameters['tab'];
    final activeTab = LibraryTab.fromName(tabName) ?? LibraryTab.albums;
    // The sidebar shell already exposes one entry per tab; the TabBar is the
    // only way between them when there is no sidebar. Asking the shell rather
    // than MediaQuery, because the shell decides from its own constraints.
    final showTabBar = !ShellLayout.hasSidebar(context);

    return Scaffold(
      appBar: PageHeaderAppBar(
        title: showTabBar ? 'Library' : activeTab.label,
        actions: [
          // A spinner while it runs: the icon gave no sign of a ~10s sync.
          if (context.select<MusicLibraryViewModel, bool>((vm) => vm.isSyncing))
            const IconButton(
              onPressed: null,
              tooltip: 'Syncing library…',
              icon: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(OmnisonicIcons.sync),
              onPressed: _syncLibrary,
              tooltip: 'Sync library',
            ),
          IconButton(
            icon: const Icon(OmnisonicIcons.sort),
            onPressed: () => _showSortOptions(activeTab),
            tooltip: 'Sort',
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
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey(activeTab),
          child: switch (activeTab) {
            LibraryTab.albums => _buildAlbumsTab(),
            LibraryTab.artists => _buildArtistsTab(),
          },
        ),
      ),
    );
  }

  /// Tab strip driven by the `?tab=` query parameter, so the sidebar, the tab
  /// strip and deep links all read and write the same piece of state.
  PreferredSizeWidget _buildTabBar(LibraryTab activeTab) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      // Keyed on the active tab so the controller is rebuilt whenever the
      // query parameter changes from elsewhere.
      child: DefaultTabController(
        key: ValueKey(activeTab),
        length: LibraryTab.count,
        initialIndex: activeTab.index,
        child: Builder(
          builder: (context) => PageHeaderAppBar.tabBar(
            context,
            tabs: [for (final tab in LibraryTab.values) Tab(text: tab.label)],
            onTap: (index) =>
                context.go('/library?tab=${LibraryTab.fromIndex(index).name}'),
          ),
        ),
      ),
    );
  }

  /// The common frame of both tabs: loading, load error and the empty
  /// library are page states; everything else is a scroll view whose
  /// search, count and filters scroll away with the grid instead of
  /// sitting fixed above it (~170px of a 640px phone).
  Widget _buildTab({
    required LibraryTab tab,
    required MusicLibraryViewModel viewModel,
    required bool isEmptyLibrary,
    required String emptyTitle,
    required List<Widget> header,
    required List<Widget> body,
  }) {
    if (viewModel.isLoading && isEmptyLibrary) {
      return const LoadingStateView(kind: SkeletonKind.grid);
    }

    final error = viewModel.errorMessage;
    return RefreshIndicator(
      onRefresh: () => viewModel.syncCollection(),
      // The first cards fade in one after the other when the grid first shows.
      child: EntranceScope(
        child: CustomScrollView(
          controller: _scrollControllers[tab],
          // So pull-to-refresh works on the empty and error states too.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (error != null && isEmptyLibrary)
              ErrorStateView.sliver(message: error, onRetry: _syncLibrary)
            else if (isEmptyLibrary)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: tab == LibraryTab.albums
                      ? OmnisonicIcons.album
                      : OmnisonicIcons.person,
                  title: emptyTitle,
                  subtitle:
                      'Add a server and sync your library to see it here.',
                  // With no server a sync has nothing to read: the way out
                  // is adding one, straight to the form.
                  action: context.watch<ServerManagementViewModel>().hasServers
                      ? FilledButton(
                          onPressed: _syncLibrary,
                          child: const Text('Sync library'),
                        )
                      : FilledButton.icon(
                          onPressed: () => showServerFormDialog(context),
                          icon: const Icon(OmnisonicIcons.add),
                          label: const Text('Add server'),
                        ),
                ),
              )
            else ...[
              // With a library on screen, a failed sync is a banner, not a
              // page: what was there stays usable.
              if (error != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    OmnisonicSpacing.gutter(context),
                    OmnisonicSpacing.sm,
                    OmnisonicSpacing.gutter(context),
                    OmnisonicSpacing.xs,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: InlineBanner(
                      kind: BannerKind.warning,
                      message: error,
                      action: TextButton(
                        onPressed: _syncLibrary,
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ),
              for (final widget in header) SliverToBoxAdapter(child: widget),
              ...body,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final albums = viewModel.filteredAlbums;
        final filtered =
            viewModel.showStarredOnly || viewModel.selectedGenre != null;
        final isEmptyLibrary = viewModel.albums.isEmpty;

        final sortOption = _sortState.getOption(LibraryTab.albums);
        final sorted = _getSortedAlbums(albums, sortOption);
        final query = _query(LibraryTab.albums);
        final shown = query.isEmpty
            ? sorted
            : [
                for (final album in sorted)
                  if (album.title.toLowerCase().contains(query) ||
                      album.artist.toLowerCase().contains(query))
                    album,
              ];

        return _buildTab(
          tab: LibraryTab.albums,
          viewModel: viewModel,
          isEmptyLibrary: isEmptyLibrary,
          emptyTitle: 'No albums yet',
          header: [
            _buildSearchPill(LibraryTab.albums, 'Search albums'),
            _buildCountLine(
              shown: shown.length,
              total: sorted.length,
              before: _originalAlbumCountCache,
              noun: 'album',
            ),
            _buildFilters(viewModel),
          ],
          body: [
            if (shown.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: OmnisonicIcons.filterAltOff,
                  title: 'No matching albums',
                  subtitle: query.isNotEmpty
                      ? 'Nothing matches '
                            '"${_searchControllers[LibraryTab.albums]!.text.trim()}".'
                      : 'No albums match the current filters.',
                  action: TextButton(
                    onPressed: () {
                      _setQuery(LibraryTab.albums, '');
                      if (filtered) viewModel.clearFilters();
                    },
                    child: const Text('Clear search and filters'),
                  ),
                ),
              )
            else
              _buildGrid(
                itemCount: shown.length,
                meta: true,
                itemBuilder: (context, index) {
                  final album = shown[index];
                  final sources =
                      _albumSourceServerIdsCache[album.id] ?? const [];
                  return AlbumCard(
                    key: ValueKey(album.id),
                    album: album,
                    onTap: () => _onAlbumTapped(album),
                    onStar: () => viewModel.starAlbum(album),
                    onUnstar: () => viewModel.unstarAlbum(album),
                    isStarred: viewModel.isAlbumStarred(album),
                    sourceServerIds: sources.length > 1 ? sources : null,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final artists = viewModel.artists;
        final sorted = LibrarySortService.sortArtists(
          artists,
          _sortState.getOption(LibraryTab.artists),
        );
        final query = _query(LibraryTab.artists);
        final shown = query.isEmpty
            ? sorted
            : [
                for (final artist in sorted)
                  if (artist.name.toLowerCase().contains(query)) artist,
              ];

        return _buildTab(
          tab: LibraryTab.artists,
          viewModel: viewModel,
          isEmptyLibrary: artists.isEmpty,
          emptyTitle: 'No artists yet',
          header: [
            _buildSearchPill(LibraryTab.artists, 'Search artists'),
            _buildCountLine(
              shown: shown.length,
              total: sorted.length,
              before: viewModel.allArtists.length,
              noun: 'artist',
            ),
          ],
          body: [
            if (shown.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: OmnisonicIcons.searchOff,
                  title: 'No matching artists',
                  subtitle:
                      'Nothing matches '
                      '"${_searchControllers[LibraryTab.artists]!.text.trim()}".',
                  action: TextButton(
                    onPressed: () => _setQuery(LibraryTab.artists, ''),
                    child: const Text('Clear search'),
                  ),
                ),
              )
            else
              _buildGrid(
                itemCount: shown.length,
                subtitle: false,
                meta: true,
                itemBuilder: (context, index) {
                  final artist = shown[index];
                  return ArtistCard(
                    key: ValueKey(artist.id),
                    artist: artist,
                    onTap: () => _onArtistTapped(artist),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    bool subtitle = true,
    bool meta = false,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        OmnisonicSpacing.gutter(context),
        OmnisonicLayout.headerGap,
        OmnisonicSpacing.gutter(context),
        OmnisonicLayout.pageBottom,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = MediaGridPreset.columnsFor(width);
          final cell = MediaGridPreset.cellWidth(width, columns);
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: MediaGridPreset.spacing,
              mainAxisSpacing: MediaGridPreset.spacing,
              mainAxisExtent: MediaCard.extentFor(
                context,
                cell,
                subtitle: subtitle,
                meta: meta,
              ),
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) =>
                Staggered(index: index, child: itemBuilder(context, index)),
          );
        },
      ),
    );
  }

  void _setQuery(LibraryTab tab, String value) {
    final controller = _searchControllers[tab]!;
    if (controller.text != value) controller.text = value;
    _searchDebouncer.cancel();
    setState(() => _LibraryMemory.queries[tab] = value);
  }

  Widget _buildSearchPill(LibraryTab tab, String hint) {
    final gutter = OmnisonicSpacing.gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, OmnisonicSpacing.xs, gutter, 0),
      child: SearchField(
        controller: _searchControllers[tab]!,
        hint: hint,
        onChanged: (value) => _searchDebouncer.run(() {
          if (!mounted) return;
          setState(() => _LibraryMemory.queries[tab] = value);
        }),
        onClear: () => _setQuery(tab, ''),
      ),
    );
  }

  /// "3 of 812 albums" while searching or filtering — it used to show the
  /// full total even when three albums were on screen.
  Widget _buildCountLine({
    required int shown,
    required int total,
    required int before,
    required String noun,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final String text;
    if (shown != total) {
      text = '$shown of ${pluralize(total, noun)}';
    } else if (before > total) {
      text = '${pluralize(total, noun)} · deduplicated from $before';
    } else {
      text = pluralize(total, noun);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OmnisonicSpacing.gutter(context),
        OmnisonicSpacing.ms,
        OmnisonicSpacing.gutter(context),
        0,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: OmnisonicTypography.technical.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Starred and genre filters as one compact row of chips.
  Widget _buildFilters(MusicLibraryViewModel viewModel) {
    final scheme = Theme.of(context).colorScheme;
    final genre = viewModel.selectedGenre;
    final filtered = viewModel.showStarredOnly || genre != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OmnisonicSpacing.gutter(context),
        OmnisonicSpacing.sm,
        OmnisonicSpacing.gutter(context),
        0,
      ),
      child: Wrap(
        spacing: OmnisonicSpacing.sm,
        runSpacing: OmnisonicSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilterChip(
            avatar: const Icon(
              OmnisonicIcons.star,
              size: OmnisonicIconSizes.sm,
            ),
            label: const Text('Starred'),
            selected: viewModel.showStarredOnly,
            onSelected: (_) => viewModel.toggleStarredFilter(),
          ),
          if (viewModel.genres.isNotEmpty)
            // A MenuAnchor rather than a PopupMenuButton: "All genres" has
            // no value, and PopupMenuButton treats a null selection as a
            // dismissal, so that item did nothing.
            MenuAnchor(
              reservedPadding: OmnisonicInsets.menuScreen,
              builder: (context, controller, child) => FilterChip(
                avatar: const Icon(
                  OmnisonicIcons.musicNote,
                  size: OmnisonicIconSizes.sm,
                ),
                label: Text(genre ?? 'All genres'),
                selected: genre != null,
                onSelected: (_) =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: genre == null
                      ? Icon(OmnisonicIcons.check, color: scheme.primary)
                      : const SizedBox(width: 24),
                  onPressed: () => viewModel.setGenreFilter(null),
                  child: const Text('All genres'),
                ),
                const Divider(height: 1),
                for (final g in viewModel.genres)
                  MenuItemButton(
                    leadingIcon: genre == g.name
                        ? Icon(OmnisonicIcons.check, color: scheme.primary)
                        : const SizedBox(width: 24),
                    trailingIcon: Text(
                      '${g.albumCount}',
                      style: OmnisonicTypography.metadata.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: () => viewModel.setGenreFilter(g.name),
                    child: Text(g.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          if (filtered)
            TextButton.icon(
              onPressed: viewModel.clearFilters,
              icon: const Icon(
                OmnisonicIcons.clear,
                size: OmnisonicIconSizes.sm,
              ),
              label: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }

  void _onAlbumTapped(Album album) =>
      context.push(AppRouter.albumDetailLocation(album.id), extra: album);

  void _onArtistTapped(Artist artist) =>
      context.push(AppRouter.artistDetailLocation(artist.id), extra: artist);

  Future<void> _syncLibrary() async {
    final viewModel = context.read<MusicLibraryViewModel>();
    viewModel.clearError();
    final success = await viewModel.syncCollection();
    if (!mounted) return;
    // A failure stays on screen as the banner or error view, with Retry,
    // rather than in a snackbar that is gone three seconds later.
    if (success) {
      showFeedback(context, 'Library synced', kind: FeedbackKind.success);
    }
  }

  void _showSortOptions(LibraryTab tab) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SortOptionsSheet(
        currentOption: _sortState.getOption(tab),
        fields: switch (tab) {
          LibraryTab.albums => SortField.values,
          LibraryTab.artists => const [SortField.title, SortField.dateAdded],
        },
        onOptionSelected: (option) =>
            setState(() => _sortState.setOption(tab, option)),
      ),
    );
  }
}
