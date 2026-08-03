import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/playback_view_model.dart';
import '../widgets/full_screen_player.dart';
import '../../../../core/design_system/design_system.dart';

/// Main player page that can be accessed from the now-playing bar
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, this.initialPanel});

  final NowPlayingPanel? initialPanel;

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
            body: Center(
              child: Text(
                'No track playing',
                style: OmnisonicTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return FullScreenPlayer(initialPanel: initialPanel);
      },
    );
  }
}
