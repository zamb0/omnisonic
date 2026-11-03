import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';

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
        .widgetList<ListTile>(
          find.descendant(of: list, matching: find.byType(ListTile)),
        )
        .map((tile) => (tile.title as Text?)?.data)
        .toList();

    expect(titles.first, queue[7].title);
    expect(titles, isNot(contains(queue[0].title)));
    expect(titles, hasLength(5)); // tracks 8..12: current plus what follows
  });
}
