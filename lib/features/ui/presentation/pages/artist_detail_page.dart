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
import '../../../../core/utils/formatters.dart';

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

            const SliverToBoxAdapter(child: SectionHeader(title: 'Albums')),
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
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        0,
        PageGutter.of(context),
        OmnisonicLayout.pageBottom,
      ),
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

  /// The artist's [DetailHeader].
  ///
  /// The old one showed "Artist information will be available in a future
  /// update." whenever there was a MusicBrainz id but no biography, a
  /// "MusicBrainz" chip that looked like a link and was not, and the raw id
  /// in a hard-coded monospace font. Only the biography is shown now, when
  /// the server has one.
  Widget _buildArtistHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final biography = widget.artist.biography?.trim();
    final hasAlbums = _albums.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        OmnisonicSpacing.sm,
        PageGutter.of(context),
        0,
      ),
      child: DetailHeader(
        eyebrow: 'Artist',
        title: widget.artist.name,
        artwork: LayoutBuilder(
          builder: (context, constraints) =>
              _buildArtistArtwork(context, scheme, constraints.maxWidth),
        ),
        chips: [
          if (!_isLoading)
            MetadataChip(
              icon: OmnisonicIcons.album,
              label: pluralize(_albums.length, 'album'),
            ),
          MetadataChip(
            icon: OmnisonicIcons.dns,
            label: _getServerName(context),
          ),
        ],
        actions: [
          AuroraButton(
            onPressed: hasAlbums ? _playArtist : null,
            icon: OmnisonicIcons.playArrow,
            label: 'Play all',
          ),
          OmnisonicButton(
            variant: OmnisonicButtonVariant.tonal,
            onPressed: hasAlbums ? _shuffleArtist : null,
            icon: OmnisonicIcons.shuffle,
            label: 'Shuffle',
          ),
        ],
        below: biography == null || biography.isEmpty
            ? null
            : _Biography(text: biography),
      ),
    );
  }

  Widget _buildArtistArtwork(
    BuildContext context,
    ColorScheme scheme,
    double size,
  ) {
    return Hero(
      tag: 'artist-${widget.artist.id}',
      child: CoverArt(
        url: widget.artist.imageUrl,
        size: size,
        shape: CoverArtShape.circle,
        elevated: true,
        fallbackIcon: OmnisonicIcons.person,
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
    if (_albums.isEmpty) return;

    final library = context.read<MusicLibraryViewModel>();
    final playbackViewModel = context.read<PlaybackViewModel>();

    final artistTracks = await library.getArtistTracks(widget.artist.id);
    if (!mounted) return;

    if (artistTracks.isEmpty) {
      showFeedback(
        context,
        "Couldn't find tracks for ${widget.artist.name}",
        kind: FeedbackKind.error,
      );
      return;
    }

    // No "Playing …" snackbar: the mini player already says so.
    final queue = shuffle
        ? (List<Track>.from(artistTracks)..shuffle())
        : artistTracks;
    playbackViewModel.playTrack(queue.first, queue: queue, startIndex: 0);
  }

  void _onAlbumTapped(Album album) {
    // Navigate to album detail page
    context.push(AppRouter.albumDetailLocation(album.id), extra: album);
  }
}

/// The server's biography of the artist, collapsed to a few lines.
class _Biography extends StatefulWidget {
  const _Biography({required this.text});

  final String text;

  @override
  State<_Biography> createState() => _BiographyState();
}

class _BiographyState extends State<_Biography> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: OmnisonicTypography.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (widget.text.length > 240)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }
}
