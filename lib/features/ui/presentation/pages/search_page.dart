import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/search_focus.dart';

import '../../../music/presentation/bloc/search_bloc.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/services/deduplication_engine.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../../core/utils/artist_grouping.dart';

typedef _MergedTrack = ({
  Track representative,
  List<String> serverIds,
  int rawCount,
});

/// Search page for finding music across all connected servers
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Sections the user expanded via "See All". Results are otherwise capped at
  /// a preview length per section.
  final Set<_ResultSection> _expandedSections = <_ResultSection>{};

  static const int _trackPreviewCount = 5;
  static const int _carouselPreviewCount = 10;

  /// Server to restrict results to, or null for "All servers".
  String? _selectedServerId;

  /// Memoized filter and merge results.
  ///
  /// Both merge passes are O(n log n) at best and sit inside the
  /// BlocBuilder's builder, so without this they re-run on every rebuild —
  /// every chip tap, every section toggle, every keystroke's rebuild.
  ///
  /// The filter is memoized as well, and that part matters more than it
  /// looks: `where().toList()` allocates a fresh list each build, so a
  /// memo keyed on the merge input's identity would miss every single time
  /// a server filter was active. It only ever hit in the unfiltered case,
  /// where the input list is passed straight through.
  List<Track>? _filterTracksSource;
  String? _filterTracksServerId;
  List<Track>? _filterTracksCache;
  List<Album>? _filterAlbumsSource;
  String? _filterAlbumsServerId;
  List<Album>? _filterAlbumsCache;
  List<Artist>? _filterArtistsSource;
  String? _filterArtistsServerId;
  List<Artist>? _filterArtistsCache;

  List<Track>? _mergedTracksSource;
  ({List<_MergedTrack> items, int rawTotal})? _mergedTracksCache;
  List<Album>? _mergedAlbumsSource;
  AlbumDedupeResult? _mergedAlbumsCache;

  bool _isExpanded(_ResultSection section) =>
      _expandedSections.contains(section);

  void _toggleSection(_ResultSection section) {
    setState(() {
      if (!_expandedSections.remove(section)) {
        _expandedSections.add(section);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // The bloc outlives this page; leaving and coming back used to show its
    // results under an empty field.
    final query = context.read<SearchBloc>().state.query;
    if (query.isNotEmpty) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    _searchController.addListener(_onSearchChanged);
    SearchFocusRequest.requests.addListener(_focusField);
    if (SearchFocusRequest.takePending()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusField());
    }
  }

  void _focusField() {
    if (!mounted) return;
    SearchFocusRequest.takePending();
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  /// Records the current query in the recent searches. Called on submit and
  /// when a result is opened — the list used to fill only from taps on
  /// itself, so on a fresh install it never appeared.
  void _rememberQuery() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<SearchBloc>().add(SearchHistoryAdded(query));
    }
  }

  @override
  void dispose() {
    SearchFocusRequest.requests.removeListener(_focusField);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // A new query means new sections; keep them collapsed to their preview.
    if (_expandedSections.isNotEmpty) {
      setState(_expandedSections.clear);
    }
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    } else {
      context.read<SearchBloc>().add(const SearchCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    // The server list is read here rather than inside the header delegate:
    // a delegate is not a widget and cannot subscribe to a provider, so
    // watching it there would silently never rebuild when a server connects.
    final servers = context.watch<ServerManagementViewModel>().servers;
    final chipsVisible = servers.length >= 2;

    // The header's extent has to be declared up front, so it is computed
    // against the user's text size rather than assumed at 1x.
    final barExtent = OmnisonicTextScale.textExtent(context, _searchBarExtent);
    final chipExtent = OmnisonicTextScale.textExtent(context, _chipRowExtent);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Same title treatment as PageHeaderAppBar on the other tabs; it
          // was the one centred, regular-weight title.
          SliverAppBar(
            centerTitle: false,
            titleSpacing: OmnisonicSpacing.gutter(context),
            title: Semantics(
              header: true,
              child: Text(
                'Search',
                style:
                    (MediaQuery.sizeOf(context).width <
                                ResponsiveBreakpoints.mobile
                            ? OmnisonicTypography.sectionTitle
                            : OmnisonicTypography.pageTitle)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
              ),
            ),
            pinned: true,
            elevation: 0,
            foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
          ),
          // Pinned and non-collapsing: the field is the page's entire
          // purpose, so it must not scroll away with the results.
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              extent: barExtent + (chipsVisible ? chipExtent : 0),
              searchBar: SizedBox(
                height: barExtent,
                child: _buildSearchBar(context),
              ),
              chips: chipsVisible
                  ? SizedBox(
                      height: chipExtent,
                      child: _buildServerFilterChips(servers),
                    )
                  : null,
              selectedServerId: _selectedServerId,
              serverIds: [for (final server in servers) server.id],
            ),
          ),
          BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) =>
                SliverMainAxisGroup(slivers: _buildSearchResults(state)),
          ),
        ],
      ),
    );
  }

  /// Height of the pinned header's two rows.
  ///
  /// A [SliverPersistentHeaderDelegate] has to declare its extent up front —
  /// it cannot measure its child — so these are authoritative rather than
  /// descriptive: both builders below lay out inside a SizedBox of exactly
  /// this height.
  static const double _searchBarExtent = 76;
  static const double _chipRowExtent = 48;

  Widget _buildSearchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmnisonicSpacing.md,
        OmnisonicSpacing.md,
        OmnisonicSpacing.md,
        OmnisonicSpacing.sm,
      ),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: OmnisonicTypography.bodyMedium.copyWith(
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search across all servers…',
            // Dense, so the field's height is predictable and matches the
            // extent the pinned header declares.
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: OmnisonicSpacing.sm,
            ),
            prefixIcon: const Icon(OmnisonicIcons.search),
            // Driven by the controller rather than by the page's build cycle:
            // typing does not call setState, so a plain read of `.text` here
            // would leave the clear button stale.
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(OmnisonicIcons.clear),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                );
              },
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              context.read<SearchBloc>().add(SearchQueryChanged(query.trim()));
              _rememberQuery();
            }
          },
        ),
      ),
    );
  }

  /// "All servers" + one chip per connected server, each tinted with
  /// [OmnisonicColors.serverColorFor] so the filter reads consistently with
  /// the source dots shown on the result rows below.
  Widget _buildServerFilterChips(List<MusicServer> servers) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        OmnisonicSpacing.md,
        0,
        OmnisonicSpacing.md,
        OmnisonicSpacing.sm,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: OmnisonicSpacing.sm),
          child: ChoiceChip(
            label: const Text('All servers'),
            selected: _selectedServerId == null,
            onSelected: (_) => setState(() => _selectedServerId = null),
          ),
        ),
        for (final server in servers)
          Padding(
            padding: const EdgeInsets.only(right: OmnisonicSpacing.sm),
            child: ChoiceChip(
              avatar: ExcludeSemantics(
                child: ServerDot(serverId: server.id, size: 10),
              ),
              label: Text(server.name),
              selected: _selectedServerId == server.id,
              onSelected: (_) => setState(() => _selectedServerId = server.id),
            ),
          ),
      ],
    );
  }

  List<Track> _filterByServer(List<Track> tracks) {
    if (_selectedServerId == null) return tracks;
    if (identical(_filterTracksSource, tracks) &&
        _filterTracksServerId == _selectedServerId &&
        _filterTracksCache != null) {
      return _filterTracksCache!;
    }
    final filtered = tracks
        .where((t) => t.serverId == _selectedServerId)
        .toList();
    _filterTracksSource = tracks;
    _filterTracksServerId = _selectedServerId;
    _filterTracksCache = filtered;
    return filtered;
  }

  List<Album> _filterAlbumsByServer(List<Album> albums) {
    if (_selectedServerId == null) return albums;
    if (identical(_filterAlbumsSource, albums) &&
        _filterAlbumsServerId == _selectedServerId &&
        _filterAlbumsCache != null) {
      return _filterAlbumsCache!;
    }
    final filtered = albums
        .where((a) => a.serverId == _selectedServerId)
        .toList();
    _filterAlbumsSource = albums;
    _filterAlbumsServerId = _selectedServerId;
    _filterAlbumsCache = filtered;
    return filtered;
  }

  List<Artist> _filterArtistsByServer(List<Artist> artists) {
    if (_selectedServerId == null) return artists;
    if (identical(_filterArtistsSource, artists) &&
        _filterArtistsServerId == _selectedServerId &&
        _filterArtistsCache != null) {
      return _filterArtistsCache!;
    }
    final filtered = artists
        .where((a) => a.serverId == _selectedServerId)
        .toList();
    _filterArtistsSource = artists;
    _filterArtistsServerId = _selectedServerId;
    _filterArtistsCache = filtered;
    return filtered;
  }

  /// Merges same-track-on-multiple-servers duplicates in [tracks] into a
  /// single row per distinct track, using the same [DeduplicationEngine]
  /// the rest of the app uses for library-wide dedup. Preserves the
  /// server's original ranking by keeping each group at its first
  /// occurrence's position.
  ({List<_MergedTrack> items, int rawTotal}) _mergeTracks(List<Track> tracks) {
    if (identical(_mergedTracksSource, tracks) && _mergedTracksCache != null) {
      return _mergedTracksCache!;
    }
    final merged = _computeMergedTracks(tracks);
    _mergedTracksSource = tracks;
    _mergedTracksCache = merged;
    return merged;
  }

  AlbumDedupeResult _mergeAlbums(List<Album> albums) {
    if (identical(_mergedAlbumsSource, albums) && _mergedAlbumsCache != null) {
      return _mergedAlbumsCache!;
    }
    final merged = dedupeAlbumsByServer(albums);
    _mergedAlbumsSource = albums;
    _mergedAlbumsCache = merged;
    return merged;
  }

  ({List<_MergedTrack> items, int rawTotal}) _computeMergedTracks(
    List<Track> tracks,
  ) {
    if (tracks.isEmpty) return (items: const [], rawTotal: 0);

    final engine = getIt<DeduplicationEngine>();
    final groups = engine.detectDuplicates(tracks).values;
    final groupByTrackId = <String, List<Track>>{};
    for (final group in groups) {
      for (final track in group) {
        groupByTrackId[track.id] = group;
      }
    }

    final items = <_MergedTrack>[];
    final emitted = <String>{};
    for (final track in tracks) {
      if (emitted.contains(track.id)) continue;
      final group = groupByTrackId[track.id];
      if (group != null) {
        final representative = engine.selectRepresentativeTrack(group);
        items.add((
          representative: representative,
          serverIds: group.map((t) => t.serverId).toList(),
          rawCount: group.length,
        ));
        emitted.addAll(group.map((t) => t.id));
      } else {
        items.add((
          representative: track,
          serverIds: [track.serverId],
          rawCount: 1,
        ));
        emitted.add(track.id);
      }
    }
    return (items: items, rawTotal: tracks.length);
  }

  /// "N merged from M results" when duplicates were actually collapsed,
  /// otherwise a plain count — never a hardcoded string.
  String _resultCountLabel(int mergedCount, int rawTotal, String noun) {
    final word = mergedCount == 1 ? noun : '${noun}s';
    if (rawTotal > mergedCount) {
      return '$mergedCount $word · merged from $rawTotal';
    }
    return '$mergedCount $word';
  }

  List<Widget> _buildSearchResults(SearchState state) {
    if (state.isLoading) {
      return [LoadingStateView.sliver(kind: SkeletonKind.list, itemCount: 5)];
    }
    if (state.isSuccess) {
      return _buildSearchResultsList(state);
    }
    if (state.isFailure) {
      return [
        ErrorStateView.sliver(
          title: 'Search error',
          message: state.errorMessage ?? 'Unknown error',
          onRetry: () {
            final query = _searchController.text.trim();
            if (query.isNotEmpty) {
              context.read<SearchBloc>().add(SearchQueryChanged(query));
            }
          },
        ),
      ];
    }
    return _buildSearchSuggestions(state);
  }

  /// The idle state used to be six hardcoded genre chips and four static
  /// "search tips" — eighty lines of content about nothing in the user's
  /// library. Meanwhile SearchBloc has carried a working searchHistory, plus
  /// SearchHistoryAdded/Cleared/SuggestionSelected events, that no widget
  /// ever dispatched.
  List<Widget> _buildSearchSuggestions(SearchState state) {
    final history = state.searchHistory;

    if (history.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: OmnisonicIcons.searchOutline,
            title: 'Search your music',
            subtitle:
                'Find tracks, albums and artists across every connected '
                'server. Duplicates are merged automatically.',
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: 'Recent searches',
          seeAllLabel: 'Clear',
          onSeeAllPressed: () =>
              context.read<SearchBloc>().add(const SearchHistoryCleared()),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: OmnisonicSpacing.sm,
            runSpacing: OmnisonicSpacing.sm,
            children: [
              for (final query in history)
                ActionChip(
                  avatar: const Icon(
                    OmnisonicIcons.history,
                    size: OmnisonicIconSizes.sm,
                  ),
                  label: Text(query),
                  onPressed: () => _runSearch(query),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Runs [query] and records it, which is what promotes it into the recent
  /// list the idle state renders.
  void _runSearch(String query) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    context.read<SearchBloc>().add(SearchHistoryAdded(query));
  }

  List<Widget> _buildSearchResultsList(SearchState state) {
    final tracks = _filterByServer(state.tracks);
    final albums = _filterAlbumsByServer(state.albums);
    // One row per artist name: each server returns its own copy.
    final artists = dedupeArtists(
      _filterArtistsByServer(state.artists),
      const [],
    ).artists;

    final hasResults =
        tracks.isNotEmpty || albums.isNotEmpty || artists.isNotEmpty;

    if (!hasResults) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: OmnisonicIcons.searchOff,
            title: 'No results found',
            subtitle: _selectedServerId != null
                ? 'Nothing on this server. Try "All servers" or different '
                      'keywords.'
                : 'Try different keywords or check your spelling.',
            action: TextButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.requestFocus();
              },
              child: const Text('Start over'),
            ),
          ),
        ),
      ];
    }

    // Both passes are memoized on the identity of the list they came from,
    // so a chip tap or a section toggle re-renders without re-running the
    // dedup engine.
    final mergedTracks = _mergeTracks(tracks);
    final mergedAlbums = _mergeAlbums(albums);

    return [
      if (mergedTracks.items.isNotEmpty)
        ..._buildTracksSection(mergedTracks.items, mergedTracks.rawTotal),
      if (mergedAlbums.albums.isNotEmpty)
        _buildAlbumsSection(
          mergedAlbums.albums,
          mergedAlbums.sourceServerIds,
          albums.length,
        ),
      if (artists.isNotEmpty) _buildArtistsSection(artists),
      const SliverToBoxAdapter(child: SizedBox(height: OmnisonicSpacing.xl)),
    ];
  }

  /// The track list is the one place on this page with unbounded length, and
  /// it used to be a shrinkWrap ListView with NeverScrollableScrollPhysics
  /// inside a SingleChildScrollView — which builds and lays out every row
  /// whether or not it is on screen, and turned "See All" on a large result
  /// set into a full re-layout of the page.
  ///
  /// As a SliverList the rows are built on demand and expanding is just a
  /// larger itemCount.
  List<Widget> _buildTracksSection(List<_MergedTrack> items, int rawTotal) {
    final expanded = _isExpanded(_ResultSection.tracks);
    final visibleCount = expanded
        ? items.length
        : items.length.clamp(0, _trackPreviewCount);
    final tracks = items.map((i) => i.representative).toList();

    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: 'Tracks',
          subtitle: _resultCountLabel(items.length, rawTotal, 'result'),
          seeAllLabel: expanded ? 'Show less' : 'See all',
          onSeeAllPressed: items.length > _trackPreviewCount
              ? () => _toggleSection(_ResultSection.tracks)
              : null,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
        sliver: SliverList.builder(
          itemCount: visibleCount,
          itemBuilder: (context, index) {
            final item = items[index];
            final track = item.representative;
            return TrackRow(
              key: ValueKey(track.id),
              track: track,
              serverId: track.serverId,
              sourceServerIds: item.serverIds,
              qualityLabel: track.quality.format,
              onTap: () => _onTrackTapped(track, tracks, index),
              onShowActions: () => _showTrackOptions(tracks, index),
            );
          },
        ),
      ),
    ];
  }

  /// A horizontal carousel cannot itself be a sliver inside a vertical
  /// viewport, so this stays a box widget in an adapter. It was never the
  /// perf problem: it is capped to a preview length and already lazy along
  /// its own axis.
  Widget _buildAlbumsSection(
    List<Album> albums,
    Map<String, List<String>> sourceServerIds,
    int rawTotal,
  ) {
    final expanded = _isExpanded(_ResultSection.albums);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Albums',
            subtitle: _resultCountLabel(albums.length, rawTotal, 'result'),
            seeAllLabel: expanded ? 'Show less' : 'See all',
            onSeeAllPressed: albums.length > _carouselPreviewCount
                ? () => _toggleSection(_ResultSection.albums)
                : null,
          ),
          SizedBox(
            // 160 of square artwork plus the title/subtitle block. Only the
            // text half grows with the user's text size — scaling the whole
            // height would enlarge the artwork too and push the row off
            // screen.
            height: AlbumCard.extentFor(context, 160),
            child: ScrollConfiguration(
              behavior: const CarouselScrollBehavior(),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: OmnisonicSpacing.md,
                ),
                itemCount: expanded
                    ? albums.length
                    : albums.length.clamp(0, _carouselPreviewCount),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  final sources = sourceServerIds[album.id] ?? const [];
                  return Padding(
                    key: ValueKey(album.id),
                    padding: const EdgeInsets.only(right: OmnisonicSpacing.sm),
                    child: AlbumCard(
                      album: album,
                      width: 160,
                      onTap: () => _onAlbumTapped(album),
                      sourceServerIds: sources.length > 1 ? sources : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsSection(List<Artist> artists) {
    final expanded = _isExpanded(_ResultSection.artists);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Artists',
            subtitle:
                '${artists.length} result${artists.length != 1 ? 's' : ''}',
            seeAllLabel: expanded ? 'Show less' : 'See all',
            onSeeAllPressed: artists.length > _carouselPreviewCount
                ? () => _toggleSection(_ResultSection.artists)
                : null,
          ),
          SizedBox(
            height: MediaCard.extentFor(
              context,
              140,
              subtitle: false,
              meta: true,
            ),
            child: ScrollConfiguration(
              behavior: const CarouselScrollBehavior(),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: OmnisonicSpacing.md,
                ),
                itemCount: expanded
                    ? artists.length
                    : artists.length.clamp(0, _carouselPreviewCount),
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return Padding(
                    key: ValueKey(artist.id),
                    padding: const EdgeInsets.only(right: OmnisonicSpacing.sm),
                    child: ArtistCard(
                      artist: artist,
                      width: 140,
                      onTap: () => _onArtistTapped(artist),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTrackTapped(Track track, List<Track> playlist, int index) {
    _rememberQuery();
    context.read<PlaybackViewModel>().playTrack(
      track,
      queue: playlist,
      startIndex: index,
    );
  }

  void _onAlbumTapped(Album album) {
    _rememberQuery();
    // Navigate to album detail page
    context.push(AppRouter.albumDetailLocation(album.id), extra: album);
  }

  void _onArtistTapped(Artist artist) {
    _rememberQuery();
    // Navigate to artist detail page
    context.push(AppRouter.artistDetailLocation(artist.id), extra: artist);
  }

  void _showTrackOptions(List<Track> tracks, int index) => showTrackActions(
    context,
    tracks[index],
    onPlay: () => _onTrackTapped(tracks[index], tracks, index),
  );
}

/// Result sections that can be expanded past their preview length.
enum _ResultSection { tracks, albums, artists }

/// Holds the search field, and the server chips when there is more than one
/// server, pinned above the results.
///
/// [minExtent] equals [maxExtent] on purpose: this header does not collapse.
/// A field that scrolls away is the one thing a search page cannot do.
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SearchHeaderDelegate({
    required this.extent,
    required this.searchBar,
    required this.chips,
    required this.selectedServerId,
    required this.serverIds,
  });

  final double extent;
  final Widget searchBar;
  final Widget? chips;

  /// Only used by [shouldRebuild]. The delegate cannot watch a provider, so
  /// the state it depends on has to be handed to it and compared here.
  final String? selectedServerId;
  final List<String> serverIds;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Same rule as the shell's AppBar theme: transparent at rest, a surface
    // once results scroll under the field.
    final scrolled = overlapsContent || shrinkOffset > 0;
    return Material(
      color: scrolled
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.94)
          : Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [searchBar, ?chips],
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent ||
      oldDelegate.selectedServerId != selectedServerId ||
      !listEquals(oldDelegate.serverIds, serverIds);
}
