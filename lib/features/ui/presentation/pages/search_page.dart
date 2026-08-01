import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/bloc/search_bloc.dart';
import '../../../music/presentation/viewmodels/playlist_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/animation_utils.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search tracks, albums, artists...',
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.read<SearchBloc>().add(SearchQueryChanged(query.trim()));
          }
        },
      ),
    );
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
    final hasResults = state.hasTracks || state.hasAlbums || state.hasArtists;

    if (!hasResults) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        subtitle: 'Try different keywords or check your spelling',
        action: TextButton(
          onPressed: () {
            _searchController.clear();
            _searchFocusNode.requestFocus();
          },
          child: const Text('Try Again'),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.hasTracks) _buildTracksSection(state.tracks),
          if (state.hasAlbums) _buildAlbumsSection(state.albums),
          if (state.hasArtists) _buildArtistsSection(state.artists),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTracksSection(List<Track> tracks) {
    final expanded = _isExpanded(_ResultSection.tracks);
    final visibleCount = expanded
        ? tracks.length
        : tracks.length.clamp(0, _trackPreviewCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tracks',
          subtitle: '${tracks.length} result${tracks.length != 1 ? 's' : ''}',
          seeAllLabel: expanded ? 'Show Less' : 'See All',
          onSeeAllPressed: tracks.length > _trackPreviewCount
              ? () => _toggleSection(_ResultSection.tracks)
              : null,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: visibleCount,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return TrackTile(
              track: track,
              onTap: () => _onTrackTapped(track, tracks, index),
              onMorePressed: () => _showTrackOptions(track),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumsSection(List<Album> albums) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Albums',
          subtitle: '${albums.length} result${albums.length != 1 ? 's' : ''}',
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
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AlbumCard(
                  album: album,
                  width: 160,
                  onTap: () => _onAlbumTapped(album),
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
    context.push('/album-detail', extra: album);
  }

  void _onArtistTapped(Artist artist) {
    // Navigate to artist detail page
    context.push('/artist-detail', extra: artist);
  }

  void _showTrackOptions(Track track) {
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
                _onTrackTapped(track, [track], 0);
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
            if (context.read<PlaylistViewModel>().playlists.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylist(track);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Playlist picker for "Add to Playlist". Shown only when at least one
  /// playlist exists, so the entry point is never a dead end.
  Future<void> _showAddToPlaylist(Track track) async {
    final playlistViewModel = context.read<PlaylistViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final playlists = playlistViewModel.playlists;

    final playlistId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: SectionHeader(
                title: 'Add to Playlist',
                padding: EdgeInsets.zero,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    leading: const Icon(Icons.playlist_play),
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.trackCount} tracks'),
                    onTap: () => Navigator.pop(sheetContext, playlist.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (playlistId == null) return;

    final added = await playlistViewModel.addTrackToPlaylist(
      playlistId,
      track.id,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Added to playlist' : 'Could not add track to playlist',
        ),
      ),
    );
  }
}

/// Result sections that can be expanded past their preview length.
enum _ResultSection { tracks, albums, artists }
