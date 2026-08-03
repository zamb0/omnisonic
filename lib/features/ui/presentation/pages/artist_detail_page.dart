import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/design_system/design_system.dart';

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
      final library = context.read<MusicLibraryViewModel>();
      final artistAlbums = await library.getArtistAlbums(widget.artist.id);

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

      if (!mounted) return;
      setState(() {
        _albums = artistAlbums;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
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
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(OmnisonicSpacing.xxl),
            child: Column(
              children: [
                Icon(
                  Icons.album_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: OmnisonicSpacing.md),
                Text(
                  'No albums found',
                  style: OmnisonicTypography.sectionTitleSmall,
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
            borderRadius: BorderRadius.circular(OmnisonicRadius.md),
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
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipOval(
          child: widget.artist.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: SubsonicCoverArt.of(
                    widget.artist.imageUrl!,
                    512,
                  ).url,
                  cacheKey: SubsonicCoverArt.of(
                    widget.artist.imageUrl!,
                    512,
                  ).cacheKey,
                  // This was the one image in the app without the shared cache
                  // manager, so artist art bypassed the 30-day disk cache.
                  cacheManager: OmnisonicImageCacheManager.instance,
                  fit: BoxFit.cover,
                  memCacheWidth: 512,
                  memCacheHeight: 512,
                  placeholder: (context, url) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: size * 0.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: size * 0.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Container(
                  color: scheme.surfaceContainerHighest,
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
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
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

  Future<void> _playArtist() => _playArtistTracks(shuffle: false);

  Future<void> _shuffleArtist() => _playArtistTracks(shuffle: true);

  /// Loads the artist's tracks from the repository and starts playback.
  ///
  /// The tracks used to be reconstructed by scanning the whole in-memory
  /// collection and matching album titles; the repository resolves them by
  /// artist ID instead, falling back to the artist's albums when a server
  /// does not tag songs with one.
  Future<void> _playArtistTracks({required bool shuffle}) async {
    if (_albums.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shuffle ? 'No albums to shuffle' : 'No albums to play'),
        ),
      );
      return;
    }

    final library = context.read<MusicLibraryViewModel>();
    final playbackViewModel = context.read<PlaybackViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final artistTracks = await library.getArtistTracks(widget.artist.id);
    if (!mounted) return;

    if (artistTracks.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No tracks found for this artist')),
      );
      return;
    }

    final queue = shuffle
        ? (List<Track>.from(artistTracks)..shuffle())
        : artistTracks;
    playbackViewModel.playTrack(queue.first, queue: queue, startIndex: 0);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${shuffle ? 'Shuffling' : 'Playing'} ${widget.artist.name} '
          '(${queue.length} tracks)',
        ),
      ),
    );
  }

  void _onAlbumTapped(Album album) {
    // Navigate to album detail page
    context.push(AppRouter.albumDetailLocation(album.id), extra: album);
  }
}
