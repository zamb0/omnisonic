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
import '../../../../core/utils/web_support.dart';
import '../../../../core/entities/entities.dart';

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
    if (!supportsOfflineDownloads) {
      return const Scaffold(
        appBar: PageHeaderAppBar(title: 'Downloads'),
        body: EmptyState(
          icon: OmnisonicIcons.cloudOff,
          title: 'Downloads unavailable',
          subtitle: offlineUnavailableOnWebMessage,
        ),
      );
    }
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
                  const SizedBox(width: OmnisonicSpacing.sm),
                  const OfflineIndicator(showWhenOnline: true),
                  const SizedBox(width: OmnisonicSpacing.sm),
                  IconButton(
                    icon: const Icon(OmnisonicIcons.refresh),
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.refreshOfflineCollection(),
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    icon: const Icon(OmnisonicIcons.analytics),
                    tooltip: 'Storage details',
                    onPressed: () => _showStatsDialog(context, viewModel),
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

          // A header that scrolls away above the tabs: fixed, it left the
          // tab content no room in landscape or at large text sizes.
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const OfflineModeBanner(),
                    if (viewModel.hasOfflineContent) ...[
                      _buildStatsSummary(context, viewModel),
                      if (viewModel.cacheStats != null)
                        _buildCacheUsageBar(context, viewModel.cacheStats!),
                    ],
                    // Shown with nothing downloaded too: that is when it
                    // matters, before the first download.
                    _buildWifiOnlyToggle(context),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTracksTab(viewModel),
                _buildAlbumsTab(viewModel),
                _buildArtistsTab(viewModel),
                _buildPlaylistsTab(viewModel),
              ],
            ),
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
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        OmnisonicSpacing.md,
        PageGutter.of(context),
        OmnisonicSpacing.ms,
      ),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Tracks',
                '${stats.cachedTracks}/${stats.totalTracks}',
                '${stats.trackCachePercentage.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(height: 40, child: VerticalDivider(width: 1)),
            Expanded(
              child: _buildStatItem(
                'Albums',
                '${stats.cachedAlbums}/${stats.totalAlbums}',
                '${stats.albumCachePercentage.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(height: 40, child: VerticalDivider(width: 1)),
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
      ('Tracks', stats.cachedTracks, scheme.tertiary),
      ('Albums', stats.cachedAlbums, scheme.primary),
      ('Artists', stats.cachedArtists, OmnisonicBrand.of(context).heat),
    ].where((s) => s.$2 > 0).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        0,
        PageGutter.of(context),
        OmnisonicSpacing.ms,
      ),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DOWNLOADED CONTENT',
              style: OmnisonicTypography.eyebrow.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.ms),
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
            const SizedBox(height: OmnisonicSpacing.ms),
            Wrap(
              spacing: OmnisonicSpacing.ms,
              runSpacing: OmnisonicSpacing.xs,
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
                      const SizedBox(
                        width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
                      ),
                      Text(
                        '${segment.$1} (${segment.$2})',
                        style: OmnisonicTypography.technicalSmall.copyWith(
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
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        0,
        PageGutter.of(context),
        OmnisonicSpacing.ms,
      ),
      child: AnimatedBuilder(
        animation: DownloadPreferencesService.instance,
        builder: (context, child) {
          final scheme = Theme.of(context).colorScheme;
          return GlassSurface(
            borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
            padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.xs),
            child: SwitchListTile(
              secondary: Icon(
                OmnisonicIcons.wifi,
                color: scheme.onSurfaceVariant,
              ),
              title: const Text('Wi-Fi only'),
              subtitle: const Text('Only download new content on Wi-Fi'),
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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value downloaded, $percentage',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            value,
            style: OmnisonicTypography.statValue.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: OmnisonicSpacing.xxs),
          Text(
            label,
            style: OmnisonicTypography.labelMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            percentage,
            style: OmnisonicTypography.technicalSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksTab(OfflineModeViewModel viewModel) {
    final tracks = viewModel.offlineTracks;

    if (tracks.isEmpty) {
      return EmptyState(
        icon: OmnisonicIcons.downloadOutline,
        title: 'Nothing downloaded yet',
        subtitle:
            'Use Download on an album, or on any track\'s actions, to keep '
            'it on this device.',
        action: FilledButton(
          onPressed: () => context.go(AppRouter.library),
          child: const Text('Browse library'),
        ),
      );
    }

    // TrackRow lays itself out on the gutter.
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: OmnisonicSpacing.sm,
        bottom: OmnisonicLayout.pageBottom,
      ),
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
          // Downloads could not be removed from here at all, though the
          // view model has always supported it.
          trailing: IconButton(
            icon: const Icon(OmnisonicIcons.delete),
            iconSize: 20,
            tooltip: 'Remove download',
            onPressed: () => _removeDownload(track),
          ),
        );
      },
    );
  }

  Future<void> _removeDownload(Track track) async {
    final error = await context.read<OfflineModeViewModel>().removeDownload(
      track.id,
    );
    if (!mounted) return;
    showFeedback(
      context,
      error ?? 'Removed "${track.title}" from this device',
      kind: error == null ? FeedbackKind.success : FeedbackKind.error,
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
      staggered: true,
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        OmnisonicSpacing.md,
        PageGutter.of(context),
        OmnisonicLayout.pageBottom,
      ),
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
      staggered: true,
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        OmnisonicSpacing.md,
        PageGutter.of(context),
        OmnisonicLayout.pageBottom,
      ),
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
      staggered: true,
      padding: EdgeInsets.fromLTRB(
        PageGutter.of(context),
        OmnisonicSpacing.md,
        PageGutter.of(context),
        OmnisonicLayout.pageBottom,
      ),
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
                const SizedBox(height: OmnisonicSpacing.md),
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
}
