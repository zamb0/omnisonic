import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';

/// Artist detail page showing albums with enhanced functionality
class ArtistDetailPage extends StatefulWidget {
  final Artist artist;

  const ArtistDetailPage({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  List<Album> _albums = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final musicRepository = context.read<MusicLibraryViewModel>();
      // Extract the original Subsonic ID for API calls
      final originalArtistId = IdGenerator.extractSubsonicId(widget.artist.id);
      
      // For now, we'll filter albums from the main collection
      // TODO: Implement proper getArtistAlbums method in view model
      final allAlbums = musicRepository.albums;
      final artistAlbums = allAlbums.where((album) {
        final albumArtistId = album.artistId != null 
            ? IdGenerator.extractSubsonicId(album.artistId!)
            : null;
        // Match by artist ID or artist name
        return albumArtistId == originalArtistId || 
               album.artist.toLowerCase() == widget.artist.name.toLowerCase();
      }).toList();

      // Sort albums by year (newest first), then by title
      artistAlbums.sort((a, b) {
        if (a.year != null && b.year != null) {
          final yearComparison = b.year!.compareTo(a.year!);
          if (yearComparison != 0) return yearComparison;
        } else if (a.year != null) {
          return -1;
        } else if (b.year != null) {
          return 1;
        }
        return a.title.compareTo(b.title);
      });

      setState(() {
        _albums = artistAlbums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load albums: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Enhanced app bar with artist image background
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background artist image with blur
                  if (widget.artist.imageUrl != null)
                    Image.network(
                      widget.artist.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[300]),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Artist image in center
                  Center(
                    child: Hero(
                      tag: 'artist-${widget.artist.id}',
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.artist.imageUrl != null
                              ? Image.network(
                                  widget.artist.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Play all button
              if (_albums.isNotEmpty)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  onPressed: () => _playArtist(),
                ),
              // Shuffle button
              if (_albums.isNotEmpty)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shuffle,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  onPressed: () => _shuffleArtist(),
                ),
            ],
        ),
          
        // Artist metadata section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artist name and metadata
                  Text(
                    widget.artist.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Artist details row
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildMetadataChip(
                        context,
                        Icons.album,
                        '${_albums.length} album${_albums.length == 1 ? '' : 's'}',
                      ),
                      _buildMetadataChip(
                        context,
                        Icons.dns,
                        _getServerName(context),
                      ),
                      if (widget.artist.musicBrainzId != null)
                        _buildMetadataChip(
                          context,
                          Icons.fingerprint,
                          'MusicBrainz',
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Artist biography section (if available)
                  if (widget.artist.biography != null && widget.artist.biography!.isNotEmpty) ...[
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.artist.biography!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (widget.artist.musicBrainzId != null) ...[
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artist information will be available in a future update.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MusicBrainz ID: ${widget.artist.musicBrainzId}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Action buttons
                  if (_albums.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _playArtist,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shuffleArtist,
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Shuffle'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Albums section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Albums',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_albums.isNotEmpty)
                    IconButton(
                      onPressed: _loadAlbums,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                ],
              ),
            ),
          ),
          
          // Albums content
          _buildAlbumsContent(),
        ],
      );
  }

  Widget _buildAlbumsContent() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load albums',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAlbums,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_albums.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.album_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No albums found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final album = _albums[index];
            return AlbumCard(
              album: album,
              onTap: () => _onAlbumTapped(album),
            );
          },
          childCount: _albums.length,
        ),
      ),
    );
  }

  Widget _buildMetadataChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getServerName(BuildContext context) {
    try {
      final serverViewModel = context.read<ServerManagementViewModel>();
      final server = serverViewModel.servers.firstWhere(
        (s) => s.id == widget.artist.serverId,
        orElse: () => throw Exception('Server not found'),
      );
      return server.name;
    } catch (e) {
      // Fallback to serverId if server not found
      return widget.artist.serverId;
    }
  }

  void _playArtist() {
    if (_albums.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No albums to play')),
      );
      return;
    }
    
    // Get all tracks from all albums
    final musicRepository = context.read<MusicLibraryViewModel>();
    final allTracks = musicRepository.tracks;
    final artistTracks = <Track>[];
    
    for (final album in _albums) {
      final originalAlbumId = IdGenerator.extractSubsonicId(album.id);
      final albumTracks = allTracks.where((track) {
        // Match by albumId if available
        if (track.albumId != null && track.albumId!.isNotEmpty) {
          final trackAlbumId = IdGenerator.extractSubsonicId(track.albumId!);
          if (trackAlbumId == originalAlbumId) {
            return true;
          }
        }
        
        // Fallback: match by album name and server ID
        return track.album.toLowerCase() == album.title.toLowerCase() &&
               track.serverId == album.serverId;
      }).toList();
      artistTracks.addAll(albumTracks);
    }
    
    if (artistTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks found for this artist')),
      );
      return;
    }
    
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(artistTracks.first, queue: artistTracks, startIndex: 0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing ${widget.artist.name} (${artistTracks.length} tracks)')),
    );
  }

  void _shuffleArtist() {
    if (_albums.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No albums to shuffle')),
      );
      return;
    }
    
    // Get all tracks from all albums
    final musicRepository = context.read<MusicLibraryViewModel>();
    final allTracks = musicRepository.tracks;
    final artistTracks = <Track>[];
    
    for (final album in _albums) {
      final originalAlbumId = IdGenerator.extractSubsonicId(album.id);
      final albumTracks = allTracks.where((track) {
        // Match by albumId if available
        if (track.albumId != null && track.albumId!.isNotEmpty) {
          final trackAlbumId = IdGenerator.extractSubsonicId(track.albumId!);
          if (trackAlbumId == originalAlbumId) {
            return true;
          }
        }
        
        // Fallback: match by album name and server ID
        return track.album.toLowerCase() == album.title.toLowerCase() &&
               track.serverId == album.serverId;
      }).toList();
      artistTracks.addAll(albumTracks);
    }
    
    if (artistTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks found for this artist')),
      );
      return;
    }
    
    final shuffledTracks = List<Track>.from(artistTracks)..shuffle();
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(shuffledTracks.first, queue: shuffledTracks, startIndex: 0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shuffling ${widget.artist.name} (${artistTracks.length} tracks)')),
    );
  }

  void _onAlbumTapped(Album album) {
    // Navigate to album detail page
    context.push('/album-detail', extra: album);
  }
}