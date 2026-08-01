import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'dart:math';
import 'dart:ui';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cover_palette_service.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../../core/utils/animation_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/server_dot.dart';

/// Home page displaying Feishin-style featured content and genres
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Ambient background tint sampled from whatever cover art Home is
  /// currently showing most prominently, used for the blurred background
  /// blob. Null until extraction finishes or if there's no artwork yet.
  Color? _blobTint;
  String? _blobSourceUrl;

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

  void _updateBlobTint(String? coverArtUrl) {
    if (coverArtUrl == _blobSourceUrl) return;
    _blobSourceUrl = coverArtUrl;
    CoverPaletteService.instance.extractColor(coverArtUrl).then((color) {
      if (mounted && _blobSourceUrl == coverArtUrl) {
        setState(() => _blobTint = color);
      }
    });
  }

  List<Track> _randomTracksFrom(List<Track> allTracks) {
    if (_randomTracks == null ||
        _randomTracksSourceLength != allTracks.length) {
      final shuffled = List<Track>.from(allTracks)..shuffle(Random());
      _randomTracks = shuffled.take(12).toList();
      _randomTracksSourceLength = allTracks.length;
    }
    return _randomTracks!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackgroundBlob()),
          RefreshIndicator(
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
          ),
        ],
      ),
    );
  }

  /// Large, softly blurred tint blob behind the whole page, sampled from the
  /// most recently played track's cover art. Purely decorative — ignores
  /// pointer events so it never intercepts taps meant for the content above.
  Widget _buildBackgroundBlob() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final source = viewModel.recentlyPlayedAlbums.isNotEmpty
            ? viewModel.recentlyPlayedAlbums.first.coverArtUrl
            : (viewModel.recentlyAddedAlbums.isNotEmpty
                  ? viewModel.recentlyAddedAlbums.first.coverArtUrl
                  : null);
        _updateBlobTint(source);
        final tint = _blobTint;
        if (tint == null) return const SizedBox.shrink();

        return IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              // Shifts the blob mostly above the visible area so only its
              // soft lower edge shows — Container.margin must be
              // non-negative, so the offset has to happen here instead.
              offset: const Offset(0, -120),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 480,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildServerSummaryLine(),
                ],
              ),
            ),
            // Servers/Downloads/Settings are secondary navigation: the
            // mockup only exposes them via the desktop sidebar, so mobile
            // needs a stand-in entry point rather than three bottom-bar
            // slots it doesn't have room for.
            IconButton(
              icon: const Icon(Icons.more_horiz),
              tooltip: 'More',
              onPressed: () => _showMoreMenu(context),
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

  /// Glass bottom sheet standing in for the secondary-nav destinations the
  /// mockup only exposes via the desktop sidebar (Servers, Downloads,
  /// Settings) — mobile has no room for them in the 4-slot bottom bar.
  void _showMoreMenu(BuildContext context) {
    AnimationUtils.showCustomBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoreMenuItem(
                sheetContext,
                icon: Icons.dns_outlined,
                label: 'Servers',
                route: AppRouter.servers,
              ),
              _buildMoreMenuItem(
                sheetContext,
                icon: Icons.download_outlined,
                label: 'Downloads',
                route: AppRouter.downloads,
              ),
              _buildMoreMenuItem(
                sheetContext,
                icon: Icons.settings_outlined,
                label: 'Settings',
                route: AppRouter.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        GoRouter.of(context).push(route);
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: GlassSurface(
              borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
              padding: const EdgeInsets.all(OmnisonicSpacing.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
                onTap: () => context.read<PlaybackViewModel>().playTrack(
                  track,
                  queue: [track],
                  startIndex: 0,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(OmnisonicRadius.md),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: track.coverArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: track.coverArtUrl!.withCoverArtSize(
                                  128,
                                ),
                                cacheKey: track.coverArtUrl!
                                    .withCoverArtSize(128)
                                    .subsonicCacheKey,
                                cacheManager:
                                    OmnisonicImageCacheManager.instance,
                                fit: BoxFit.cover,
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
                            style: OmnisonicTypography.overline.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.title,
                            style: OmnisonicTypography.titleSmall.copyWith(
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: OmnisonicTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: scheme.onPrimary,
                        size: 22,
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
              _buildSectionHeader('Random Tracks', Icons.shuffle_rounded),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: randomTracks.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildTrackTile(randomTracks[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackTile(Track track) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(OmnisonicRadius.md),
        onTap: () => context.read<PlaybackViewModel>().playTrack(
          track,
          queue: [track],
          startIndex: 0,
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
                              imageUrl: track.coverArtUrl!.withCoverArtSize(88),
                              cacheKey: track.coverArtUrl!
                                  .withCoverArtSize(88)
                                  .subsonicCacheKey,
                              cacheManager: OmnisonicImageCacheManager.instance,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: OmnisonicTypography.titleLarge.copyWith(
              fontWeight: OmnisonicTypography.bold,
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
          icon: Icons.fiber_new_rounded,
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
          icon: Icons.history_rounded,
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

        return _buildAlbumSection(
          title: 'Most Played',
          albums: albums,
          icon: Icons.trending_up_rounded,
        );
      },
    );
  }

  Widget _buildAlbumSection({
    required String title,
    required List<Album> albums,
    required IconData icon,
    bool showServerDots = false,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, icon),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        borderRadius: BorderRadius.circular(12),
                        color: scheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: album.coverArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: album.coverArtUrl!.withCoverArtSize(
                                  320,
                                ),
                                cacheKey: album.coverArtUrl!
                                    .withCoverArtSize(320)
                                    .subsonicCacheKey,
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
                    if (showServerDot)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: ServerDot(serverId: album.serverId),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                album.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                album.artist,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
        onTap: () => context.push('/album-detail', extra: widget.album),
        child: Stack(
          children: [
            widget.child,
            if (_isHovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
