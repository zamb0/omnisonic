import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';

/// Mini player widget that appears at the bottom of the screen when music is playing
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackViewModel>(
      builder: (context, viewModel, child) {
        final track = viewModel.currentTrack;

        // Animate mini player appearance/disappearance
        return AnimatedContainer(
          duration: AnimationConstants.standardAnimation,
          curve: AnimationConstants.standardCurve,
          height: viewModel.hasCurrentTrack ? 60 : 0,
          child: AnimatedOpacity(
            duration: AnimationConstants.standardAnimation,
            curve: AnimationConstants.standardCurve,
            opacity: viewModel.hasCurrentTrack ? 1.0 : 0.0,
            child: track != null
                ? _buildMiniPlayerContent(context, track, viewModel)
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayerContent(
    BuildContext context,
    Track track,
    PlaybackViewModel viewModel,
  ) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRouter.nowPlaying),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Album artwork
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[300],
                  ),
                  child: track.coverArtUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: track.coverArtUrl!.withCoverArtSize(96),
                            cacheKey: track.coverArtUrl!
                                .withCoverArtSize(96)
                                .subsonicCacheKey,
                            cacheManager: OmnisonicImageCacheManager.instance,
                            fit: BoxFit.cover,
                            memCacheWidth: 96,
                            memCacheHeight: 96,
                            fadeInDuration: const Duration(milliseconds: 120),
                            useOldImageOnUrlChange: true,
                            placeholder: (context, url) => const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.music_note, color: Colors.grey),
                ),

                const SizedBox(width: 12),

                // Track info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            track.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            track.artist,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous button
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: viewModel.hasPrevious
                          ? viewModel.skipToPrevious
                          : null,
                      iconSize: 24,
                    ),

                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: viewModel.togglePlayPause,
                      iconSize: 28,
                    ),

                    // Next button
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: viewModel.hasNext
                          ? viewModel.skipToNext
                          : null,
                      iconSize: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
