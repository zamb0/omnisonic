import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/playback/data/datasources/handoff_service.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The player bar while another device plays: its track and live progress,
/// clearly not this device's own playback.
void main() {
  RemoteNowPlaying remote({bool playing = true}) {
    final track = testTrack(title: 'Across The Room');
    return RemoteNowPlaying(
      deviceName: 'iPhone',
      track: track,
      queue: [track],
      index: 0,
      playing: playing,
      position: const Duration(seconds: 30),
      duration: track.duration,
      anchor: DateTime.now(),
      live: true,
    );
  }

  Future<TestViewModels> pump(
    WidgetTester tester, {
    required Size size,
    required RemoteNowPlaying playback,
  }) async {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.playback.emitRemoteNowPlaying(playback);
    await pumpShell(
      tester,
      location: AppRouter.home,
      size: size,
      viewModels: models,
      settle: false,
      routes: testShellRoutes(
        builders: {AppRouter.home: (_, _) => const SizedBox.expand()},
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return models;
  }

  testWidgets('on a phone: whose playback it is, and continue here', (
    tester,
  ) async {
    final models = await pump(
      tester,
      size: TestSizes.phone,
      playback: remote(),
    );

    expect(find.text('Playing on iPhone'), findsOneWidget);
    expect(find.text('Across The Room'), findsOneWidget);
    // None of the local transport: this device is not playing.
    expect(find.byTooltip('Next track'), findsNothing);

    await tester.tap(find.byTooltip('Continue here'));
    await tester.pump();

    expect(models.playback.continueRemoteCalls, 1);
  });

  testWidgets('on desktop: the other device\'s clock is shown too', (
    tester,
  ) async {
    await pump(tester, size: TestSizes.desktop, playback: remote());

    expect(find.text('Playing on iPhone'), findsOneWidget);
    expect(find.textContaining('0:3'), findsWidgets);
    expect(find.text('Continue here'), findsOneWidget);
  });

  testWidgets('a pause over there reads as one', (tester) async {
    await pump(tester, size: TestSizes.phone, playback: remote(playing: false));

    expect(find.text('Paused on iPhone'), findsOneWidget);
  });
}
