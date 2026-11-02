import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/download_preferences_service.dart';
import '../../domain/services/offline_content_filter.dart';
import '../viewmodels/offline_mode_view_model.dart';
import '../widgets/offline_indicator.dart';
import '../../../ui/presentation/widgets/widgets.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../../core/utils/formatters.dart';

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
      appBar: PageHeaderAppBar(
        title: 'Downloads',
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
                    icon: const Icon(OmnisonicIcons.refresh),
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
                          leading: Icon(OmnisonicIcons.analytics),
                          title: Text('Statistics'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(OmnisonicIcons.settings),
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
        bottom: PageHeaderAppBar.tabBar(
          context,
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tracks'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: Consumer<OfflineModeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const LoadingStateView(kind: SkeletonKind.list);
          }

          final error = viewModel.errorMessage;
          if (error != null) {
            return ErrorStateView(
              message: error,
              onRetry: viewModel.refreshOfflineCollection,
            );
          }

          if (!viewModel.hasOfflineContent) {
            return const EmptyState(
              icon: OmnisonicIcons.cloudOff,
              title: 'No Offline Content',
              subtitle: 'Download music for offline listening to see it here.',
            );
          }

          return Column(
            children: [
              // Offline mode banner
              const OfflineModeBanner(),

              // Statistics summary
              _buildStatsSummary(context, viewModel),

              if (viewModel.cacheStats != null)
                _buildCacheUsageBar(context, viewModel.cacheStats!),

              _buildWifiOnlyToggle(context),

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  /// Cache usage bar segmented by content type (tracks/albums/artists),
  /// proportioned by real cached-item counts from [OfflineCacheStats].
  Widget _buildCacheUsageBar(BuildContext context, OfflineCacheStats stats) {
    final scheme = Theme.of(context).colorScheme;
    final totalCached =
        stats.cachedTracks + stats.cachedAlbums + stats.cachedArtists;
    if (totalCached == 0) return const SizedBox.shrink();

    final segments = <(String, int, Color)>[
      ('Tracks', stats.cachedTracks, OmnisonicColors.primaryTeal),
      ('Albums', stats.cachedAlbums, OmnisonicColors.primaryPurple),
      ('Artists', stats.cachedArtists, OmnisonicColors.accentPink),
    ].where((s) => s.$2 > 0).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloaded content',
              style: OmnisonicTypography.overline.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(OmnisonicRadius.full),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (final segment in segments)
                      Expanded(
                        flex: segment.$2,
                        child: Container(color: segment.$3),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final segment in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: segment.$3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${segment.$1} (${segment.$2})',
                        style: OmnisonicTypography.metadata.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiOnlyToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AnimatedBuilder(
        animation: DownloadPreferencesService.instance,
        builder: (context, child) {
          final scheme = Theme.of(context).colorScheme;
          return GlassSurface(
            borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Wi-Fi only',
                style: OmnisonicTypography.bodyMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Only download new content on Wi-Fi',
                style: OmnisonicTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: DownloadPreferencesService.instance.wifiOnlyEnabled,
              onChanged: (value) =>
                  DownloadPreferencesService.instance.setWifiOnlyEnabled(value),
            ),
          );
        },
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
        Text(
          label,
          style: TextStyle(fontSize: 12, color: OmnisonicColors.neutralGray600),
        ),
        Text(
          percentage,
          style: TextStyle(fontSize: 11, color: OmnisonicColors.neutralGray600),
        ),
      ],
    );
  }

  Widget _buildTracksTab(OfflineModeViewModel viewModel) {
    final tracks = viewModel.offlineTracks;

    if (tracks.isEmpty) {
      return const EmptyState(
        icon: OmnisonicIcons.musicNoteOutline,
        title: 'No offline tracks',
        subtitle: 'Downloaded tracks appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        void play() => context.read<PlaybackViewModel>().playTrack(
          track,
          queue: tracks,
          startIndex: index,
        );
        return TrackRow(
          key: ValueKey(track.id),
          track: track,
          showAlbum: true,
          onTap: play,
          onShowActions: () => showTrackActions(context, track, onPlay: play),
        );
      },
    );
  }

  Widget _buildAlbumsTab(OfflineModeViewModel viewModel) {
    final albums = viewModel.offlineAlbums;

    if (albums.isEmpty) {
      return const EmptyState(
        icon: OmnisonicIcons.albumOutline,
        title: 'No offline albums',
        subtitle: 'Download an album to listen without a connection.',
      );
    }

    return ResponsiveGridView.media(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      meta: true,
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return AlbumCard(
          album: album,
          badge: const OfflineContentBadge(isAvailable: true, size: 14),
        );
      },
    );
  }

  Widget _buildArtistsTab(OfflineModeViewModel viewModel) {
    final artists = viewModel.offlineArtists;

    if (artists.isEmpty) {
      return const EmptyState(
        icon: OmnisonicIcons.personOutline,
        title: 'No offline artists',
        subtitle: 'Artists appear here once their music is downloaded.',
      );
    }

    return ResponsiveGridView.media(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      subtitle: false,
      meta: true,
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ArtistCard(
          artist: artist,
          badge: const OfflineContentBadge(isAvailable: true, size: 14),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(OfflineModeViewModel viewModel) {
    final playlists = viewModel.offlinePlaylists;

    if (playlists.isEmpty) {
      return const EmptyState(
        icon: OmnisonicIcons.playlistPlay,
        title: 'No offline playlists',
        subtitle: 'Downloaded playlists appear here.',
      );
    }

    return ResponsiveGridView.media(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      meta: true,
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return MediaCard(
          title: playlist.name,
          subtitle: playlist.description?.isNotEmpty == true
              ? playlist.description
              : null,
          meta: pluralize(playlist.trackCount, 'track'),
          imageUrl: playlist.coverArtUrl,
          fallbackIcon: OmnisonicIcons.playlistPlay,
          badge: const OfflineContentBadge(isAvailable: true, size: 14),
          onTap: () =>
              context.push(AppRouter.playlistDetailLocation(playlist.id)),
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
