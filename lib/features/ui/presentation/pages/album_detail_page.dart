import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../music/presentation/widgets/add_to_playlist_sheet.dart';
import '../../../offline/presentation/viewmodels/offline_mode_view_model.dart';
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

  /// Tracks for every album variant, keyed by album ID, used to compare
  /// quality/availability across sources for the SOURCE panel and the
  /// per-track notes. Populated lazily and only when there's more than one
  /// source to compare.
  final Map<String, List<Track>> _variantTracksCache = {};

  /// Source notes keyed by track ID, rebuilt whenever a variant's tracks
  /// arrive. [_sourceNoteFor] is called once per visible row and used to walk
  /// every variant's tracks and read the server list from the context on each
  /// call, which made scrolling cost O(variants x tracks) per row.
  Map<String, String>? _sourceNotes;

  /// Server ID to display name, so per-row lookups do not read the provider
  /// and scan the server list again for every visible track.
  Map<String, String> _serverNames = const {};

  @override
  void initState() {
    super.initState();
    _album = widget.album;
    _albumVariants = _resolveAlbumVariants();
    _loadTracks();
    if (_albumVariants.length > 1) {
      _loadVariantTracksForComparison();
    }
  }

  /// Fetches (and caches) every variant's track list so the SOURCE panel can
  /// show a real per-source quality summary instead of just track counts.
  Future<void> _loadVariantTracksForComparison() async {
    final musicRepository = context.read<MusicLibraryViewModel>();
    for (final variant in _albumVariants) {
      if (_variantTracksCache.containsKey(variant.id)) continue;
      try {
        final tracks = await musicRepository.getAlbumTracks(variant.id);
        if (!mounted) return;
        setState(() {
          _variantTracksCache[variant.id] = tracks;
          _rebuildSourceNotes();
        });
      } catch (_) {
        // Best-effort: a source that fails to load just won't get a quality
        // summary or count toward the cross-source note comparisons.
      }
    }
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
        _variantTracksCache[_album.id] = albumTracks;
        _rebuildSourceNotes();
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
    // The page used to return a bare CustomScrollView. Without a Scaffold,
    // the SnackBars raised from the track sheet had nothing to attach to and
    // the AppBar had no scaffold geometry to work with.
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTracks,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
              return _buildDesktopScaffold(context);
            }
            return _buildMobileScaffold(context);
          },
        ),
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
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
              ],
            ),
          ),
        ),

        // Tracks content
        _buildTracksContent(),
      ],
    );
  }

  /// Desktop shell (≥1024px): two columns — a track table with SOURCE/FORMAT
  /// columns on the left, a "Resolution" panel (source picker, cross-source
  /// conflict callouts, other albums by the same artist) on the right.
  Widget _buildDesktopScaffold(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        // Two sliver columns rather than a Row inside one adapter. The whole
        // desktop layout used to be a single box, which forced the track
        // table to be an eager Column — a 500-track album built 500 rows on
        // the first frame.
        SliverPadding(
          padding: const EdgeInsets.all(OmnisonicSpacing.lg),
          sliver: SliverCrossAxisGroup(
            slivers: [
              SliverCrossAxisExpanded(
                flex: 2,
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAlbumHeaderContent(
                            context,
                            Theme.of(context).colorScheme,
                            0,
                            includeArtwork: true,
                            includeSourcePanel: false,
                          ),
                          const SizedBox(height: OmnisonicSpacing.lg),
                          _buildTracksHeaderRow(context),
                          const SizedBox(height: OmnisonicSpacing.sm),
                        ],
                      ),
                    ),
                    ..._buildTrackTableSlivers(context),
                  ],
                ),
              ),
              SliverConstrainedCrossAxis(
                maxExtent: 340 + OmnisonicSpacing.lg,
                sliver: SliverPadding(
                  padding: const EdgeInsets.only(left: OmnisonicSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _buildResolutionPanel(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        icon: const Icon(OmnisonicIcons.arrowBack),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/library');
          }
        },
      ),
      title: Text(_album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (_tracks.isNotEmpty)
          IconButton(
            tooltip: 'Play',
            icon: const Icon(OmnisonicIcons.playArrow),
            onPressed: _playAlbum,
          ),
        if (_tracks.isNotEmpty)
          IconButton(
            tooltip: 'Shuffle',
            icon: const Icon(OmnisonicIcons.shuffle),
            onPressed: _shuffleAlbum,
          ),
        if (_tracks.isNotEmpty)
          IconButton(
            tooltip: 'Download album',
            icon: const Icon(OmnisonicIcons.downloadOutline),
            onPressed: _downloadAlbum,
          ),
      ],
    );
  }

  Widget _buildTracksHeaderRow(BuildContext context) {
    return Row(
      children: [
        Text(
          'Tracks',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTracksContent() {
    if (_isLoading) {
      return LoadingStateView.sliver(kind: SkeletonKind.list, itemCount: 6);
    }

    final error = _errorMessage;
    if (error != null) {
      return ErrorStateView.sliver(
        title: 'Failed to load tracks',
        message: error,
        onRetry: _loadTracks,
      );
    }

    if (_tracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          icon: OmnisonicIcons.musicNoteOutline,
          title: 'No tracks found',
          subtitle:
              'This album has no playable tracks on any connected '
              'server.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = _tracks[index];
        return TrackTile(
          track: track,
          showTrackNumber: true,
          serverId: _albumVariants.length > 1 ? track.serverId : null,
          qualityLabel: track.quality.format,
          sourceNote: _sourceNotes?[track.id],
          onTap: () => _onTrackTapped(track, index),
          onMorePressed: () => _showTrackOptions(track),
        );
      }, childCount: _tracks.length),
    );
  }

  // ---------------------------------------------------------------------
  // Desktop track table (SOURCE/FORMAT columns)
  // ---------------------------------------------------------------------

  List<Widget> _buildTrackTableSlivers(BuildContext context) {
    if (_isLoading) {
      return [LoadingStateView.sliver(kind: SkeletonKind.list, itemCount: 6)];
    }

    final error = _errorMessage;
    if (error != null) {
      return [
        SliverToBoxAdapter(
          child: ErrorStateView(
            title: 'Failed to load tracks',
            message: error,
            onRetry: _loadTracks,
          ),
        ),
      ];
    }

    if (_tracks.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: OmnisonicIcons.musicNoteOutline,
            title: 'No tracks found',
            subtitle:
                'This album has no playable tracks on any connected server.',
          ),
        ),
      ];
    }

    return [
      // Pinned, so the column labels stay above the rows you are reading
      // rather than scrolling off with the album header.
      SliverPersistentHeader(
        pinned: true,
        delegate: _TrackTableHeaderDelegate(
          child: _buildTrackTableHeaderRow(context),
        ),
      ),
      SliverList.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) => KeyedSubtree(
          key: ValueKey(_tracks[index].id),
          child: _buildTrackTableRow(context, _tracks[index], index),
        ),
      ),
    ];
  }

  Widget _buildTrackTableHeaderRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget label(String text, {TextAlign? align}) => Text(
      text,
      textAlign: align,
      style: OmnisonicTypography.overline.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.md,
              vertical: OmnisonicSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(width: 32, child: label('#')),
                Expanded(flex: 3, child: label('TITLE')),
                Expanded(flex: 2, child: label('SOURCE')),
                SizedBox(width: 96, child: label('FORMAT')),
                SizedBox(
                  width: 48,
                  child: label('TIME', align: TextAlign.right),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTableRow(BuildContext context, Track track, int index) {
    final scheme = Theme.of(context).colorScheme;
    final note = _sourceNotes?[track.id];
    final showSource = _albumVariants.length > 1;

    return InkWell(
      onTap: () => _onTrackTapped(track, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                style: OmnisonicTypography.metadata.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmnisonicTypography.bodyMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (showSource) ...[
                    ServerDot(serverId: track.serverId, size: 8),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      note ??
                          (showSource ? _serverNameFor(track.serverId) : '—'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OmnisonicTypography.metadata.copyWith(
                        color: note != null
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                        fontStyle: note != null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 96,
              child: Text(
                '${track.quality.format} ${track.quality.bitrate}',
                style: OmnisonicTypography.metadata.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                _formatDuration(track.duration),
                textAlign: TextAlign.right,
                style: OmnisonicTypography.metadata.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(OmnisonicIcons.moreVert, size: 18),
                onPressed: () => _showTrackOptions(track),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Resolution panel (desktop right column)
  // ---------------------------------------------------------------------

  Widget _buildResolutionPanel(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_albumVariants.length > 1) ...[
            _buildSourcePanel(context, Theme.of(context).colorScheme),
            const SizedBox(height: 20),
          ],
          _buildConflictCallouts(context),
          _buildAlsoByArtistGrid(context),
        ],
      ),
    );
  }

  /// Flags tracks whose duration disagrees by more than 2s across sources —
  /// a real signal that two servers likely have different rips/edits of the
  /// same track, derived from the same [_variantTracksCache] used for the
  /// per-track notes.
  List<String> _conflictCallouts() {
    if (_variantTracksCache.length < 2) return const [];

    final byTrackNumber = <int, List<Track>>{};
    for (final tracks in _variantTracksCache.values) {
      for (final track in tracks) {
        final number = track.trackNumber;
        if (number == null) continue;
        byTrackNumber.putIfAbsent(number, () => []).add(track);
      }
    }

    final callouts = <String>[];
    final sortedNumbers = byTrackNumber.keys.toList()..sort();
    for (final number in sortedNumbers) {
      final durations = byTrackNumber[number]!
          .map((t) => t.duration.inSeconds)
          .toList();
      final minSeconds = durations.reduce((a, b) => a < b ? a : b);
      final maxSeconds = durations.reduce((a, b) => a > b ? a : b);
      if (maxSeconds - minSeconds > 2) {
        callouts.add('Track $number differs in length between servers');
      }
    }
    return callouts;
  }

  Widget _buildConflictCallouts(BuildContext context) {
    final callouts = _conflictCallouts();
    if (callouts.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  OmnisonicIcons.warningAmber,
                  size: OmnisonicIconSizes.sm,
                  color: OmnisonicColors.warningAccessible,
                ),
                const SizedBox(width: 6),
                Text(
                  'CONFLICTS',
                  style: OmnisonicTypography.overline.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final callout in callouts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  callout,
                  style: OmnisonicTypography.bodySmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Other albums by the same artist, deduplicated the same way the library
  /// grid is (best copy per title/artist/year group across servers).
  Widget _buildAlsoByArtistGrid(BuildContext context) {
    final libraryViewModel = context.watch<MusicLibraryViewModel>();
    final rawOthers = libraryViewModel.albums
        .where(
          (a) =>
              a.artist == _album.artist &&
              _albumGroupKey(a) != _albumGroupKey(_album),
        )
        .toList();
    if (rawOthers.isEmpty) return const SizedBox.shrink();

    final others = dedupeAlbumsByServer(rawOthers).albums.take(4).toList();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALSO BY ${_album.artist.toUpperCase()}',
          style: OmnisonicTypography.overline.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final album in others)
              SizedBox(
                width: 96,
                child: AlbumCard(
                  album: album,
                  width: 96,
                  showMeta: false,
                  onTap: () {
                    context.pushReplacement(
                      AppRouter.albumDetailLocation(album.id),
                      extra: album,
                    );
                  },
                ),
              ),
          ],
        ),
      ],
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
    double artworkSize, {
    bool includeArtwork = false,
    bool includeSourcePanel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeArtwork) ...[
          _buildAlbumArtwork(context, scheme, 220),
          const SizedBox(height: 16),
        ],
        // Eyebrow states the aggregation up front — this is the one screen
        // where "the same album lives on N servers" is the point.
        Text(
          _albumVariants.length > 1
              ? 'ALBUM · MERGED FROM ${_albumVariants.length} SERVERS'
              : 'ALBUM',
          style: OmnisonicTypography.eyebrow.copyWith(
            fontSize: 10.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _album.title,
          style: OmnisonicTypography.pageTitle.copyWith(
            fontSize: includeArtwork ? 28 : 52,
            fontWeight: OmnisonicTypography.black,
            letterSpacing: includeArtwork ? -0.56 : -1.56,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _album.artist,
          style: OmnisonicTypography.bodyMedium.copyWith(
            fontSize: includeArtwork ? 14 : 15,
            fontWeight: OmnisonicTypography.semiBold,
            color: scheme.onSurface,
          ),
        ),
        if (includeSourcePanel && _albumVariants.length > 1) ...[
          const SizedBox(height: 12),
          _buildSourcePanel(context, scheme),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (_album.year != null)
              _buildMetadataChip(
                context,
                OmnisonicIcons.calendarToday,
                '${_album.year}',
              ),
            if (_album.genre != null)
              _buildMetadataChip(
                context,
                OmnisonicIcons.musicNote,
                _album.genre!,
              ),
            _buildMetadataChip(
              context,
              OmnisonicIcons.queueMusic,
              '${_tracks.length} track${_tracks.length == 1 ? '' : 's'}',
            ),
            if (_tracks.isNotEmpty)
              _buildMetadataChip(
                context,
                OmnisonicIcons.accessTime,
                _formatTotalDuration(_tracks),
              ),
            _buildMetadataChip(
              context,
              OmnisonicIcons.dns,
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
                icon: const Icon(OmnisonicIcons.playArrow),
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
                icon: const Icon(OmnisonicIcons.shuffle),
                label: const Text('Shuffle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _downloadAlbum,
                icon: const Icon(OmnisonicIcons.downloadOutline),
                label: const Text('Download'),
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
    final borderRadius = BorderRadius.circular(OmnisonicRadius.art);
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
                  imageUrl: SubsonicCoverArt.of(_album.coverArtUrl!, 800).url,
                  cacheKey: SubsonicCoverArt.of(
                    _album.coverArtUrl!,
                    800,
                  ).cacheKey,
                  cacheManager: OmnisonicImageCacheManager.instance,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  memCacheHeight: 800,
                  fadeInDuration: const Duration(milliseconds: 120),
                  useOldImageOnUrlChange: true,
                  placeholder: (context, url) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      OmnisonicIcons.album,
                      size: size * 0.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (context, url, error) => coverArtErrorWidget(
                    Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        OmnisonicIcons.album,
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
                    OmnisonicIcons.album,
                    size: size * 0.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }

  /// Best quality found among a variant's cached tracks, or null if that
  /// variant's tracks haven't loaded yet.
  AudioQuality? _bestQualityFor(String albumId) {
    final tracks = _variantTracksCache[albumId];
    if (tracks == null || tracks.isEmpty) return null;
    return tracks
        .map((t) => t.quality)
        .reduce((a, b) => a.qualityScore >= b.qualityScore ? a : b);
  }

  /// The variant with the best overall quality among the sources we've
  /// fetched tracks for so far; null until at least one has loaded.
  Album? get _bestVariant {
    Album? best;
    AudioQuality? bestQuality;
    for (final variant in _albumVariants) {
      final quality = _bestQualityFor(variant.id);
      if (quality == null) continue;
      if (bestQuality == null ||
          quality.qualityScore > bestQuality.qualityScore) {
        best = variant;
        bestQuality = quality;
      }
    }
    return best;
  }

  /// One-line comparison note for [track] against the same track number on
  /// other sources of this album, or null when there's nothing noteworthy
  /// (single source, still loading, or this copy is already the best one).
  /// Recomputes [_sourceNotes] for every track currently on screen.
  void _rebuildSourceNotes() {
    final notes = <String, String>{};
    final serverNames = {
      for (final server in context.read<ServerManagementViewModel>().servers)
        server.id: server.name,
    };
    _serverNames = serverNames;

    for (final track in _tracks) {
      final note = _sourceNoteFor(track, serverNames);
      if (note != null) notes[track.id] = note;
    }

    _sourceNotes = notes;
  }

  String? _sourceNoteFor(Track track, Map<String, String> serverNames) {
    if (_albumVariants.length <= 1 || track.trackNumber == null) return null;

    final matches = <Track>[];
    for (final tracks in _variantTracksCache.values) {
      matches.addAll(tracks.where((t) => t.trackNumber == track.trackNumber));
    }
    if (matches.length <= 1) {
      // Every variant's tracks are in yet and none of them have this track
      // number besides the copy we're looking at.
      if (_variantTracksCache.length < _albumVariants.length) return null;
      return 'Only on ${serverNames[track.serverId] ?? track.serverId}';
    }

    final best = matches.reduce(
      (a, b) => a.quality.qualityScore >= b.quality.qualityScore ? a : b,
    );
    if (best.serverId == track.serverId ||
        best.quality.qualityScore <= track.quality.qualityScore) {
      return null;
    }
    if (best.quality.qualityScore >= AudioQuality.lossless.qualityScore &&
        track.quality.qualityScore < AudioQuality.lossless.qualityScore) {
      return 'Lossless available on '
          '${serverNames[best.serverId] ?? best.serverId}';
    }
    return 'Higher quality on ${serverNames[best.serverId] ?? best.serverId}';
  }

  String _serverNameFor(String serverId) => _serverNames[serverId] ?? serverId;

  Widget _buildSourcePanel(BuildContext context, ColorScheme scheme) {
    final serverViewModel = context.read<ServerManagementViewModel>();
    final serverMap = {
      for (var server in serverViewModel.servers) server.id: server,
    };
    final best = _bestVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSurface(
          borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.xs,
            vertical: OmnisonicSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Text(
                  'SOURCE',
                  style: OmnisonicTypography.overline.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final variant in _albumVariants)
                _buildSourceRow(
                  variant,
                  serverMap[variant.serverId],
                  selected: variant.id == _album.id,
                ),
            ],
          ),
        ),
        if (best != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              best.id == _album.id
                  ? 'Playing from ${_serverNameFor(_album.serverId)} — highest quality available'
                  : 'Playing from ${_serverNameFor(_album.serverId)} — '
                        '${_serverNameFor(best.serverId)} has higher quality',
              style: OmnisonicTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceRow(
    Album variant,
    MusicServer? server, {
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final quality = _bestQualityFor(variant.id);
    final subtitleParts = [
      quality?.toString() ?? '${variant.trackCount ?? 0} tracks',
      if (server != null) server.status.toString(),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(OmnisonicRadius.md),
      onTap: () {
        if (variant.id == _album.id) return;
        setState(() => _album = variant);
        _loadTracks();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            ServerDot(serverId: variant.serverId, size: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server?.name ?? variant.serverId,
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurface,
                      fontWeight: OmnisonicTypography.semiBold,
                    ),
                  ),
                  Text(
                    subtitleParts.join(' · '),
                    style: OmnisonicTypography.metadata.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? OmnisonicIcons.checkCircle
                  : OmnisonicIcons.circleOutline,
              color: selected
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: OmnisonicIconSizes.smd,
            ),
          ],
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
          Icon(
            icon,
            size: OmnisonicIconSizes.sm,
            color: scheme.onSurfaceVariant,
          ),
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

  /// Downloads every track of the album that is not already available
  /// offline. This is the only entry point into DownloadManager from the UI.
  Future<void> _downloadAlbum() async {
    if (_tracks.isEmpty) return;

    final offline = context.read<OfflineModeViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(content: Text('Downloading ${_album.title}…')),
    );

    final failures = await offline.downloadTracks(_tracks);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failures == 0
              ? '${_album.title} is available offline'
              : '$failures of ${_tracks.length} tracks could not be downloaded',
        ),
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
              leading: const Icon(OmnisonicIcons.playArrow),
              title: const Text('Play Now'),
              onTap: () {
                context.pop();
                _onTrackTapped(track, _tracks.indexOf(track));
              },
            ),
            ListTile(
              leading: const Icon(OmnisonicIcons.queueMusic),
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
              leading: const Icon(OmnisonicIcons.playlistAdd),
              title: const Text('Add to Playlist'),
              onTap: () {
                context.pop();
                showAddToPlaylistSheet(context, track);
              },
            ),
            ListTile(
              leading: const Icon(OmnisonicIcons.info),
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

/// Pins the desktop track table's column labels above the rows.
class _TrackTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TrackTableHeaderDelegate({required this.child});

  final Widget child;

  /// The label row is a fixed two-line block: one row of overline text plus
  /// a divider.
  static const double _extent = 33;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: _extent, child: child);

  @override
  bool shouldRebuild(_TrackTableHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
