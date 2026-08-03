import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'dart:math';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_stats_rail.dart';
import '../widgets/server_dot.dart';
import 'main_shell.dart';

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
          _buildOnboardingSection(),
          _buildContinueListeningSection(),
          _buildRandomTracksSection(),
          _buildRecentlyAddedSection(),
          _buildRecentlyPlayedSection(),
          _buildMostPlayedSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: scroll),
              const SizedBox(width: 16),
              const SizedBox(width: 300, child: LibraryStatsRail()),
            ],
          );
        },
      ),
    );
  }

  static const double _statsRailBreakpoint = 1100;

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: OmnisonicTypography.pageTitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildServerSummaryLine(),
                ],
              ),
            ),
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
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OmnisonicColors.serverColorFor(server.id),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              '${servers.length} $serverWord · $status',
              style: OmnisonicTypography.metadata.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  /// "Pick up where you left" card: the single most recently played track,
  /// presented as a glass panel over its own art. Purely a shortcut into
  /// existing playback — there's no persisted resume position to restore.
  Widget _buildContinueListeningSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final recent = viewModel.recentlyPlayed;
        if (recent.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final track = recent.first;
        final scheme = Theme.of(context).colorScheme;

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: GlassSurface(
              borderRadius: BorderRadius.circular(OmnisonicRadius.xxl),
              padding: const EdgeInsets.all(OmnisonicSpacing.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(OmnisonicRadius.xxl),
                onTap: () => context.read<PlaybackViewModel>().playTrack(
                  track,
                  queue: recent,
                  startIndex: 0,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(OmnisonicRadius.art),
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: track.coverArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: SubsonicCoverArt.of(
                                  track.coverArtUrl!,
                                  128,
                                ).url,
                                cacheKey: SubsonicCoverArt.of(
                                  track.coverArtUrl!,
                                  128,
                                ).cacheKey,
                                cacheManager:
                                    OmnisonicImageCacheManager.instance,
                                fit: BoxFit.cover,
                                memCacheWidth: 128,
                                memCacheHeight: 128,
                              )
                            : _buildPlaceholderArt(),
                      ),
                    ),
                    const SizedBox(width: OmnisonicSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick up where you left',
                            style: OmnisonicTypography.glassButton.copyWith(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            track.title,
                            style: OmnisonicTypography.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: OmnisonicTypography.bold,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: OmnisonicTypography.bodySmall.copyWith(
                              fontWeight: OmnisonicTypography.medium,
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ServerDot(serverId: track.serverId, size: 6),
                              const SizedBox(width: 6),
                              Text(
                                track.quality.toString(),
                                style: OmnisonicTypography.technical.copyWith(
                                  fontSize: 9.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.onSurface,
                        boxShadow: OmnisonicShadows.artCompact,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: scheme.surface,
                        size: 24,
                      ),
                    ),
                  ],
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
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final randomTracks = _randomTracksFrom(viewModel.tracks);

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Random Tracks', meta: 'shuffle all'),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: randomTracks.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildTrackTile(randomTracks, index),
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(OmnisonicRadius.md),
        // Playing the whole row, not just this track, so the queue keeps going.
        onTap: () => context.read<PlaybackViewModel>().playTrack(
          track,
          queue: queue,
          startIndex: index,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: track.coverArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: SubsonicCoverArt.of(
                                track.coverArtUrl!,
                                88,
                              ).url,
                              cacheKey: SubsonicCoverArt.of(
                                track.coverArtUrl!,
                                88,
                              ).cacheKey,
                              cacheManager: OmnisonicImageCacheManager.instance,
                              memCacheWidth: 88,
                              memCacheHeight: 88,
                              fit: BoxFit.cover,
                            )
                          : _buildPlaceholderArt(),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: ServerDot(serverId: track.serverId),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      style: OmnisonicTypography.bodySmall.copyWith(
                        color: scheme.onSurface,
                        fontWeight: OmnisonicTypography.medium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: OmnisonicTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section heading: an oversized Gabarito title with an optional mono
  /// counter aligned to its baseline. No icon chip — the redesign carries
  /// hierarchy in the type, not in decoration beside it.
  Widget _buildSectionHeader(String title, {String? meta}) {
    final scheme = Theme.of(context).colorScheme;
    final wide = ShellLayout.hasSidebar(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  (wide
                          ? OmnisonicTypography.sectionTitle
                          : OmnisonicTypography.sectionTitleSmall)
                      .copyWith(color: scheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (meta != null)
            Text(
              meta,
              style: OmnisonicTypography.technical.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

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
            icon: Icons.dns_outlined,
            title: 'No music server yet',
            subtitle:
                'Add a Subsonic-compatible server to start browsing and '
                'playing your library.',
            action: FilledButton.icon(
              onPressed: () => context.push(AppRouter.servers),
              icon: const Icon(Icons.add),
              label: const Text('Add a server'),
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
          return const SliverToBoxAdapter(child: SizedBox.shrink());
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
          return const SliverToBoxAdapter(child: SizedBox.shrink());
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
          return const SliverToBoxAdapter(child: SizedBox.shrink());
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
          _buildSectionHeader(title, meta: meta),
          SizedBox(
            height: 244,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _buildAlbumCard(album, showServerDot: showServerDots),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(Album album, {bool showServerDot = false}) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _HoverAlbumCard(
          album: album,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          OmnisonicRadius.art,
                        ),
                        color: scheme.surfaceContainerHighest,
                        boxShadow: OmnisonicShadows.art,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          OmnisonicRadius.art,
                        ),
                        child: album.coverArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: SubsonicCoverArt.of(
                                  album.coverArtUrl!,
                                  320,
                                ).url,
                                cacheKey: SubsonicCoverArt.of(
                                  album.coverArtUrl!,
                                  320,
                                ).cacheKey,
                                cacheManager:
                                    OmnisonicImageCacheManager.instance,
                                fit: BoxFit.cover,
                                memCacheWidth: 320,
                                memCacheHeight: 320,
                                fadeInDuration: const Duration(
                                  milliseconds: 150,
                                ),
                                placeholder: (context, url) =>
                                    _buildPlaceholderArt(),
                                errorWidget: (context, url, error) =>
                                    coverArtErrorWidget(
                                      _buildPlaceholderArt(),
                                      url,
                                      error,
                                    ),
                              )
                            : _buildPlaceholderArt(),
                      ),
                    ),
                    // Source badge sits on a small glass chip rather than
                    // bare on the art, so it stays legible over any cover.
                    if (showServerDot)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: GlassSurface(
                          borderRadius: BorderRadius.circular(9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: ServerDot(serverId: album.serverId, size: 6),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.title,
                style: OmnisonicTypography.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: OmnisonicTypography.bold,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album.artist,
                style: OmnisonicTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: OmnisonicTypography.medium,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.album,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
        size: 48,
      ),
    );
  }

  Future<void> _onRefresh() async {
    final viewModel = context.read<MusicLibraryViewModel>();
    await viewModel.refreshSmartCollections();
  }
}

/// Hover card widget with play button overlay
class _HoverAlbumCard extends StatefulWidget {
  const _HoverAlbumCard({required this.album, required this.child});

  final Album album;
  final Widget child;

  @override
  State<_HoverAlbumCard> createState() => _HoverAlbumCardState();
}

class _HoverAlbumCardState extends State<_HoverAlbumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          AppRouter.albumDetailLocation(widget.album.id),
          extra: widget.album,
        ),
        child: Stack(
          children: [
            widget.child,
            if (_isHovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(OmnisonicRadius.md),
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HoverButton(
                          icon: Icons.shuffle,
                          onPressed: () => _shuffleAlbum(context),
                        ),
                        const SizedBox(width: 8),
                        _HoverButton(
                          icon: Icons.play_arrow,
                          onPressed: () => _playAlbum(context),
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _playAlbum(BuildContext context) {
    final viewModel = context.read<MusicLibraryViewModel>();
    final playback = context.read<PlaybackViewModel>();
    viewModel.getAlbumTracks(widget.album.id).then((tracks) {
      if (tracks.isNotEmpty) {
        playback.playTrack(tracks.first, queue: tracks, startIndex: 0);
      }
    });
  }

  void _shuffleAlbum(BuildContext context) {
    final viewModel = context.read<MusicLibraryViewModel>();
    final playback = context.read<PlaybackViewModel>();
    viewModel.getAlbumTracks(widget.album.id).then((tracks) {
      if (tracks.isNotEmpty) {
        final shuffled = List<Track>.from(tracks)..shuffle();
        playback.playTrack(shuffled.first, queue: shuffled, startIndex: 0);
      }
    });
  }
}

/// Hover button widget
class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(widget.isPrimary ? 24 : 20),
        child: Container(
          width: widget.isPrimary ? 48 : 40,
          height: widget.isPrimary ? 48 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isPrimary
                ? scheme.primary.withValues(alpha: _isHovered ? 1.0 : 0.9)
                : scheme.surfaceContainerHighest.withValues(
                    alpha: _isHovered ? 0.8 : 0.6,
                  ),
          ),
          child: Icon(
            widget.icon,
            color: widget.isPrimary
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
            size: widget.isPrimary ? 28 : 20,
          ),
        ),
      ),
    );
  }
}
