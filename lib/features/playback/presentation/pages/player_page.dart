import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_router.dart';
import '../../../ui/presentation/widgets/empty_state.dart';
import '../widgets/full_screen_player.dart';

/// Main player page that can be accessed from the now-playing bar.
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, this.initialPanel});

  final NowPlayingPanel? initialPanel;

  @override
  Widget build(BuildContext context) =>
      FullScreenPlayer(initialPanel: initialPanel);
}

/// What the player shows with no track — opened from a deep link, or left
/// open while the queue was cleared.
///
/// It used to have no leading button, so on desktop there was no way out,
/// and a second, differently-worded copy lived in [FullScreenPlayer].
class NothingPlayingView extends StatelessWidget {
  const NothingPlayingView({super.key});

  static void close(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(OmnisonicIcons.close),
          tooltip: 'Close player',
          onPressed: () => close(context),
        ),
      ),
      body: EmptyState(
        icon: OmnisonicIcons.musicNoteOutline,
        title: 'Nothing playing',
        subtitle: 'Pick a track and it will show up here.',
        action: FilledButton.icon(
          onPressed: () => context.go(AppRouter.library),
          icon: const Icon(OmnisonicIcons.libraryMusic),
          label: const Text('Browse library'),
        ),
      ),
    );
  }
}
