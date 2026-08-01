import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/offline_mode_view_model.dart';
import '../widgets/offline_indicator.dart';
import '../../../ui/presentation/widgets/track_tile.dart';
import '../../../ui/presentation/widgets/album_card.dart';
import '../../../ui/presentation/widgets/artist_card.dart';
import '../../../ui/presentation/widgets/playlist_card.dart';

/// Page for managing offline mode and viewing offline content
class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  State<OfflineModePage> createState() => _OfflineModePageState();
}

class _OfflineModePageState extends State<OfflineModePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode'),
        actions: [
          Consumer<OfflineModeViewModel>(
            builder: (context, viewModel, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NetworkQualityIndicator(),
                  const SizedBox(width: 8),
                  const OfflineIndicator(showWhenOnline: true),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.refreshOfflineCollection(),
                    tooltip: 'Refresh',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'stats',
                        child: ListTile(
                          leading: Icon(Icons.analytics),
                          title: Text('Statistics'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tracks', icon: Icon(Icons.music_note)),
            Tab(text: 'Albums', icon: Icon(Icons.album)),
            Tab(text: 'Artists', icon: Icon(Icons.person)),
            Tab(text: 'Playlists', icon: Icon(Icons.playlist_play)),
          ],
        ),
      ),
      body: Consumer<OfflineModeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => viewModel.refreshOfflineCollection(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasOfflineContent) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Offline Content',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Download music for offline listening to see it here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Offline mode banner
              const OfflineModeBanner(),

              // Statistics summary
              _buildStatsSummary(context, viewModel),

              // Content tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTracksTab(viewModel),
                    _buildAlbumsTab(viewModel),
                    _buildArtistsTab(viewModel),
                    _buildPlaylistsTab(viewModel),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsSummary(
    BuildContext context,
    OfflineModeViewModel viewModel,
  ) {
    final stats = viewModel.cacheStats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Tracks',
              '${stats.cachedTracks}/${stats.totalTracks}',
              '${stats.trackCachePercentage.toStringAsFixed(1)}%',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Albums',
              '${stats.cachedAlbums}/${stats.totalAlbums}',
              '${stats.albumCachePercentage.toStringAsFixed(1)}%',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Artists',
              '${stats.cachedArtists}/${stats.totalArtists}',
              '${stats.artistCachePercentage.toStringAsFixed(1)}%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String percentage) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          percentage,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildTracksTab(OfflineModeViewModel viewModel) {
    final tracks = viewModel.offlineTracks;

    if (tracks.isEmpty) {
      return const Center(child: Text('No offline tracks available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackTile(
          track: track,
          onTap: () {
            // Handle track tap - play offline track
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab(OfflineModeViewModel viewModel) {
    final albums = viewModel.offlineAlbums;

    if (albums.isEmpty) {
      return const Center(child: Text('No offline albums available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Stack(
          children: [
            AlbumCard(
              album: album,
              onTap: () {
                // Handle album tap - navigate to offline album view
              },
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: OfflineContentBadge(isAvailable: true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArtistsTab(OfflineModeViewModel viewModel) {
    final artists = viewModel.offlineArtists;

    if (artists.isEmpty) {
      return const Center(child: Text('No offline artists available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Stack(
          children: [
            ArtistCard(
              artist: artist,
              onTap: () {
                // Handle artist tap - navigate to offline artist view
              },
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: OfflineContentBadge(isAvailable: true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistsTab(OfflineModeViewModel viewModel) {
    final playlists = viewModel.offlinePlaylists;

    if (playlists.isEmpty) {
      return const Center(child: Text('No offline playlists available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Stack(
          children: [
            PlaylistCard(
              playlist: playlist,
              onTap: () {
                // Handle playlist tap - navigate to offline playlist view
              },
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: OfflineContentBadge(isAvailable: true),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final viewModel = context.read<OfflineModeViewModel>();

    switch (action) {
      case 'stats':
        _showStatsDialog(context, viewModel);
        break;
      case 'settings':
        _showSettingsDialog(context, viewModel);
        break;
    }
  }

  void _showStatsDialog(BuildContext context, OfflineModeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Statistics'),
        content: FutureBuilder<Map<String, dynamic>?>(
          future: viewModel.getOfflineStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Text('Failed to load statistics');
            }

            final stats = snapshot.data!;
            final cacheStats = stats['cacheStats'] as Map<String, dynamic>;
            final collectionStats =
                stats['collectionStats'] as Map<String, dynamic>;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cache Size: ${cacheStats['formattedTotalSize']}'),
                Text('Available: ${cacheStats['formattedAvailableSpace']}'),
                Text('Files: ${cacheStats['fileCount']}'),
                Text(
                  'Usage: ${cacheStats['usagePercentage'].toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
                Text(
                  'Tracks: ${collectionStats['cachedTracks']}/${collectionStats['totalTracks']}',
                ),
                Text(
                  'Albums: ${collectionStats['cachedAlbums']}/${collectionStats['totalAlbums']}',
                ),
                Text(
                  'Artists: ${collectionStats['cachedArtists']}/${collectionStats['totalArtists']}',
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    OfflineModeViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Force Offline Mode'),
              subtitle: const Text('Override network detection'),
              value: viewModel.isOffline,
              onChanged: (value) {
                viewModel.setOfflineMode(value);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
