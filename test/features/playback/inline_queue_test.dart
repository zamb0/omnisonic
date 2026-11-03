import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';
import 'package:omnisonic/features/ui/presentation/widgets/track_row.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Regression for #53 point 7: the player's inline queue showed the first six
/// tracks of the queue, most of which had already played.
void main() {
  testWidgets('inline queue starts at the current track', (tester) async {
    final models = TestViewModels();
    final queue = testTracks(12);
    models.playback.emitPlaying(queue[7], queue: queue, currentIndex: 7);

    await pumpPage(
      tester,
      const FullScreenPlayer(initialPanel: NowPlayingPanel.queue),
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));

    final list = find.byType(ListView).last;
    final titles = tester
        .widgetList<TrackRow>(
          find.descendant(of: list, matching: find.byType(TrackRow)),
        )
        .map((row) => row.track.title)
        .toList();

    expect(titles.first, queue[7].title);
    expect(titles, isNot(contains(queue[0].title)));
    expect(titles, hasLength(5)); // tracks 8..12: current plus what follows
  });

  testWidgets('inline queue lists the whole rest of the queue, no link', (
    tester,
  ) async {
    final models = TestViewModels();
    final queue = testTracks(20);
    models.playback.emitPlaying(queue[0], queue: queue, currentIndex: 0);

    await pumpPage(
      tester,
      const FullScreenPlayer(initialPanel: NowPlayingPanel.queue),
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));

    final list = tester.widget<ListView>(find.byType(ListView).last);
    expect(list.childrenDelegate.estimatedChildCount, 20);
    expect(find.textContaining('Open full queue'), findsNothing);
  });
}
