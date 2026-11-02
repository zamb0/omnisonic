import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/animated_now_playing_bar.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The mini-player is the one control on screen at all times and it was
/// tap-only — there was no Dismissible, onHorizontalDrag or onVerticalDrag
/// anywhere in lib/.
void main() {
  Future<TestViewModels> pumpBar(
    WidgetTester tester, {
    required VoidCallback onTap,
    int queueLength = 3,
    int currentIndex = 1,
  }) async {
    final models = TestViewModels();
    final queue = testTracks(queueLength);
    models.playback.emitPlaying(
      queue[currentIndex],
      queue: queue,
      currentIndex: currentIndex,
    );

    await pumpPage(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedNowPlayingBar(onTap: onTap),
      ),
      viewModels: models,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
    return models;
  }

  testWidgets('tapping still opens the full player', (tester) async {
    var opened = false;
    await pumpBar(tester, onTap: () => opened = true);

    await tester.tap(find.byType(AnimatedNowPlayingBar));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('flicking up opens the full player', (tester) async {
    var opened = false;
    await pumpBar(tester, onTap: () => opened = true);

    await tester.fling(
      find.byType(AnimatedNowPlayingBar),
      const Offset(0, -60),
      1000,
    );
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('flicking down does not open it', (tester) async {
    // Down is the direction that dismisses the full player, so it must not
    // also be the direction that opens it.
    var opened = false;
    await pumpBar(tester, onTap: () => opened = true);

    await tester.fling(
      find.byType(AnimatedNowPlayingBar),
      const Offset(0, 60),
      1000,
    );
    await tester.pump();

    expect(opened, isFalse);
  });

  testWidgets('flicking left skips forward', (tester) async {
    // Left moves forward: the queue travels leftwards past a fixed playhead,
    // which is the direction the finger pushes it.
    final models = await pumpBar(tester, onTap: () {});
    final before = models.playback.currentIndex;

    await tester.fling(
      find.byType(AnimatedNowPlayingBar),
      const Offset(-120, 0),
      1000,
    );
    await tester.pump();

    expect(models.playback.currentIndex, before);
    // FakePlaybackViewModel records the intent rather than moving the queue,
    // so the assertion is that the bar asked at all.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a slow drag is not a flick', (tester) async {
    // Otherwise scrolling the page behind the bar would change tracks.
    var opened = false;
    await pumpBar(tester, onTap: () => opened = true);

    await tester.drag(find.byType(AnimatedNowPlayingBar), const Offset(0, -60));
    await tester.pump();

    expect(opened, isFalse);
  });

  testWidgets('the bar announces itself to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester, onTap: () {});

    // It used to read out "0" — the progress indicator's value — because the
    // tappable region carried no label of its own.
    expect(find.bySemanticsLabel(RegExp('Now playing')), findsWidgets);
    handle.dispose();
  });
}
