import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../music/presentation/viewmodels/playlist_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/animation_utils.dart';

/// Library page displaying albums, artists, and tracks
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Data is already loaded via the ViewModel's initialization
    });
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
          tabs: const [
            Tab(text: 'Albums', icon: Icon(Icons.album)),
            Tab(text: 'Artists', icon: Icon(Icons.person)),
            Tab(text: 'Tracks', icon: Icon(Icons.music_note)),
            Tab(text: 'Playlists', icon: Icon(Icons.playlist_play)),
          ],
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
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
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

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: ResponsiveGridView(
            padding: const EdgeInsets.all(16),
            minItemWidth: 160,
            spacing: 16,
            children: albums.map((album) {
              return AlbumCard(
                album: album,
                onTap: () => _onAlbumTapped(album),
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

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: ResponsiveGridView(
            padding: const EdgeInsets.all(16),
            minItemWidth: 140,
            spacing: 16,
            children: artists.map((artist) {
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

        return RefreshIndicator(
          onRefresh: () => viewModel.syncCollection(),
          child: Column(
            children: [
              _buildTrackListHeader(tracks.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return TrackTile(
                      track: track,
                      showTrackNumber: false,
                      onTap: () => _onTrackTapped(track, tracks, index),
                      onMorePressed: () => _showTrackOptions(track),
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
                      '${playlists.length} playlist${playlists.length != 1 ? 's' : ''}',
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
                  children: playlists.map((playlist) {
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
    context.go('/album-detail', extra: album);
  }

  void _onArtistTapped(Artist artist) {
    // Navigate to artist detail page
    context.go('/artist-detail', extra: artist);
  }

  void _onTrackTapped(Track track, List<Track> playlist, int index) {
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(track, queue: playlist, startIndex: index);
  }

  void _onPlaylistTapped(Playlist playlist) {
    context.go('/playlist-detail?id=${playlist.id}');
  }

  void _showTrackOptions(Track track) {
    AnimationUtils.showCustomBottomSheet(
      context: context,
      builder: (context) => _buildTrackOptionsSheet(track),
    );
  }

  Widget _buildTrackOptionsSheet(Track track) {
    return Container(
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to queue')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement add to playlist
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add to playlist - Coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Track Info'),
            onTap: () {
              Navigator.pop(context);
              _showTrackInfo(track);
            },
          ),
        ],
      ),
    );
  }

  void _showTrackInfo(Track track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(track.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Artist', track.artist),
            _buildInfoRow('Album', track.album),
            _buildInfoRow('Duration', _formatDuration(track.duration)),
            if (track.year != null) _buildInfoRow('Year', track.year.toString()),
            if (track.genre != null) _buildInfoRow('Genre', track.genre!),
            _buildInfoRow('Quality', track.quality.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _syncLibrary() {
    context.read<MusicLibraryViewModel>().syncCollection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing library...')),
    );
  }

  void _showSortOptions() {
    AnimationUtils.showCustomBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alphabetical'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Recently Added'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Most Played'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
          ],
        ),
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