import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';
import 'package:provider/provider.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Regression for #66: "Open full queue" pushed the queue, a route inside
/// the shell, from the full-screen player, a route above it. The shell page
/// ended up twice on the root navigator and the build failed on
/// `!keyReservation.contains(key)`.
void main() {
  Future<GoRouter> pumpPlayer(WidgetTester tester, Size size) async {
    final models = TestViewModels();
    final queue = testTracks(4);
    models.playback.emitPlaying(queue[0], queue: queue, currentIndex: 0);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    // Same shape as AppRouter: the queue inside the shell, the player
    // outside it.
    final router = GoRouter(
      initialLocation: AppRouter.home,
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: AppRouter.home,
              builder: (context, state) => const Text('stub:home'),
            ),
            GoRoute(
              path: AppRouter.queue,
              builder: (context, state) => const Text('stub:queue'),
            ),
          ],
        ),
        GoRoute(
          path: AppRouter.nowPlaying,
          builder: (context, state) =>
              const FullScreenPlayer(initialPanel: NowPlayingPanel.queue),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: models.providers,
        child: MaterialApp.router(
          routerConfig: router,
          theme: OmnisonicTheme.lightTheme,
        ),
      ),
    );
    router.push(AppRouter.nowPlaying);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // On a phone the queue panel is a sheet, opened after the player's
    // first frame; let it finish sliding in.
    await tester.pump(const Duration(seconds: 1));
    return router;
  }

  for (final (name, size) in [
    ('phone, queue in a sheet', TestSizes.phone),
    ('desktop, queue inline', TestSizes.desktop),
  ]) {
    testWidgets('opens the queue page ($name)', (tester) async {
      final router = await pumpPlayer(tester, size);

      await tester.tap(find.textContaining('Open full queue'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('stub:queue'), findsOneWidget);
      expect(find.byType(FullScreenPlayer), findsNothing);

      // Back from the queue lands on the page the player was opened from.
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('stub:home'), findsOneWidget);
    });
  }
}
