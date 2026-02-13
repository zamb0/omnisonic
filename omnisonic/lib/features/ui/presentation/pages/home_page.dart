import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../../core/entities/entities.dart';

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
            _buildFeaturedAlbumsSection(),
            _buildRecentAlbumsSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedAlbumsSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        final albums = viewModel.albums.take(10).toList();
        if (albums.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 330,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildFeaturedAlbumCard(album),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedAlbumCard(Album album) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _HoverAlbumCard(
          album: album,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getColorForAlbum(album).withOpacity(0.15),
                    scheme.surface,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title at top
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Text(
                      album.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                        maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Album artwork
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _buildAlbumArtwork(album),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Artist and genre/year
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          album.artist,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getAlbumMetadata(album),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArtwork(Album album) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: scheme.surfaceVariant,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: album.coverArtUrl != null
            ? Image.network(
                album.coverArtUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
              )
            : _buildPlaceholderArt(),
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

  Color _getColorForAlbum(Album album) {
    final colors = [
      const Color(0xFFC4A942), // Gold
      const Color(0xFFB94A48), // Red
      const Color(0xFF7A7A7A), // Gray
      const Color(0xFF8B6F47), // Brown
      const Color(0xFF5B7C99), // Blue
      const Color(0xFF7B68A6), // Purple
      const Color(0xFF6B9B7D), // Green
    ];
    return colors[album.title.hashCode.abs() % colors.length];
  }

  String _getAlbumMetadata(Album album) {
    final parts = <String>[];
    if (album.genre != null && album.genre!.isNotEmpty) {
      parts.add(album.genre!.toUpperCase());
    }
    if (album.year != null) {
      parts.add(album.year.toString());
    }
    return parts.join(' • ');
  }

  Widget _buildRecentAlbumsSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        // Get albums from recently played tracks
        final recentAlbumIds = <String>{};
        final recentAlbums = <Album>[];
        
        for (final track in viewModel.recentlyPlayed) {
          final albumId = track.albumId;
          if (albumId != null && !recentAlbumIds.contains(albumId)) {
            final album = viewModel.albums.where((a) => a.id == albumId).firstOrNull;
            if (album != null) {
              recentAlbumIds.add(albumId);
              recentAlbums.add(album);
            }
          }
        }

        if (recentAlbums.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Most played',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: View more
                      },
                      child: Text(
                        'View more',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recentAlbums.take(10).length,
                  itemBuilder: (context, index) {
                    final album = recentAlbums[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildMostPlayedAlbumCard(album),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMostPlayedAlbumCard(Album album) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _HoverAlbumCard(
          album: album,
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: scheme.surfaceVariant,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: album.coverArtUrl != null
                          ? Image.network(
                              album.coverArtUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
                            )
                          : _buildPlaceholderArt(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
    this.compact = false,
  });

  final Album album;
  final Widget child;
  final bool compact;

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
                    borderRadius: BorderRadius.circular(widget.compact ? 6 : 8),
                    color: Colors.black.withOpacity(0.5),
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
