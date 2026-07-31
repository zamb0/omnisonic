import 'package:flutter/material.dart';

import '../entities/album.dart';
import '../entities/artist.dart';
import '../entities/track.dart';
import '../entities/audio_quality.dart';
import 'enhanced_cards.dart';
import 'enhanced_lists.dart';
import 'theme.dart';
import 'spacing.dart';

/// Example page demonstrating the enhanced UI components
/// Shows how to use EnhancedAlbumCard, EnhancedArtistCard, EnhancedTrackCard,
/// and EnhancedAnimatedList together in a real music app interface
class EnhancedComponentsExample extends StatefulWidget {
  const EnhancedComponentsExample({super.key});

  @override
  State<EnhancedComponentsExample> createState() =>
      _EnhancedComponentsExampleState();
}

class _EnhancedComponentsExampleState extends State<EnhancedComponentsExample>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Track> _tracks = [];
  String? _playingTrackId;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateSampleData() {
    // Generate sample albums
    _albums = List.generate(
      20,
      (index) => Album(
        id: 'album_$index',
        title: 'Album ${index + 1}',
        artist: 'Artist ${(index % 5) + 1}',
        serverId: 'server_1',
        lastModified: DateTime.now(),
        year: 2020 + (index % 4),
        trackCount: 10 + (index % 5),
        coverArtUrl: index % 3 == 0
            ? 'https://picsum.photos/300/300?random=$index'
            : null,
      ),
    );

    // Generate sample artists
    _artists = List.generate(
      10,
      (index) => Artist(
        id: 'artist_$index',
        name: 'Artist ${index + 1}',
        serverId: 'server_1',
        lastModified: DateTime.now(),
        albumCount: 2 + (index % 3),
        imageUrl: index % 2 == 0
            ? 'https://picsum.photos/200/200?random=${index + 100}'
            : null,
      ),
    );

    // Generate sample tracks
    _tracks = List.generate(
      50,
      (index) => Track(
        id: 'track_$index',
        title: 'Track ${index + 1}',
        artist: 'Artist ${(index % 5) + 1}',
        album: 'Album ${(index % 10) + 1}',
        duration: Duration(minutes: 3, seconds: 30 + (index % 60)),
        serverId: 'server_1',
        streamUrl: 'https://example.com/track_$index.mp3',
        quality: AudioQuality.high,
        lastModified: DateTime.now(),
        trackNumber: (index % 12) + 1,
        coverArtUrl: index % 4 == 0
            ? 'https://picsum.photos/100/100?random=${index + 200}'
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Components Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Albums', icon: Icon(Icons.album)),
            Tab(text: 'Artists', icon: Icon(Icons.person)),
            Tab(text: 'Tracks', icon: Icon(Icons.music_note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAlbumsTab(), _buildArtistsTab(), _buildTracksTab()],
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return Column(
      children: [
        // Layout toggle buttons
        Padding(
          padding: OmnisonicInsets.allMd,
          child: Row(
            children: [
              Text('Layout:', style: context.textTheme.titleSmall),
              const SizedBox(width: OmnisonicSpacing.md),
              SegmentedButton<CardLayout>(
                segments: const [
                  ButtonSegment(value: CardLayout.grid, label: Text('Grid')),
                  ButtonSegment(value: CardLayout.list, label: Text('List')),
                  ButtonSegment(
                    value: CardLayout.compact,
                    label: Text('Compact'),
                  ),
                ],
                selected: {CardLayout.grid},
                onSelectionChanged: (Set<CardLayout> selection) {
                  // Handle layout change
                },
              ),
            ],
          ),
        ),
        // Albums grid
        Expanded(
          child: EnhancedGridView(
            padding: OmnisonicInsets.allMd,
            crossAxisCount: _getGridColumns(context),
            mainAxisSpacing: OmnisonicSpacing.md,
            crossAxisSpacing: OmnisonicSpacing.md,
            childAspectRatio: 0.8,
            enableStaggeredAnimation: true,
            children: _albums
                .map(
                  (album) => EnhancedAlbumCard(
                    album: album,
                    layout: CardLayout.grid,
                    isSelected: _selectedItems.contains(album.id),
                    onTap: () => _handleAlbumTap(album),
                    onLongPress: () => _handleAlbumLongPress(album),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsTab() {
    return EnhancedGridView(
      padding: OmnisonicInsets.allMd,
      crossAxisCount: _getGridColumns(context, isArtist: true),
      mainAxisSpacing: OmnisonicSpacing.lg,
      crossAxisSpacing: OmnisonicSpacing.md,
      childAspectRatio: 0.9,
      enableStaggeredAnimation: true,
      children: _artists
          .map(
            (artist) => EnhancedArtistCard(
              artist: artist,
              layout: CardLayout.grid,
              isSelected: _selectedItems.contains(artist.id),
              onTap: () => _handleArtistTap(artist),
              onLongPress: () => _handleArtistLongPress(artist),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTracksTab() {
    return EnhancedAnimatedList<Track>(
      items: _tracks,
      padding: OmnisonicInsets.allMd,
      enableStaggeredAnimation: true,
      enableReordering: true,
      enableDismiss: true,
      onReorder: _handleTrackReorder,
      onItemDismissed: _handleTrackDismissed,
      itemBuilder: (context, track, index, animation) {
        return EnhancedTrackCard(
          track: track,
          layout: CardLayout.list,
          trackNumber: index + 1,
          isPlaying: _playingTrackId == track.id,
          isSelected: _selectedItems.contains(track.id),
          onTap: () => _handleTrackTap(track),
          onLongPress: () => _handleTrackLongPress(track),
        );
      },
    );
  }

  int _getGridColumns(BuildContext context, {bool isArtist = false}) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return isArtist ? 6 : 8;
    } else if (width > 800) {
      return isArtist ? 4 : 6;
    } else if (width > 600) {
      return isArtist ? 3 : 4;
    } else {
      return isArtist ? 2 : 3;
    }
  }

  void _handleAlbumTap(Album album) {
    setState(() {
      if (_selectedItems.contains(album.id)) {
        _selectedItems.remove(album.id);
      } else {
        _selectedItems.add(album.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${album.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleAlbumLongPress(Album album) {
    _showContextMenu(context, 'Album: ${album.title}');
  }

  void _handleArtistTap(Artist artist) {
    setState(() {
      if (_selectedItems.contains(artist.id)) {
        _selectedItems.remove(artist.id);
      } else {
        _selectedItems.add(artist.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${artist.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleArtistLongPress(Artist artist) {
    _showContextMenu(context, 'Artist: ${artist.name}');
  }

  void _handleTrackTap(Track track) {
    setState(() {
      _playingTrackId = _playingTrackId == track.id ? null : track.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _playingTrackId == track.id ? 'Playing: ${track.title}' : 'Stopped',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleTrackLongPress(Track track) {
    _showContextMenu(context, 'Track: ${track.title}');
  }

  void _handleTrackReorder(int oldIndex, int newIndex) {
    setState(() {
      final track = _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, track);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved track from position ${oldIndex + 1} to ${newIndex + 1}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleTrackDismissed(Track track, int index) {
    setState(() {
      _tracks.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed: ${track.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _tracks.insert(index, track);
            });
          },
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: OmnisonicInsets.allLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.textTheme.titleMedium),
            const SizedBox(height: OmnisonicSpacing.lg),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Info'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of using enhanced components in a music player interface
class MusicPlayerExample extends StatefulWidget {
  const MusicPlayerExample({super.key});

  @override
  State<MusicPlayerExample> createState() => _MusicPlayerExampleState();
}

class _MusicPlayerExampleState extends State<MusicPlayerExample> {
  final List<Track> _queue = [];
  int _currentTrackIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _generateQueue();
  }

  void _generateQueue() {
    _queue.addAll(
      List.generate(
        10,
        (index) => Track(
          id: 'queue_track_$index',
          title: 'Queue Track ${index + 1}',
          artist: 'Queue Artist ${(index % 3) + 1}',
          album: 'Queue Album ${(index % 2) + 1}',
          duration: Duration(minutes: 3, seconds: 30 + (index % 60)),
          serverId: 'server_1',
          streamUrl: 'https://example.com/queue_track_$index.mp3',
          quality: AudioQuality.high,
          lastModified: DateTime.now(),
          trackNumber: index + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player Queue'),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Now playing section
          if (_queue.isNotEmpty) _buildNowPlayingSection(),

          // Queue section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: OmnisonicInsets.allMd,
                  child: Text('Up Next', style: context.textTheme.titleLarge),
                ),
                Expanded(
                  child: EnhancedAnimatedList<Track>(
                    items: _queue,
                    enableReordering: true,
                    enableDismiss: true,
                    enableStaggeredAnimation: true,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        final track = _queue.removeAt(oldIndex);
                        _queue.insert(newIndex, track);

                        // Update current track index if needed
                        if (oldIndex == _currentTrackIndex) {
                          _currentTrackIndex = newIndex;
                        } else if (oldIndex < _currentTrackIndex &&
                            newIndex >= _currentTrackIndex) {
                          _currentTrackIndex--;
                        } else if (oldIndex > _currentTrackIndex &&
                            newIndex <= _currentTrackIndex) {
                          _currentTrackIndex++;
                        }
                      });
                    },
                    onItemDismissed: (track, index) {
                      setState(() {
                        _queue.removeAt(index);
                        if (index < _currentTrackIndex) {
                          _currentTrackIndex--;
                        } else if (index == _currentTrackIndex &&
                            _queue.isNotEmpty) {
                          _currentTrackIndex = _currentTrackIndex.clamp(
                            0,
                            _queue.length - 1,
                          );
                        }
                      });
                    },
                    itemBuilder: (context, track, index, animation) {
                      return EnhancedTrackCard(
                        track: track,
                        layout: CardLayout.list,
                        trackNumber: index + 1,
                        isPlaying: _isPlaying && index == _currentTrackIndex,
                        onTap: () {
                          setState(() {
                            _currentTrackIndex = index;
                            _isPlaying = true;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingSection() {
    final currentTrack = _queue[_currentTrackIndex];

    return Container(
      padding: OmnisonicInsets.allLg,
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(OmnisonicRadius.lg),
        ),
      ),
      child: Row(
        children: [
          // Album art
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OmnisonicRadius.md),
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 32),
          ),
          const SizedBox(width: OmnisonicSpacing.md),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTrack.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentTrack.artist,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Play/pause button
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
          ),
        ],
      ),
    );
  }
}
