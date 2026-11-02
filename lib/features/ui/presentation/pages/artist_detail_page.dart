import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/entities/entities.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/app_log.dart';
import '../services/library_sort_service.dart';

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
        return LibrarySortService.compareNames(a.title, b.title);
      });

      if (!mounted) return;
      setState(() {
        _albums = artistAlbums;
        _isLoading = false;
      });
    } catch (e) {
      AppLog.error('Loading albums for ${widget.artist.id} failed: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = describeUnexpected(action: "load this artist's albums");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same reason as the album page: a bare CustomScrollView leaves SnackBars
    // and the AppBar without a Scaffold to sit in.
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAlbums,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouter.library);
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
                    icon: const Icon(OmnisonicIcons.playArrow),
                    onPressed: _playArtist,
                  ),
                if (_albums.isNotEmpty)
                  IconButton(
                    tooltip: 'Shuffle',
                    icon: const Icon(OmnisonicIcons.shuffle),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Albums content
            _buildAlbumsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsContent() {
    if (_isLoading) {
      return LoadingStateView.sliver(kind: SkeletonKind.grid, itemCount: 6);
    }

    final error = _errorMessage;
    if (error != null) {
      return ErrorStateView.sliver(
        title: 'Failed to load albums',
        message: error,
        onRetry: _loadAlbums,
      );
    }

    if (_albums.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          icon: OmnisonicIcons.albumOutline,
          title: 'No albums found',
          subtitle:
              'None of the connected servers have albums by this '
              'artist.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = MediaGridPreset.columnsFor(width);
          final cell = MediaGridPreset.cellWidth(width, columns);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: MediaGridPreset.spacing,
              mainAxisSpacing: MediaGridPreset.spacing,
              mainAxisExtent: AlbumCard.extentFor(context, cell),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final album = _albums[index];
              return AlbumCard(
                key: ValueKey(album.id),
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
            MetadataChip(
              icon: OmnisonicIcons.album,
              label: '${_albums.length} album${_albums.length == 1 ? '' : 's'}',
            ),
            MetadataChip(
              icon: OmnisonicIcons.dns,
              label: _getServerName(context),
            ),
            if (widget.artist.musicBrainzId != null)
              MetadataChip(
                icon: OmnisonicIcons.fingerprint,
                label: 'MusicBrainz',
              ),
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
                icon: const Icon(OmnisonicIcons.playArrow),
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
                icon: const Icon(OmnisonicIcons.shuffle),
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
          child: CoverArt(
            url: widget.artist.imageUrl,
            shape: CoverArtShape.circle,
            fallbackIcon: OmnisonicIcons.person,
          ),
        ),
      ),
    );
  }

  String _getServerName(BuildContext context) => context
      .read<ServerManagementViewModel>()
      .serverNameFor(widget.artist.serverId);

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
