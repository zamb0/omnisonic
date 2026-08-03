import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../music/presentation/bloc/search_bloc.dart';
import '../../../music/presentation/widgets/add_to_playlist_sheet.dart';
import '../../../offline/presentation/viewmodels/offline_mode_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/services/deduplication_engine.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../../core/utils/animation_utils.dart';

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

  /// Memoized merge/dedupe results, keyed by the identity of the result list
  /// they were computed from. Both passes are O(n log n) at best and used to
  /// re-run on every chip tap and section toggle, because they sit inside the
  /// BlocBuilder's builder.
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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildServerFilterChips(context),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                return _buildSearchResults(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            prefixIcon: const Icon(Icons.search),
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
                  icon: const Icon(Icons.clear),
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
            }
          },
        ),
      ),
    );
  }

  /// "All servers" + one chip per connected server, each tinted with
  /// [OmnisonicColors.serverColorFor] so the filter reads consistently with
  /// the source dots shown on the result rows below.
  Widget _buildServerFilterChips(BuildContext context) {
    final serverViewModel = context.watch<ServerManagementViewModel>();
    final servers = serverViewModel.servers;
    if (servers.length < 2) {
      // A single-server library has nothing to filter by.
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All servers'),
              selected: _selectedServerId == null,
              onSelected: (_) => setState(() => _selectedServerId = null),
            ),
          ),
          for (final server in servers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OmnisonicColors.serverColorFor(server.id),
                  ),
                ),
                label: Text(server.name),
                selected: _selectedServerId == server.id,
                onSelected: (_) =>
                    setState(() => _selectedServerId = server.id),
              ),
            ),
        ],
      ),
    );
  }

  List<Track> _filterByServer(List<Track> tracks) {
    if (_selectedServerId == null) return tracks;
    return tracks.where((t) => t.serverId == _selectedServerId).toList();
  }

  List<Album> _filterAlbumsByServer(List<Album> albums) {
    if (_selectedServerId == null) return albums;
    return albums.where((a) => a.serverId == _selectedServerId).toList();
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
      return '$mergedCount $word merged from $rawTotal results';
    }
    return '$mergedCount $word';
  }

  Widget _buildSearchResults(SearchState state) {
    if (state.isInitial) {
      return _buildSearchSuggestions();
    } else if (state.isLoading) {
      return const LoadingIndicator(message: 'Searching...');
    } else if (state.isSuccess) {
      return _buildSearchResultsList(state);
    } else if (state.isFailure) {
      return _buildErrorState(state.errorMessage ?? 'Unknown error');
    }

    return _buildSearchSuggestions();
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Search Your Music',
            subtitle: 'Find tracks, albums, and artists across all servers',
          ),
          const SizedBox(height: 24),
          _buildQuickSearchSection(context),
          const SizedBox(height: 24),
          _buildSearchTipsSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickSearchSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Search',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickSearchChip('Rock', Icons.music_note),
            _buildQuickSearchChip('Jazz', Icons.music_note),
            _buildQuickSearchChip('Classical', Icons.music_note),
            _buildQuickSearchChip('Electronic', Icons.music_note),
            _buildQuickSearchChip('Pop', Icons.music_note),
            _buildQuickSearchChip('Hip Hop', Icons.music_note),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSearchChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _onSearchChanged();
      },
    );
  }

  Widget _buildSearchTipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Tips',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildTipItem(context, 'Search by track name, artist, or album'),
        _buildTipItem(context, 'Use quotes for exact matches: "Dark Side"'),
        _buildTipItem(
          context,
          'Search across all connected servers simultaneously',
        ),
        _buildTipItem(context, 'Results are deduplicated automatically'),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(SearchState state) {
    final tracks = _filterByServer(state.tracks);
    final albums = _filterAlbumsByServer(state.albums);
    final artists = _selectedServerId == null
        ? state.artists
        : state.artists.where((a) => a.serverId == _selectedServerId).toList();

    final hasResults =
        tracks.isNotEmpty || albums.isNotEmpty || artists.isNotEmpty;

    if (!hasResults) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        subtitle: _selectedServerId != null
            ? 'No results on this server. Try "All servers" or different keywords.'
            : 'Try different keywords or check your spelling',
        action: TextButton(
          onPressed: () {
            _searchController.clear();
            _searchFocusNode.requestFocus();
          },
          child: const Text('Try Again'),
        ),
      );
    }

    final mergedTracks = _mergeTracks(tracks);
    final mergedAlbums = _mergeAlbums(albums);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mergedTracks.items.isNotEmpty)
            _buildTracksSection(mergedTracks.items, mergedTracks.rawTotal),
          if (mergedAlbums.albums.isNotEmpty)
            _buildAlbumsSection(
              mergedAlbums.albums,
              mergedAlbums.sourceServerIds,
              albums.length,
            ),
          if (artists.isNotEmpty) _buildArtistsSection(artists),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTracksSection(List<_MergedTrack> items, int rawTotal) {
    final expanded = _isExpanded(_ResultSection.tracks);
    final visibleCount = expanded
        ? items.length
        : items.length.clamp(0, _trackPreviewCount);
    final tracks = items.map((i) => i.representative).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tracks',
          subtitle: _resultCountLabel(items.length, rawTotal, 'result'),
          seeAllLabel: expanded ? 'Show Less' : 'See All',
          onSeeAllPressed: items.length > _trackPreviewCount
              ? () => _toggleSection(_ResultSection.tracks)
              : null,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: visibleCount,
          itemBuilder: (context, index) {
            final item = items[index];
            final track = item.representative;
            return TrackTile(
              track: track,
              serverId: track.serverId,
              sourceServerIds: item.serverIds,
              qualityLabel: track.quality.format,
              onTap: () => _onTrackTapped(track, tracks, index),
              onMorePressed: () => _showTrackOptions(tracks, index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumsSection(
    List<Album> albums,
    Map<String, List<String>> sourceServerIds,
    int rawTotal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Albums',
          subtitle: _resultCountLabel(albums.length, rawTotal, 'result'),
          seeAllLabel: _isExpanded(_ResultSection.albums)
              ? 'Show Less'
              : 'See All',
          onSeeAllPressed: albums.length > _carouselPreviewCount
              ? () => _toggleSection(_ResultSection.albums)
              : null,
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _isExpanded(_ResultSection.albums)
                ? albums.length
                : albums.length.clamp(0, _carouselPreviewCount),
            itemBuilder: (context, index) {
              final album = albums[index];
              final sources = sourceServerIds[album.id] ?? const [];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    AlbumCard(
                      album: album,
                      width: 160,
                      onTap: () => _onAlbumTapped(album),
                    ),
                    if (sources.length > 1)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: ServerDotStack(serverIds: sources),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsSection(List<Artist> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Artists',
          subtitle: '${artists.length} result${artists.length != 1 ? 's' : ''}',
          seeAllLabel: _isExpanded(_ResultSection.artists)
              ? 'Show Less'
              : 'See All',
          onSeeAllPressed: artists.length > _carouselPreviewCount
              ? () => _toggleSection(_ResultSection.artists)
              : null,
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _isExpanded(_ResultSection.artists)
                ? artists.length
                : artists.length.clamp(0, _carouselPreviewCount),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ArtistCard(
                  artist: artist,
                  width: 140,
                  onTap: () => _onArtistTapped(artist),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Search Error',
      subtitle: message,
      action: ElevatedButton(
        onPressed: () {
          if (_searchController.text.trim().isNotEmpty) {
            context.read<SearchBloc>().add(
              SearchQueryChanged(_searchController.text.trim()),
            );
          }
        },
        child: const Text('Retry'),
      ),
    );
  }

  void _onTrackTapped(Track track, List<Track> playlist, int index) {
    context.read<PlaybackViewModel>().playTrack(
      track,
      queue: playlist,
      startIndex: index,
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

  void _showTrackOptions(List<Track> tracks, int index) {
    final track = tracks[index];
    AnimationUtils.showCustomBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play Now'),
              onTap: () {
                Navigator.pop(context);
                _onTrackTapped(track, tracks, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(context);
                context.read<PlaybackViewModel>().addToQueue(track);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Added to queue')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                showAddToPlaylistSheet(context, track);
              },
            ),
            _DownloadTrackTile(track: track),
          ],
        ),
      ),
    );
  }
}

/// "Download" row for the track options sheet: downloads the track for
/// offline playback, or removes it again when it is already downloaded.
class _DownloadTrackTile extends StatelessWidget {
  const _DownloadTrackTile({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineModeViewModel>();
    final isDownloaded = offline.isTrackAvailableOffline(track.id);
    final isDownloading = offline.isTrackDownloading(track.id);

    return ListTile(
      leading: Icon(
        isDownloaded
            ? Icons.download_done
            : isDownloading
            ? Icons.downloading
            : Icons.download_outlined,
      ),
      title: Text(
        isDownloaded
            ? 'Remove Download'
            : isDownloading
            ? 'Downloading…'
            : 'Download',
      ),
      enabled: !isDownloading,
      onTap: () async {
        Navigator.pop(context);
        final messenger = ScaffoldMessenger.of(context);
        final error = isDownloaded
            ? await offline.removeDownload(track.id)
            : await offline.downloadTrack(track);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error ??
                  (isDownloaded
                      ? 'Download removed'
                      : 'Downloaded for offline'),
            ),
          ),
        );
      },
    );
  }
}

/// Result sections that can be expanded past their preview length.
enum _ResultSection { tracks, albums, artists }
