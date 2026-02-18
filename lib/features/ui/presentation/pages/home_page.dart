import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';

/// Home page displaying Feishin-style featured content and genres
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildRecentlyAddedSection(),
            _buildRecentlyPlayedSection(),
            _buildMostPlayedSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Home',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover your music',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
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
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
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
                  child: _buildAlbumCard(album),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(Album album) {
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.surfaceVariant,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: album.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: album.coverArtUrl!.withCoverArtSize(320),
                            cacheKey: album.coverArtUrl!.withCoverArtSize(320).subsonicCacheKey,
                            cacheManager: OmnisonicImageCacheManager.instance,
                            fit: BoxFit.cover,
                            memCacheWidth: 320,
                            memCacheHeight: 320,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) => _buildPlaceholderArt(),
                            errorWidget: (context, url, error) =>
                                coverArtErrorWidget(_buildPlaceholderArt(), url, error),
                          )
                        : _buildPlaceholderArt(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                album.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                album.artist,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      color: scheme.surfaceVariant,
      child: Icon(
        Icons.album,
        color: scheme.onSurfaceVariant.withOpacity(0.3),
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
  const _HoverAlbumCard({
    required this.album,
    required this.child,
  });

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
                    color: Colors.black.withOpacity(0.6),
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
                        const SizedBox(width: 8),
                        _HoverButton(
                          icon: Icons.more_vert,
                          onPressed: () => _showOptions(context),
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

  void _showOptions(BuildContext context) {
    // TODO: Show album options
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
                ? scheme.primary.withOpacity(_isHovered ? 1.0 : 0.9)
                : scheme.surfaceVariant.withOpacity(_isHovered ? 0.8 : 0.6),
          ),
          child: Icon(
            widget.icon,
            color: widget.isPrimary ? scheme.onPrimary : scheme.onSurfaceVariant,
            size: widget.isPrimary ? 28 : 20,
          ),
        ),
      ),
    );
  }
}
