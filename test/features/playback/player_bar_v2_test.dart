import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/playback/presentation/widgets/animated_now_playing_bar.dart';
import 'package:omnisonic/features/playback/presentation/widgets/transport_controls.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// docs/design-system.md §9.6: the player bars wear the Aurora signature.
void main() {
  Future<TestViewModels> pumpBar(
    WidgetTester tester, {
    required Size size,
    Duration position = const Duration(seconds: 51),
    bool isPlaying = true,
  }) async {
    final models = TestViewModels();
    final track = testTrack(duration: const Duration(minutes: 3, seconds: 24));
    models.playback.emitPlaying(
      track,
      position: position,
      isPlaying: isPlaying,
    );
    await pumpPage(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedNowPlayingBar(onTap: () {}),
      ),
      viewModels: models,
      size: size,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
    return models;
  }

  group('mini player (phone)', () {
    testWidgets('has a 44 PlayDisc and a 2 px Aurora line on the bottom edge', (
      tester,
    ) async {
      await pumpBar(tester, size: TestSizes.phone);
      expect(tester.getSize(find.byType(PlayDisc)), const Size(44, 44));

      final line = find.byType(AuroraProgressLine);
      expect(line, findsOneWidget);
      expect(tester.getSize(line).height, 2);
      final bar = tester.getRect(find.byType(AnimatedNowPlayingBar));
      expect(
        tester.getRect(line).bottom,
        closeTo(bar.bottom, 1),
        reason: 'the progress sits on the bottom edge',
      );
      expect(
        tester.widget<AuroraProgressLine>(line).fraction,
        closeTo(51 / 204, 0.001),
      );
    });

    testWidgets('the glass carries the cover tint at 12 %', (tester) async {
      await pumpBar(tester, size: TestSizes.phone);
      final tints = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(AnimatedNowPlayingBar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(tints.any((b) => (b.color.a - 0.12).abs() < 0.01), isTrue);
    });

    testWidgets('the disc pauses and resumes', (tester) async {
      final models = await pumpBar(tester, size: TestSizes.phone);
      expect(find.byIcon(OmnisonicIcons.pause), findsOneWidget);
      await tester.tap(find.byType(PlayDisc));
      await tester.pump(const Duration(milliseconds: 400));
      expect(models.playback.isPlaying, isFalse);
      expect(find.byIcon(OmnisonicIcons.playArrow), findsWidgets);
    });
  });

  group('transport bar (desktop)', () {
    testWidgets('has a 48 PlayDisc and the Aurora seek bar', (tester) async {
      await pumpBar(tester, size: TestSizes.desktop);
      expect(tester.getSize(find.byType(PlayDisc)), const Size(48, 48));
      expect(find.byType(AuroraProgress), findsOneWidget);
      expect(find.byType(AuroraProgressLine), findsNothing);
    });

    testWidgets('dragging the seek bar changes the label live and seeks once', (
      tester,
    ) async {
      final models = await pumpBar(tester, size: TestSizes.desktop);
      final rect = tester.getRect(find.byType(AuroraProgress));
      final gesture = await tester.startGesture(
        Offset(rect.left + 2, rect.center.dy),
      );
      await gesture.moveTo(
        Offset(rect.left + rect.width * 0.5, rect.center.dy),
      );
      await tester.pump();
      expect(
        find.text('1:42'),
        findsOneWidget,
        reason: 'elapsed follows the finger',
      );
      expect(
        models.playback.playbackState.position,
        const Duration(seconds: 51),
      );
      await gesture.up();
      await tester.pump();
      expect(models.playback.playbackState.position.inSeconds, closeTo(102, 4));
    });
  });

  testWidgets('PlayPauseButton: 64 when prominent, 48 by default', (
    tester,
  ) async {
    final models = TestViewModels();
    models.playback.emitPlaying(testTrack());
    await pumpPage(
      tester,
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayPauseButton(playback: models.playback),
            PlayPauseButton(playback: models.playback, prominent: true),
          ],
        ),
      ),
      viewModels: models,
      settle: false,
    );
    final sizes = tester
        .widgetList<PlayDisc>(find.byType(PlayDisc))
        .map((d) => d.size.diameter);
    expect(sizes, [48, 64]);
  });
}
