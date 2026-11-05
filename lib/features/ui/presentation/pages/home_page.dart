import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'dart:math';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../widgets/widgets.dart';
import '../../../servers/presentation/widgets/server_form_dialog.dart';

/// Home page displaying Feishin-style featured content and genres
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.random});

  /// Source of randomness for the "Random Tracks" sample.
  ///
  /// Left null in the app so every launch samples differently. Tests pass a
  /// seeded [Random] so the section renders the same rows every run —
  /// without it a golden of this page can never match twice.
  final Random? random;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Client-side random sample of the full unified collection, refreshed
  /// whenever the underlying track list changes size (a new sync). There's
  /// no server-side "random tracks" endpoint in use, so this mirrors the
  /// existing shuffle-on-tap behaviour rather than a persisted feature.
  List<Track>? _randomTracks;
  int? _randomTracksSourceLength;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MusicLibraryViewModel>().refreshSmartCollections();
      }
    });
  }

  static const int _randomTrackCount = 12;

  List<Track> _randomTracksFrom(List<Track> allTracks) {
    if (_randomTracks != null &&
        _randomTracksSourceLength == allTracks.length) {
      return _randomTracks!;
    }

    // Picking distinct indices rather than copying and shuffling the whole
    // library for twelve rows.
    final random = widget.random ?? Random();
    final picked = <int>{};
    final wanted = min(_randomTrackCount, allTracks.length);
    while (picked.length < wanted) {
      picked.add(random.nextInt(allTracks.length));
    }

    _randomTracks = [for (final index in picked) allTracks[index]];
    _randomTracksSourceLength = allTracks.length;
    return _randomTracks!;
  }

  @override
  Widget build(BuildContext context) {
    final scroll = RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildErrorBanner(),
          _buildOnboardingSection(),
          _buildContinueListeningSection(),
          _buildRandomTracksSection(),
          _buildRecentlyAddedSection(),
          _buildRecentlyPlayedSection(),
          _buildMostPlayedSection(),
          const SliverToBoxAdapter(
            child: SizedBox(height: OmnisonicLayout.pageBottom),
          ),
        ],
      ),
    );

    // The stats rail is the design's second content column. It only appears
    // once the feed beside it can still hold a sensible album row, otherwise
    // both halves end up cramped.
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _statsRailBreakpoint) return scroll;
          // The feed keeps its own right gutter as the gap to the rail; the
          // rail is chrome-like and keeps the chrome inset to the window,
          // lining up with the player bar below it.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: scroll),
              const SizedBox(width: 300, child: LibraryStatsRail()),
              const SizedBox(width: OmnisonicLayout.chromeInset),
            ],
          );
        },
      ),
    );
  }

  static const double _statsRailBreakpoint = 1100;

  Widget _buildAppBar() {
    final gutter = PageGutter.of(context);
    // Same title scale as PageHeaderAppBar, so Home does not shout louder
    // than the tabs beside it.
    final compact =
        MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobile;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          gutter,
          OmnisonicLayout.pageTop(context),
          gutter,
          OmnisonicLayout.headerGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Home',
                style:
                    (compact
                            ? OmnisonicTypography.sectionTitle
                            : OmnisonicTypography.pageTitle)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            _buildServerSummaryLine(),
          ],
        ),
      ),
    );
  }

  /// Compact "N servers · syncing/up to date" line with a colored dot per
  /// connected server, using the same [OmnisonicColors.serverColorFor] hues
  /// as the album/track source badges elsewhere on this page.
  Widget _buildServerSummaryLine() {
    final scheme = Theme.of(context).colorScheme;
    return Consumer2<ServerManagementViewModel, MusicLibraryViewModel>(
      builder: (context, serverViewModel, libraryViewModel, child) {
        final servers = serverViewModel.servers;
        if (servers.isEmpty) {
          return Text(
            'Discover your music',
            style: OmnisonicTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
        }

        final serverWord = servers.length == 1 ? 'server' : 'servers';
        final status = libraryViewModel.isSyncing ? 'syncing…' : 'up to date';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final server in servers.take(6))
              Padding(
                key: ValueKey(server.id),
                padding: const EdgeInsets.only(right: OmnisonicSpacing.xs),
                child: ServerDot(serverId: server.id, size: 8),
              ),
            const SizedBox(width: OmnisonicSpacing.xs),
            Flexible(
              child: Text(
                '${servers.length} $serverWord · $status',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmnisonicTypography.technical.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// "Pick up where you left off" card: the single most recently played track,
  /// presented as a glass panel over its own art. Purely a shortcut into
  /// existing playback — there's no persisted resume position to restore.
  /// What a section shows when it has nothing in it.
  ///
  /// A skeleton while the library is still arriving, and nothing at all
  /// afterwards: an empty "Recently Played" row on a fresh install is noise,
  /// not information. The sections used to return [SizedBox.shrink] in both
  /// cases, so a first sync looked like an app with no content rather than
  /// one that was still working.
  Widget _sectionPlaceholder(MusicLibraryViewModel viewModel, String title) {
    if (!viewModel.isLoading && !viewModel.isSyncing) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const LoadingStateView(kind: SkeletonKind.carousel),
        ],
      ),
    );
  }

  /// Surfaced above the feed rather than replacing it: a failed refresh
  /// should not hide the content that did load.
  Widget _buildErrorBanner() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final message = viewModel.errorMessage;
        if (message == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final gutter = PageGutter.of(context);
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              OmnisonicSpacing.sm,
              gutter,
              OmnisonicSpacing.sm,
            ),
            child: InlineBanner(
              kind: BannerKind.error,
              message: message,
              action: TextButton(
                onPressed: () {
                  viewModel.clearError();
                  _onRefresh();
                },
                child: const Text('Try again'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueListeningSection() {
    return Consumer2<MusicLibraryViewModel, PlaybackViewModel>(
      builder: (context, viewModel, playback, child) {
        final recent = viewModel.recentlyPlayed;
        // The deck first: a restored queue (or whatever is playing now) is
        // where the user left off. The play history lags it, so the card
        // said "Opening" while the mini player showed "Midnight Drive".
        final current = playback.currentTrack;
        if (current == null && recent.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final track = current ?? recent.first;
        final scheme = Theme.of(context).colorScheme;

        final gutter = PageGutter.of(context);
        // Resumes a paused deck; while it plays, opens the player.
        void play() => current != null
            ? playback.isPlaying
                  ? context.push(AppRouter.nowPlaying)
                  : playback.resume()
            : playback.playTrack(track, queue: recent, startIndex: 0);

        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              OmnisonicSpacing.sm,
              gutter,
              0,
            ),
            child: GlassSurface(
              borderRadius: BorderRadius.circular(OmnisonicRadius.overlay),
              child: InkWell(
                borderRadius: BorderRadius.circular(OmnisonicRadius.overlay),
                onTap: play,
                child: Padding(
                  padding: const EdgeInsets.all(OmnisonicSpacing.md),
                  child: Row(
                    children: [
                      CoverArt(
                        url: track.coverArtUrl, seed: track.albumId ?? track.id,
                        size: 64,
                        elevated: true,
                      ),
                      const SizedBox(width: OmnisonicSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (current != null && playback.isPlaying) ...[
                                  const NowPlayingEqualizer(playing: true),
                                  const SizedBox(width: OmnisonicSpacing.sm),
                                ],
                                Flexible(
                                  child: Text(
                                    'PICK UP WHERE YOU LEFT OFF',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: OmnisonicTypography.eyebrow.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: OmnisonicSpacing.xs),
                            Text(
                              track.title,
                              style: OmnisonicTypography.titleMedium.copyWith(
                                color: scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                ServerDot(serverId: track.serverId, size: 6),
                                const SizedBox(
                                  width:
                                      OmnisonicSpacing.xs +
                                      OmnisonicSpacing.xxs,
                                ),
                                Flexible(
                                  child: Text(
                                    '${track.artist} · ${track.quality.displayName}',
                                    style: OmnisonicTypography.bodySmall
                                        .copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: OmnisonicSpacing.sm),
                      // The page's one Aurora control.
                      PlayDisc(
                        onPressed: play,
                        tooltip: current != null && playback.isPlaying
                            ? 'Open player'
                            : 'Play ${track.title}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Horizontal row of tracks drawn at random from the whole aggregated
  /// collection, each tagged with a source-server dot.
  Widget _buildRandomTracksSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.tracks.isEmpty) {
          return _sectionPlaceholder(viewModel, 'Random Tracks');
        }
        final randomTracks = _randomTracksFrom(viewModel.tracks);

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "shuffle all" used to sit here as plain text that looked
              // like an action; it is one now.
              _buildSectionHeader(
                'Random Tracks',
                actionLabel: 'Shuffle all',
                onAction: () => _shuffleAll(viewModel.tracks),
              ),
              SizedBox(
                // Two lines of text in a dense row, at the user's text size.
                height: OmnisonicTextScale.boxExtent(
                  context,
                  fixed: 24,
                  text: 48,
                ),
                child: ScrollConfiguration(
                  behavior: const CarouselScrollBehavior(),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: PageGutter.horizontal(context),
                    itemCount: randomTracks.length,
                    itemBuilder: (context, index) => Padding(
                      // Keyed by track so a reshuffle cannot hand one tile's
                      // state (hover, artwork fade-in) to another track.
                      key: ValueKey(randomTracks[index].id),
                      padding: const EdgeInsets.only(
                        right: OmnisonicSpacing.sm,
                      ),
                      child: _buildTrackTile(randomTracks, index),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackTile(List<Track> queue, int index) {
    final track = queue[index];
    // Playing the whole row, not just this track, so the queue keeps going.
    void play() => context.read<PlaybackViewModel>().playTrack(
      track,
      queue: queue,
      startIndex: index,
    );
    return SizedBox(
      width: 240,
      child: TrackRow(
        track: track,
        dense: true,
        showDuration: false,
        serverId: track.serverId,
        onTap: play,
        onShowActions: () => showTrackActions(context, track, onPlay: play),
      ),
    );
  }

  /// Section heading: an oversized Gabarito title with an optional mono
  /// counter aligned to its baseline. No icon chip — the redesign carries
  /// hierarchy in the type, not in decoration beside it.
  Widget _buildSectionHeader(
    String title, {
    String? meta,
    String? actionLabel,
    VoidCallback? onAction,
  }) => SectionHeader(
    title: title,
    meta: meta,
    size: SectionHeaderSize.large,
    padding: EdgeInsets.fromLTRB(
      PageGutter.of(context),
      OmnisonicLayout.sectionGap(context),
      PageGutter.of(context),
      OmnisonicLayout.headerGap,
    ),
    seeAllLabel: actionLabel ?? 'See all',
    onSeeAllPressed: onAction,
  );

  /// First-run state: with no server configured every section below collapses,
  /// so Home would otherwise be a title over a blank screen.
  Widget _buildOnboardingSection() {
    return Consumer<ServerManagementViewModel>(
      builder: (context, serverViewModel, child) {
        if (serverViewModel.isLoading || serverViewModel.hasServers) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: OmnisonicIcons.dnsOutline,
            title: 'No music server yet',
            subtitle:
                'Add a Subsonic-compatible server to start browsing and '
                'playing your library.',
            // Straight to the form: the Servers list it used to open was
            // empty and had its own "Add server" button, two taps for one.
            action: FilledButton.icon(
              onPressed: () => showServerFormDialog(context),
              icon: const Icon(OmnisonicIcons.add),
              label: const Text('Add server'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentlyAddedSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final albums = viewModel.recentlyAddedAlbums;
        if (albums.isEmpty) {
          return _sectionPlaceholder(viewModel, 'Recently Added');
        }

        return _buildAlbumSection(
          title: 'Recently Added',
          albums: albums,
          meta: 'across all servers',
        );
      },
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final albums = viewModel.recentlyPlayedAlbums;
        if (albums.isEmpty) {
          return _sectionPlaceholder(viewModel, 'Recently Played');
        }

        return _buildAlbumSection(
          title: 'Recently Played',
          albums: albums,
          showServerDots: true,
        );
      },
    );
  }

  Widget _buildMostPlayedSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final albums = viewModel.mostPlayedAlbums;
        if (albums.isEmpty) {
          return _sectionPlaceholder(viewModel, 'Most Played');
        }

        return _buildAlbumSection(title: 'Most Played', albums: albums);
      },
    );
  }

  Widget _buildAlbumSection({
    required String title,
    required List<Album> albums,
    String? meta,
    bool showServerDots = false,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousels show a preview; "See all" leads to the full list.
          _buildSectionHeader(
            title,
            meta: meta,
            onAction: () => context.go('${AppRouter.library}?tab=albums'),
          ),
          SizedBox(
            height: AlbumCard.extentFor(context, 160, showMeta: false),
            child: ScrollConfiguration(
              behavior: const CarouselScrollBehavior(),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                // Starts on the gutter, under the section title, and scrolls
                // out to the edge of the column.
                padding: PageGutter.horizontal(context),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return Padding(
                    key: ValueKey(album.id),
                    padding: const EdgeInsets.only(
                      right: MediaGridPreset.spacing,
                    ),
                    child: _buildAlbumCard(
                      album,
                      showServerDot: showServerDots,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(Album album, {bool showServerDot = false}) =>
      AlbumCard(
        album: album,
        width: 160,
        showMeta: false,
        sourceServerIds: showServerDot ? [album.serverId] : null,
      );

  void _shuffleAll(List<Track> tracks) {
    if (tracks.isEmpty) return;
    final queue = List<Track>.of(tracks)..shuffle();
    context.read<PlaybackViewModel>().playTrack(
      queue.first,
      queue: queue,
      startIndex: 0,
    );
  }

  Future<void> _onRefresh() async {
    final viewModel = context.read<MusicLibraryViewModel>();
    await viewModel.refreshSmartCollections();
  }
}
