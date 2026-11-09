import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/repositories/playback_repository.dart'
    as playback;
import 'package:omnisonic/features/playback/presentation/widgets/animated_now_playing_bar.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The bar used to slide up from below its own slot — over the nav pills,
/// which had already jumped to make room — and to disappear without any
/// animation, because the build returned an empty box the moment the track
/// was gone.
void main() {
  const idle = playback.PlaybackState(
    isPlaying: false,
    currentTrack: null,
    position: Duration.zero,
    duration: Duration.zero,
    queue: [],
    currentIndex: 0,
    repeatMode: playback.RepeatMode.none,
    shuffleEnabled: false,
    volume: 1.0,
  );

  double barHeight(WidgetTester tester) =>
      tester.getSize(find.byType(AnimatedNowPlayingBar)).height;

  testWidgets('the bar grows in, and its gap with it', (tester) async {
    final models = TestViewModels();
    await pumpShell(tester, viewModels: models, settle: false);
    expect(barHeight(tester), 0, reason: 'no gap above the nav when idle');

    models.playback.emitPlaying(testTrack(title: 'Arriving'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final midway = barHeight(tester);

    await tester.pump(const Duration(milliseconds: 300));
    final settled = barHeight(tester);

    expect(midway, greaterThan(0));
    expect(midway, lessThan(settled));
  });

  testWidgets('the bar collapses showing the last track', (tester) async {
    final models = TestViewModels();
    models.playback.emitPlaying(testTrack(title: 'Leaving'));
    await pumpShell(tester, viewModels: models, settle: false);
    await tester.pump();
    final settled = barHeight(tester);
    expect(settled, greaterThan(0), reason: 'already playing: no entrance');

    models.playback.emitState(idle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(barHeight(tester), inInclusiveRange(1, settled - 1));
    expect(find.text('Leaving'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(barHeight(tester), 0);
    expect(find.text('Leaving'), findsNothing);
  });
}
