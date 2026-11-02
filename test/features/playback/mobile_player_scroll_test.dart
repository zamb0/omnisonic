import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The mobile player used to embed a 400px queue/lyrics panel, with its own
/// list, inside the page's scroll view: two scroll regions fighting over
/// every vertical drag.
void main() {
  Future<void> pumpPlayer(
    WidgetTester tester, {
    NowPlayingPanel? initialPanel,
  }) async {
    final models = TestViewModels();
    final queue = testTracks(4);
    models.playback.emitPlaying(queue.first, queue: queue, currentIndex: 0);

    await pumpPage(
      tester,
      FullScreenPlayer(initialPanel: initialPanel),
      viewModels: models,
      size: TestSizes.phone,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the page has a single vertical scroll region', (tester) async {
    await pumpPlayer(tester);

    final vertical = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where((s) => axisDirectionToAxis(s.axisDirection) == Axis.vertical);
    expect(vertical, hasLength(1));
  });

  testWidgets('the panels open in a sheet', (tester) async {
    await pumpPlayer(tester);

    final launcher = find.widgetWithText(OutlinedButton, 'Queue');
    await tester.ensureVisible(launcher);
    await tester.tap(launcher);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(SegmentedButton<NowPlayingPanel>), findsOneWidget);
  });

  testWidgets('opening on a panel shows it straight away', (tester) async {
    await pumpPlayer(tester, initialPanel: NowPlayingPanel.visualizer);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BottomSheet), findsOneWidget);

    // Let the visualizer's staggered start-up timers run out.
    await tester.pump(const Duration(seconds: 5));
  });
}
