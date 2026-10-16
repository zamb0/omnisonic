import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';

/// Album detail page showing tracks with enhanced functionality
class AlbumDetailPage extends StatefulWidget {
  final Album album;

  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late Album _album;
  List<Album> _albumVariants = [];
  List<Track> _tracks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _album = widget.album;
    _albumVariants = _resolveAlbumVariants();
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
      final albumTracks = await musicRepository.getAlbumTracks(_album.id);

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
        SliverAppBar(
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/library');
              }
            },
          ),
          title: Text(
            _album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_tracks.isNotEmpty)
              IconButton(
                tooltip: 'Play',
                icon: const Icon(Icons.play_arrow),
                onPressed: _playAlbum,
              ),
            if (_tracks.isNotEmpty)
              IconButton(
                tooltip: 'Shuffle',
                icon: const Icon(Icons.shuffle),
                onPressed: _shuffleAlbum,
              ),
          ],
        ),
        SliverToBoxAdapter(child: _buildAlbumHeader(context)),

        // Tracks section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(
                  'Tracks',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                Icon(Icons.music_note_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tracks found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = _tracks[index];
        return TrackTile(
          track: track,
          showTrackNumber: true,
          onTap: () => _onTrackTapped(track, index),
          onMorePressed: () => _showTrackOptions(track),
        );
      }, childCount: _tracks.length),
    );
  }

  Widget _buildAlbumHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final artworkSize = isNarrow ? 160.0 : 200.0;
          final content = _buildAlbumHeaderContent(
            context,
            scheme,
            artworkSize,
          );
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlbumArtwork(context, scheme, artworkSize),
                const SizedBox(height: 16),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlbumArtwork(context, scheme, artworkSize),
              const SizedBox(width: 24),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlbumHeaderContent(
    BuildContext context,
    ColorScheme scheme,
    double artworkSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _album.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          _album.artist,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_albumVariants.length > 1) ...[
          const SizedBox(height: 12),
          _buildServerPicker(context, scheme),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (_album.year != null)
              _buildMetadataChip(
                context,
                Icons.calendar_today,
                '${_album.year}',
              ),
            if (_album.genre != null)
              _buildMetadataChip(context, Icons.music_note, _album.genre!),
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
              _getServerNameForAlbum(context, _album),
            ),
          ],
        ),
        if (_tracks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _playAlbum,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _shuffleAlbum,
                icon: const Icon(Icons.shuffle),
                label: const Text('Shuffle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAlbumArtwork(
    BuildContext context,
    ColorScheme scheme,
    double size,
  ) {
    final borderRadius = BorderRadius.circular(14);
    return Hero(
      tag: 'album-${widget.album.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: _album.coverArtUrl != null
              ? CachedNetworkImage(
                  imageUrl: _album.coverArtUrl!.withCoverArtSize(800),
                  cacheKey: _album.coverArtUrl!
                      .withCoverArtSize(800)
                      .subsonicCacheKey,
                  cacheManager: OmnisonicImageCacheManager.instance,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  memCacheHeight: 800,
                  fadeInDuration: const Duration(milliseconds: 120),
                  useOldImageOnUrlChange: true,
                  placeholder: (context, url) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.album,
                      size: size * 0.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (context, url, error) => coverArtErrorWidget(
                    Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.album,
                        size: size * 0.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    url,
                    error,
                  ),
                )
              : Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.album,
                    size: size * 0.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildServerPicker(BuildContext context, ColorScheme scheme) {
    final serverViewModel = context.read<ServerManagementViewModel>();
    final serverMap = {
      for (var server in serverViewModel.servers) server.id: server.name,
    };
    final selected = _albumVariants.firstWhere(
      (album) => album.id == _album.id,
      orElse: () => _albumVariants.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Album>(
          value: selected,
          isDense: true,
          dropdownColor: scheme.surface,
          icon: Icon(
            Icons.expand_more,
            color: scheme.onSurfaceVariant,
            size: 18,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          items: _albumVariants.map((album) {
            final serverName = serverMap[album.serverId] ?? album.serverId;
            final trackCount = album.trackCount ?? 0;
            return DropdownMenuItem<Album>(
              value: album,
              child: Text('$serverName · $trackCount tracks'),
            );
          }).toList(),
          onChanged: (album) {
            if (album == null || album.id == _album.id) return;
            setState(() {
              _album = album;
            });
            _loadTracks();
          },
        ),
      ),
    );
  }

  Widget _buildMetadataChip(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Album> _resolveAlbumVariants() {
    final libraryViewModel = context.read<MusicLibraryViewModel>();
    final key = _albumGroupKey(_album);
    final variants = libraryViewModel.albums
        .where((album) => _albumGroupKey(album) == key)
        .toList();

    if (variants.every((album) => album.id != _album.id)) {
      variants.add(_album);
    }

    variants.sort((a, b) {
      final aTracks = a.trackCount ?? 0;
      final bTracks = b.trackCount ?? 0;
      if (aTracks != bTracks) {
        return bTracks.compareTo(aTracks);
      }
      return b.lastModified.compareTo(a.lastModified);
    });

    return variants;
  }

  String _albumGroupKey(Album album) {
    final title = _normalizeAlbumKey(album.title);
    final artist = album.artist; // Exact match for artist
    final year = album.year?.toString() ?? '';
    return '$title|$artist|$year';
  }

  String _normalizeAlbumKey(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  String _formatTotalDuration(List<Track> tracks) {
    final totalSeconds = tracks.fold<int>(
      0,
      (sum, track) => sum + track.duration.inSeconds,
    );

    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getServerNameForAlbum(BuildContext context, Album album) {
    try {
      final serverViewModel = context.read<ServerManagementViewModel>();
      final server = serverViewModel.servers.firstWhere(
        (s) => s.id == album.serverId,
        orElse: () => throw Exception('Server not found'),
      );
      return server.name;
    } catch (e) {
      // Fallback to serverId if server not found
      return album.serverId;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tracks to play')));
      return;
    }

    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(_tracks.first, queue: _tracks, startIndex: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${_album.title} (${_tracks.length} tracks)'),
      ),
    );
  }

  void _shuffleAlbum() {
    if (_tracks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tracks to shuffle')));
      return;
    }

    final playbackViewModel = context.read<PlaybackViewModel>();
    final shuffledTracks = List<Track>.from(_tracks)..shuffle();
    playbackViewModel.playTrack(
      shuffledTracks.first,
      queue: shuffledTracks,
      startIndex: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shuffling ${_album.title} (${_tracks.length} tracks)'),
      ),
    );
  }

  void _onTrackTapped(Track track, int index) {
    debugPrint('Track tapped: ${track.title} (${track.id})');
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Added to queue')));
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
            if (track.year != null)
              _buildInfoRow('Year', track.year.toString()),
            if (track.genre != null) _buildInfoRow('Genre', track.genre!),
            if (track.trackNumber != null)
              _buildInfoRow('Track', track.trackNumber.toString()),
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
