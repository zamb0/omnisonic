import 'package:flutter/material.dart';

import '../../../playback/presentation/pages/player_page.dart';
import '../../../playback/presentation/widgets/full_screen_player.dart';

/// Now Playing page with full playback controls and track information
class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key, this.initialPanel});

  final NowPlayingPanel? initialPanel;

  @override
  Widget build(BuildContext context) {
    return PlayerPage(initialPanel: initialPanel);
  }
}
