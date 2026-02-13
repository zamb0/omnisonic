import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../music/presentation/viewmodels/playlist_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../models/library_tab.dart';
import '../models/library_sort_state.dart';
import '../models/sort_option.dart';
import '../services/library_sort_service.dart';
import '../services/track_actions.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/animation_utils.dart';

/// Library page displaying albums, artists, tracks, and playlists
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LibrarySortState _sortState;
  late TrackActions _trackActions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: LibraryTab.count, vsync: this);
    _sortState = LibrarySortState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trackActions = TrackActions(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: LibraryTab.values
              .map((tab) => Tab(text: tab.label, icon: Icon(tab.icon)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlbumsTab(),
          _buildArtistsTab(),
          _buildTracksTab(),
          _buildPlaylistsTab(),
        ],
      ),
    );
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

        final sortOption = _sortState.getOption(LibraryTab.albums);
        final sortedAlbums = LibrarySortService.sortAlbums(albums, sortOption);
        
        // Create a map of server IDs to server names for quick lookup
        final serverMap = {for (var server in serverViewModel.servers) server.id: server.name};

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: ResponsiveGridView(
            padding: const EdgeInsets.all(16),
            minItemWidth: 160,
            spacing: 16,
            children: sortedAlbums.map((album) {
              return AlbumCard(
                album: album,
                onTap: () => _onAlbumTapped(album),
                serverName: serverMap[album.serverId],
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
            padding: const EdgeInsets.all(16),
            minItemWidth: 140,
            spacing: 16,
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

  Widget _buildTracksTab() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingList();
        }

        final tracks = viewModel.tracks;
        if (tracks.isEmpty) {
          return EmptyState(
            icon: Icons.music_note,
            title: 'No Tracks',
            subtitle: 'Connect to servers and sync your library to see tracks here',
            action: ElevatedButton(
              onPressed: _syncLibrary,
              child: const Text('Sync Library'),
            ),
          );
        }

        final sortOption = _sortState.getOption(LibraryTab.tracks);
        final sortedTracks = LibrarySortService.sortTracks(tracks, sortOption);

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: Column(
            children: [
              _buildTrackListHeader(sortedTracks.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedTracks.length,
                  itemBuilder: (context, index) {
                    final track = sortedTracks[index];
                    return TrackTile(
                      track: track,
                      showTrackNumber: false,
                      onTap: () => _onTrackTapped(track, sortedTracks, index),
                      onMorePressed: () => _trackActions.showOptions(
                        track,
                        onPlayNow: () => _onTrackTapped(track, sortedTracks, index),
                      ),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.playlist_play, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${sortedPlaylists.length} playlist${sortedPlaylists.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minItemWidth: 160,
                  spacing: 16,
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

  Widget _buildTrackListHeader(int trackCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.music_note, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$trackCount track${trackCount != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: trackCount > 0 ? _shuffleAllTracks : null,
            tooltip: 'Shuffle All',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: trackCount > 0 ? _playAllTracks : null,
            tooltip: 'Play All',
          ),
        ],
      ),
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

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        );
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

  void _onTrackTapped(Track track, List<Track> playlist, int index) {
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(track, queue: playlist, startIndex: index);
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
    final currentTab = LibraryTab.fromIndex(_tabController.index);
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

  void _shuffleAllTracks() {
    final tracks = context.read<MusicLibraryViewModel>().tracks;
    if (tracks.isNotEmpty) {
      final shuffledTracks = List<Track>.from(tracks)..shuffle();
      context.read<PlaybackViewModel>().playTrack(shuffledTracks.first, queue: shuffledTracks);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shuffling all tracks')),
      );
    }
  }

  void _playAllTracks() {
    final tracks = context.read<MusicLibraryViewModel>().tracks;
    if (tracks.isNotEmpty) {
      context.read<PlaybackViewModel>().playTrack(tracks.first, queue: tracks, startIndex: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playing all tracks')),
      );
    }
  }
}