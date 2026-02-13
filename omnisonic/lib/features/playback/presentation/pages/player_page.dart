import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../viewmodels/playback_view_model.dart';
import '../widgets/full_screen_player.dart';
import '../widgets/audio_visualizer.dart';

/// Main player page that can be accessed from the now-playing bar
/// 
/// Features:
/// - Full-screen player interface
/// - Audio visualizations
/// - Queue management
/// - Responsive design
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackViewModel>(
      builder: (context, playbackViewModel, child) {
        if (playbackViewModel.currentTrack == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Player'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(
              child: Text(
                'No track playing',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              // Main player interface
              Expanded(
                child: const FullScreenPlayer(),
              ),
              
              // Bottom section with tabs
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Audio visualizer
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OmnisonicSpacing.md,
                        vertical: OmnisonicSpacing.sm,
                      ),
                      child: AudioVisualizer(
                        isPlaying: playbackViewModel.isPlaying,
                        type: AudioVisualizerType.equalizer,
                        height: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.onSurface,
                      unselectedLabelColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.queue_music),
                          text: 'Queue',
                        ),
                        Tab(
                          icon: Icon(Icons.lyrics),
                          text: 'Lyrics',
                        ),
                        Tab(
                          icon: Icon(Icons.equalizer),
                          text: 'Visualizer',
                        ),
                      ],
                    ),
                    
                    // Tab content
                    SizedBox(
                      height: 200,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildQueueTab(playbackViewModel),
                          _buildLyricsTab(),
                          _buildVisualizerTab(playbackViewModel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueueTab(PlaybackViewModel playbackViewModel) {
    final queue = playbackViewModel.queue;
    final currentIndex = playbackViewModel.currentIndex;

    if (queue.isEmpty) {
      return const Center(
        child: Text(
          'No tracks in queue',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(OmnisonicSpacing.sm),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final track = queue[index];
        final isCurrentTrack = index == currentIndex;

        return QueueUpdateAnimation(
          queueLength: queue.length,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCurrentTrack
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
              ),
              child: track.coverArtUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: track.coverArtUrl!,
                        cacheKey: track.coverArtUrl!.subsonicCacheKey,
                        fit: BoxFit.cover,
                        maxWidthDiskCache: 80,
                        maxHeightDiskCache: 80,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          return const Icon(
                            Icons.music_note,
                            color: Colors.white70,
                            size: 20,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.music_note,
                      color: Colors.white70,
                      size: 20,
                    ),
            ),
            title: Text(
              track.title,
              style: TextStyle(
                color: isCurrentTrack
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isCurrentTrack
                ? Icon(
                    playbackViewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              playbackViewModel.jumpToTrack(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildLyricsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lyrics,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: OmnisonicSpacing.md),
          Text(
            'Lyrics not available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: OmnisonicSpacing.sm),
          Text(
            'Lyrics support coming soon',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerTab(PlaybackViewModel playbackViewModel) {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      child: Column(
        children: [
          // Waveform visualizer
          Expanded(
            child: AudioVisualizer(
              isPlaying: playbackViewModel.isPlaying,
              type: AudioVisualizerType.waveform,
              height: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: OmnisonicSpacing.md),
          
          // Circular visualizer
          AudioVisualizer(
            isPlaying: playbackViewModel.isPlaying,
            type: AudioVisualizerType.circular,
            height: 100,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}