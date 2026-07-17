import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';

/// Artist detail page showing albums with enhanced functionality
class ArtistDetailPage extends StatefulWidget {
  final Artist artist;

  const ArtistDetailPage({super.key, required this.artist});

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
            widget.artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_albums.isNotEmpty)
              IconButton(
                tooltip: 'Play All',
                icon: const Icon(Icons.play_arrow),
                onPressed: _playArtist,
              ),
            if (_albums.isNotEmpty)
              IconButton(
                tooltip: 'Shuffle',
                icon: const Icon(Icons.shuffle),
                onPressed: _shuffleArtist,
              ),
          ],
        ),
        SliverToBoxAdapter(child: _buildArtistHeader(context)),

        // Albums section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(
                  'Albums',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                Icon(Icons.album_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No albums found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final rawCount = (constraints.crossAxisExtent / 180).floor();
          final crossAxisCount = rawCount < 2
              ? 2
              : (rawCount > 6 ? 6 : rawCount);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final album = _albums[index];
              return AlbumCard(
                album: album,
                onTap: () => _onAlbumTapped(album),
              );
            }, childCount: _albums.length),
          );
        },
      ),
    );
  }

  Widget _buildArtistHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final imageSize = isNarrow ? 150.0 : 190.0;
          final content = _buildArtistHeaderContent(context, scheme);
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArtistArtwork(context, scheme, imageSize),
                const SizedBox(height: 16),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArtistArtwork(context, scheme, imageSize),
              const SizedBox(width: 24),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArtistHeaderContent(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.artist.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _buildMetadataChip(
              context,
              Icons.album,
              '${_albums.length} album${_albums.length == 1 ? '' : 's'}',
            ),
            _buildMetadataChip(context, Icons.dns, _getServerName(context)),
            if (widget.artist.musicBrainzId != null)
              _buildMetadataChip(context, Icons.fingerprint, 'MusicBrainz'),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.artist.biography != null &&
            widget.artist.biography!.isNotEmpty)
          _buildAboutCard(
            context,
            scheme,
            widget.artist.biography!,
            widget.artist.musicBrainzId,
          )
        else if (widget.artist.musicBrainzId != null)
          _buildAboutCard(
            context,
            scheme,
            'Artist information will be available in a future update.',
            widget.artist.musicBrainzId,
          ),
        if (_albums.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _playArtist,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _shuffleArtist,
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

  Widget _buildAboutCard(
    BuildContext context,
    ColorScheme scheme,
    String text,
    String? musicBrainzId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (musicBrainzId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'MusicBrainz ID: $musicBrainzId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtistArtwork(
    BuildContext context,
    ColorScheme scheme,
    double size,
  ) {
    return Hero(
      tag: 'artist-${widget.artist.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceVariant,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipOval(
          child: widget.artist.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.artist.imageUrl!,
                  cacheKey: widget.artist.imageUrl!.subsonicCacheKey,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  placeholder: (context, url) => Container(
                    color: scheme.surfaceVariant,
                    child: Icon(
                      Icons.person,
                      size: size * 0.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: scheme.surfaceVariant,
                    child: Icon(
                      Icons.person,
                      size: size * 0.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Container(
                  color: scheme.surfaceVariant,
                  child: Icon(
                    Icons.person,
                    size: size * 0.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No albums to play')));
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
    playbackViewModel.playTrack(
      artistTracks.first,
      queue: artistTracks,
      startIndex: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Playing ${widget.artist.name} (${artistTracks.length} tracks)',
        ),
      ),
    );
  }

  void _shuffleArtist() {
    if (_albums.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No albums to shuffle')));
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
    playbackViewModel.playTrack(
      shuffledTracks.first,
      queue: shuffledTracks,
      startIndex: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Shuffling ${widget.artist.name} (${artistTracks.length} tracks)',
        ),
      ),
    );
  }

  void _onAlbumTapped(Album album) {
    // Navigate to album detail page
    context.push('/album-detail', extra: album);
  }
}
