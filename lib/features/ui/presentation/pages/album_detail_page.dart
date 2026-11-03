import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../offline/presentation/viewmodels/offline_mode_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/app_log.dart';

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

  /// Servers each on-screen track is actually on, keyed by track ID. Every
  /// row used to carry its own copy's dot only, so a track on both servers
  /// looked like it was on one.
  Map<String, List<String>> _trackSources = const {};

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
      // The user may have left while the server was answering.
      if (!mounted) return;

      setState(() {
        _tracks = albumTracks;
        _isLoading = false;
        _variantTracksCache[_album.id] = albumTracks;
        _rebuildSourceNotes();
      });
    } catch (e) {
      AppLog.error('Loading tracks for ${_album.id} failed: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = describeUnexpected(action: "load this album's tracks");
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: OmnisonicTypography.bold,
                  ),
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
                          _buildHeader(context, desktop: true),
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
      leading: BackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.library);
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: OmnisonicTypography.bold,
          ),
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
        return TrackRow(
          key: ValueKey(track.id),
          track: track,
          leading: TrackRowLeading.trackNumber,
          sourceServerIds: _albumVariants.length > 1
              ? _trackSources[track.id] ?? [track.serverId]
              : null,
          qualityLabel: track.quality.format,
          sourceNote: _sourceNotes?[track.id],
          onTap: () => _onTrackTapped(track, index),
          onShowActions: () => _showTrackOptions(track),
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
          extent: _TrackTableHeaderDelegate.extentFor(context),
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

    // Frosted rather than an opaque surface slab: the rows still have to
    // be hidden as they scroll under the pinned labels, but a flat block of
    // `surface` broke the glass backdrop.
    return GlassSurface(
      borderRadius: BorderRadius.zero,
      intensity: GlassIntensity.pill,
      highlight: false,
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
                track.quality.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmnisonicTypography.metadata.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                formatDuration(track.duration),
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
                tooltip: 'More actions for ${track.title}',
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

  Widget _buildAlbumHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: _buildHeader(context),
  );

  /// The album's [DetailHeader]. On desktop it sits in the left column above
  /// the track table, stacked, and the source picker moves to the right
  /// panel.
  Widget _buildHeader(BuildContext context, {bool desktop = false}) {
    final scheme = Theme.of(context).colorScheme;
    final canPlay = _tracks.isNotEmpty;
    final artistId = _album.artistId;

    return DetailHeader(
      forceNarrow: desktop,
      artworkSize: desktop ? 220 : null,
      // Eyebrow states the aggregation up front — this is the one screen
      // where "the same album lives on N servers" is the point.
      eyebrow: _albumVariants.length > 1
          ? 'Album · merged from ${_albumVariants.length} servers'
          : 'Album',
      title: _album.title,
      artwork: LayoutBuilder(
        builder: (context, constraints) =>
            _buildAlbumArtwork(context, scheme, constraints.maxWidth),
      ),
      subtitle: artistId == null
          ? Text(_album.artist)
          : _ArtistLink(
              name: _album.artist,
              onTap: () =>
                  context.push(AppRouter.artistDetailLocation(artistId)),
            ),
      chips: [
        if (_album.year != null)
          MetadataChip(
            icon: OmnisonicIcons.calendarToday,
            label: '${_album.year}',
          ),
        if (_album.genre != null)
          MetadataChip(icon: OmnisonicIcons.musicNote, label: _album.genre!),
        // Not while loading: "0 tracks" there read as an empty album.
        if (!_isLoading)
          MetadataChip(
            icon: OmnisonicIcons.queueMusic,
            label: pluralize(_tracks.length, 'track'),
          ),
        if (_tracks.isNotEmpty)
          MetadataChip(
            icon: OmnisonicIcons.accessTime,
            label: formatTotalDuration(
              _tracks.fold(Duration.zero, (sum, t) => sum + t.duration),
            ),
          ),
        // Merged albums name the server count, with the list on tap: one
        // server's name under a "merged from 2 servers" eyebrow contradicted it.
        if (_albumVariants.length > 1)
          Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            message: [
              for (final variant in _albumVariants)
                _getServerNameForAlbum(context, variant),
            ].join('\n'),
            child: MetadataChip(
              icon: OmnisonicIcons.dns,
              label: '${_albumVariants.length} servers',
            ),
          )
        else
          MetadataChip(
            icon: OmnisonicIcons.dns,
            label: _getServerNameForAlbum(context, _album),
          ),
      ],
      actions: [
        FilledButton.icon(
          onPressed: canPlay ? _playAlbum : null,
          icon: const Icon(OmnisonicIcons.playArrow),
          label: const Text('Play'),
        ),
        OutlinedButton.icon(
          onPressed: canPlay ? _shuffleAlbum : null,
          icon: const Icon(OmnisonicIcons.shuffle),
          label: const Text('Shuffle'),
        ),
        // Icon-only: with a label the third button wrapped onto a row of
        // its own on phones. The app bar has the same action.
        IconButton.outlined(
          onPressed: canPlay ? _downloadAlbum : null,
          tooltip: 'Download album',
          icon: const Icon(OmnisonicIcons.downloadOutline),
        ),
      ],
      below: !desktop && _albumVariants.length > 1
          ? _buildSourcePanel(context, scheme)
          : null,
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
          child: CoverArt(
            url: _album.coverArtUrl,
            radius: 0,
            fallbackIcon: OmnisonicIcons.album,
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

  bool get _variantQualitiesDiffer {
    final scores = {
      for (final variant in _albumVariants)
        _bestQualityFor(variant.id)?.qualityScore,
    }..remove(null);
    return scores.length > 1;
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

    final sources = <String, List<String>>{};
    for (final track in _tracks) {
      final note = _sourceNoteFor(track, serverNames);
      if (note != null) notes[track.id] = note;
      sources[track.id] = _sourcesFor(track);
    }

    _sourceNotes = notes;
    _trackSources = sources;
  }

  List<String> _sourcesFor(Track track) {
    if (track.trackNumber == null) return [track.serverId];
    final serverIds = <String>{track.serverId};
    for (final tracks in _variantTracksCache.values) {
      for (final other in tracks) {
        if (other.trackNumber == track.trackNumber) {
          serverIds.add(other.serverId);
        }
      }
    }
    return serverIds.toList();
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
        // Only when the copies differ: "highest quality available" over two
        // identical MP3 128 copies claimed a choice that was not there.
        if (best != null && _variantQualitiesDiffer) ...[
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

  String _getServerNameForAlbum(BuildContext context, Album album) =>
      context.read<ServerManagementViewModel>().serverNameFor(album.serverId);

  void _playAlbum() {
    if (_tracks.isEmpty) return;
    context.read<PlaybackViewModel>().playTrack(
      _tracks.first,
      queue: _tracks,
      startIndex: 0,
    );
  }

  void _shuffleAlbum() {
    if (_tracks.isEmpty) return;
    final shuffled = List<Track>.of(_tracks)..shuffle();
    context.read<PlaybackViewModel>().playTrack(
      shuffled.first,
      queue: shuffled,
      startIndex: 0,
    );
  }

  /// Downloads every track of the album that is not already available
  /// offline. This is the only entry point into DownloadManager from the UI.
  Future<void> _downloadAlbum() async {
    if (_tracks.isEmpty) return;

    final offline = context.read<OfflineModeViewModel>();
    showFeedback(context, 'Downloading ${_album.title}…');
    final failures = await offline.downloadTracks(_tracks);
    if (!mounted) return;
    showFeedback(
      context,
      failures == 0
          ? '${_album.title} is available offline'
          : "${pluralize(failures, 'track')} of ${_tracks.length} couldn't "
                'be downloaded',
      kind: failures == 0 ? FeedbackKind.success : FeedbackKind.error,
      actionLabel: failures == 0 ? null : 'Retry',
      onAction: failures == 0 ? null : _downloadAlbum,
    );
  }

  void _onTrackTapped(Track track, int index) {
    final playbackViewModel = context.read<PlaybackViewModel>();
    playbackViewModel.playTrack(track, queue: _tracks, startIndex: index);
  }

  void _showTrackOptions(Track track) => showTrackActions(
    context,
    track,
    onPlay: () => _onTrackTapped(track, _tracks.indexOf(track)),
    showGoToAlbum: false,
  );
}

/// Pins the desktop track table's column labels above the rows.
class _TrackTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TrackTableHeaderDelegate({required this.child, required this.extent});

  final Widget child;

  /// One row of overline labels, its padding and a divider, measured at the
  /// current text scale — a fixed 33px clipped the labels at large text.
  final double extent;

  /// The header's height for the current text scale.
  static double extentFor(BuildContext context) =>
      // 2 × 8px padding, a 1px divider and the glass's 2 × 1px border are
      // fixed; the label line (11px at a 1.6 line height, plus rounding
      // slack) scales.
      19 + OmnisonicTextScale.textExtent(context, 19);

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: extent, child: child);

  @override
  bool shouldRebuild(_TrackTableHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.extent != extent;
}

/// The album's artist as a link to their page.
class _ArtistLink extends StatelessWidget {
  const _ArtistLink({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(name),
        ),
      ),
    );
  }
}
