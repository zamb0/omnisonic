import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// "Pick up where you left off" resumes the loaded deck — at launch, the play
/// queue restored from the server — instead of restarting a recent track.
void main() {
  Future<TestViewModels> pumpHome(
    WidgetTester tester, {
    required void Function(TestViewModels models) arrange,
  }) async {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.library.emitSmartCollections(
      recentlyPlayed: [testTrack(id: 'server1_recent', title: 'Recent Song')],
    );
    arrange(models);

    await pumpPage(
      tester,
      HomePage(),
      viewModels: models,
      size: TestSizes.phone,
      settle: false,
    );
    await tester.pump();
    return models;
  }

  testWidgets('a paused session is resumed where it was left', (tester) async {
    final queue = [
      testTrack(id: 'server1_q1', title: 'Queued One'),
      testTrack(id: 'server1_q2', title: 'Restored Song'),
    ];
    final models = await pumpHome(
      tester,
      arrange: (models) => models.playback.emitPlaying(
        queue[1],
        queue: queue,
        currentIndex: 1,
        isPlaying: false,
        position: const Duration(seconds: 90),
      ),
    );

    expect(find.text('PICK UP WHERE YOU LEFT OFF'), findsOneWidget);
    expect(find.text('Restored Song'), findsWidgets);
    expect(find.text('Recent Song'), findsNothing);

    await tester.tap(find.text('PICK UP WHERE YOU LEFT OFF'));
    await tester.pump();

    // Resumed in place: no new queue, so the saved position survives.
    expect(models.playback.isPlaying, isTrue);
    expect(models.playback.playTrackCalls, isEmpty);
  });

  testWidgets('without a session it falls back to recently played', (
    tester,
  ) async {
    final models = await pumpHome(tester, arrange: (_) {});

    expect(find.text('Recent Song'), findsOneWidget);

    await tester.tap(find.text('PICK UP WHERE YOU LEFT OFF'));
    await tester.pump();

    expect(models.playback.playTrackCalls.single.track.id, 'server1_recent');
  });
}
