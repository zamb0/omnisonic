import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';

/// Album detail page showing tracks with enhanced functionality
class AlbumDetailPage extends StatefulWidget {
  final Album album;

  const AlbumDetailPage({
    super.key,
    required this.album,
  });

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  List<Track> _tracks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final musicRepository = context.read<MusicLibraryViewModel>();
      
      // Use proper getAlbumTracks method which queries by albumId
      // and fetches from server if not found locally
      final albumTracks = await musicRepository.getAlbumTracks(widget.album.id);

      // Sort tracks by track number if available
      albumTracks.sort((a, b) {
        final aTrackNum = a.trackNumber ?? 0;
        final bTrackNum = b.trackNumber ?? 0;
        return aTrackNum.compareTo(bTrackNum);
      });

      setState(() {
        _tracks = albumTracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tracks: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Enhanced app bar with album artwork background
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/library'),
          ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.album.title,
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
                  // Background album artwork with blur
                  if (widget.album.coverArtUrl != null)
                    Image.network(
                      widget.album.coverArtUrl!,
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
                  // Album artwork in center
                  Center(
                    child: Hero(
                      tag: 'album-${widget.album.id}',
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.album.coverArtUrl != null
                              ? Image.network(
                                  widget.album.coverArtUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.album,
                                      size: 100,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.album,
                                    size: 100,
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
              if (_tracks.isNotEmpty)
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
                  onPressed: () => _playAlbum(),
                ),
              // Shuffle button
              if (_tracks.isNotEmpty)
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
                  onPressed: () => _shuffleAlbum(),
                ),
            ],
        ),
          
        // Album metadata section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album title and metadata
                  Text(
                    widget.album.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Album details row
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (widget.album.year != null)
                        _buildMetadataChip(
                          context,
                          Icons.calendar_today,
                          '${widget.album.year}',
                        ),
                      if (widget.album.genre != null)
                        _buildMetadataChip(
                          context,
                          Icons.music_note,
                          widget.album.genre!,
                        ),
                      _buildMetadataChip(
                        context,
                        Icons.queue_music,
                        '${_tracks.length} track${_tracks.length == 1 ? '' : 's'}',
                      ),
                      if (_tracks.isNotEmpty)
                        _buildMetadataChip(
                          context,
                          Icons.access_time,
                          _formatTotalDuration(_tracks),
                        ),
                      _buildMetadataChip(
                        context,
                        Icons.dns,
                        _getServerName(context),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  if (_tracks.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _playAlbum,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shuffleAlbum,
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
          
          // Tracks section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Tracks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_tracks.isNotEmpty)
                    IconButton(
                      onPressed: _loadTracks,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                ],
              ),
            ),
          ),
          
          // Tracks content
          _buildTracksContent(),
        ],
      );
  }

  Widget _buildTracksContent() {
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
                  'Failed to load tracks',
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
                  onPressed: _loadTracks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.music_note_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No tracks found',
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = _tracks[index];
          return TrackTile(
            track: track,
            showTrackNumber: true,
            onTap: () => _onTrackTapped(track, index),
            onMorePressed: () => _showTrackOptions(track),
          );
        },
        childCount: _tracks.length,
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

  String _formatTotalDuration(List<Track> tracks) {
    final totalSeconds = tracks
        .where((track) => track.duration != null)
        .fold<int>(0, (sum, track) => sum + track.duration!.inSeconds);
    
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getServerName(BuildContext context) {
    try {
      final serverViewModel = context.read<ServerManagementViewModel>();
      final server = serverViewModel.servers.firstWhere(
        (s) => s.id == widget.album.serverId,
        orElse: () => throw Exception('Server not found'),
      );
      return server.name;
    } catch (e) {
      // Fallback to serverId if server not found
      return widget.album.serverId;
    }
  }

  String _getTrackServerName(Track track) {
    try {
      final serverViewModel = context.read<ServerManagementViewModel>();
      final serverId = IdGenerator.extractServerId(track.id);
      final server = serverViewModel.servers.firstWhere(
        (s) => s.id == serverId,
        orElse: () => throw Exception('Server not found'),
      );
      return server.name;
    } catch (e) {
      // Fallback to serverId if server not found
      return IdGenerator.extractServerId(track.id);
    }
  }

  void _playAlbum() {
    if (_tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks to play')),
      );
      return;
    }
    
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(_tracks.first, queue: _tracks, startIndex: 0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing ${widget.album.title} (${_tracks.length} tracks)')),
    );
  }

  void _shuffleAlbum() {
    if (_tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks to shuffle')),
      );
      return;
    }
    
    final playbackViewModel = context.read<PlaybackViewModel>();
    final shuffledTracks = List<Track>.from(_tracks)..shuffle();
    playbackViewModel.playTrack(shuffledTracks.first, queue: shuffledTracks, startIndex: 0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shuffling ${widget.album.title} (${_tracks.length} tracks)')),
    );
  }

  void _onTrackTapped(Track track, int index) {
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(track, queue: _tracks, startIndex: index);
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
                context.pop();
                _onTrackTapped(track, _tracks.indexOf(track));
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to Queue'),
              onTap: () {
                context.pop();
                context.read<PlaybackViewModel>().addToQueue(track);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to queue')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Track Info'),
              onTap: () {
                context.pop();
                _showTrackInfo(track);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackInfo(Track track) {
    AnimationUtils.showCustomDialog(
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
            if (track.trackNumber != null) _buildInfoRow('Track', track.trackNumber.toString()),
            _buildInfoRow('Quality', track.quality.toString()),
            _buildInfoRow('Server', _getTrackServerName(track)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
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

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Unknown';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}