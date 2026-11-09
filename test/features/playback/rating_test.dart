import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Rating the playing track from Now Playing.
void main() {
  Future<TestViewModels> pumpPlayer(WidgetTester tester) async {
    final models = TestViewModels();
    models.playback.emitPlaying(testTrack());
    await pumpPage(
      tester,
      const FullScreenPlayer(),
      viewModels: models,
      size: TestSizes.phone,
      settle: false,
      disableAnimations: true,
    );
    await tester.pump(const Duration(milliseconds: 500));
    return models;
  }

  testWidgets('a star rates the playing track', (tester) async {
    final models = await pumpPlayer(tester);

    await tester.tap(find.byTooltip('Rate 4 stars'));
    await tester.pump();

    expect(models.playback.ratingCalls.single.rating, 4);
    final stars = tester.widget<RatingStars>(find.byType(RatingStars));
    expect(stars.rating, 4);
  });

  testWidgets('tapping the current rating clears it', (tester) async {
    final models = await pumpPlayer(tester);
    await tester.tap(find.byTooltip('Rate 3 stars'));
    await tester.pump();

    await tester.tap(find.byTooltip('Clear rating'));
    await tester.pump();

    expect(models.playback.ratingCalls.map((c) => c.rating), [3, 0]);
  });
}
