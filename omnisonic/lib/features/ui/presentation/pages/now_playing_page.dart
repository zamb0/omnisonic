import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/playback_repository.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/routing/app_router.dart';

/// Now Playing page with full playback controls and track information
class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => _closePlayerWithAnimation(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Consumer<PlaybackViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.hasCurrentTrack) {
            return _buildNowPlayingContent(context, viewModel);
          } else {
            return _buildNoTrackContent();
          }
        },
      ),
    );
  }

  Widget _buildNowPlayingContent(BuildContext context, PlaybackViewModel viewModel) {
    final track = viewModel.currentTrack!;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAlbumArt(track),
                const SizedBox(height: 32),
                _buildTrackInfo(track),
                const SizedBox(height: 32),
                _buildProgressSection(context, viewModel),
                const SizedBox(height: 32),
                _buildPlaybackControls(context, viewModel),
                const SizedBox(height: 24),
                _buildSecondaryControls(context, viewModel),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumArt(Track track) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 80,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 80,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[800],
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white54,
                  size: 80,
                ),
              ),
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return Column(
      children: [
        Text(
          track.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          track.artist,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          track.album,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, PlaybackViewModel viewModel) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.grey[600],
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: viewModel.position.inMilliseconds.toDouble(),
            max: viewModel.duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              viewModel.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(viewModel.position),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                _formatDuration(viewModel.duration),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(BuildContext context, PlaybackViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            viewModel.shuffleEnabled ? Icons.shuffle : Icons.shuffle,
            color: viewModel.shuffleEnabled ? Colors.green : Colors.grey[400],
            size: 28,
          ),
          onPressed: () => viewModel.toggleShuffleMode(),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 36,
          ),
          onPressed: viewModel.hasPrevious
              ? () => viewModel.skipToPrevious()
              : null,
        ),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 36,
            ),
            onPressed: () => viewModel.togglePlayPause(),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 36,
          ),
          onPressed: viewModel.hasNext
              ? () => viewModel.skipToNext()
              : null,
        ),
        IconButton(
          icon: Icon(
            _getRepeatIcon(viewModel.repeatMode),
            color: viewModel.repeatMode != RepeatMode.none ? Colors.green : Colors.grey[400],
            size: 28,
          ),
          onPressed: () => viewModel.toggleRepeatMode(),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(BuildContext context, PlaybackViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.favorite_border,
            color: Colors.grey[400],
            size: 24,
          ),
          onPressed: () {
            // TODO: Implement favorite functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Favorite - Coming soon')),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.volume_up,
            color: Colors.grey[400],
            size: 24,
          ),
          onPressed: () => _showVolumeControl(context),
        ),
        IconButton(
          icon: Icon(
            Icons.queue_music,
            color: Colors.grey[400],
            size: 24,
          ),
          onPressed: () => _showQueue(context),
        ),
        IconButton(
          icon: Icon(
            Icons.share,
            color: Colors.grey[400],
            size: 24,
          ),
          onPressed: () {
            // TODO: Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share - Coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoTrackContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Track Playing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a track to start playing',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showMoreOptions(BuildContext context) {
    AnimationUtils.showCustomBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                // TODO: Implement add to playlist
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('Track Info', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                // TODO: Implement track info
              },
            ),
            ListTile(
              leading: const Icon(Icons.equalizer, color: Colors.white),
              title: const Text('Equalizer', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                // TODO: Implement equalizer
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeControl(BuildContext context) {
    AnimationUtils.showCustomDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Volume', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.white),
                Expanded(
                  child: Slider(
                    value: 0.7, // TODO: Get actual volume
                    onChanged: (value) {
                      // TODO: Implement volume control
                    },
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.white),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    AnimationUtils.showCustomBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Queue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 5, // TODO: Get actual queue length
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
                      title: Text(
                        'Track ${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Artist ${index + 1}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () {
                          // TODO: Implement queue item options
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Closes the player with a slide-down animation to match the down arrow
  void _closePlayerWithAnimation(BuildContext context) {
    // Try to pop with GoRouter first (maintains proper routing state)
    if (context.canPop()) {
      context.pop();
    } else {
      // If we can't pop, navigate to home (which will show the mini player)
      context.go(AppRouter.home);
    }
  }
}