import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// docs/design-system.md §9.5: default · hover · live · paused · selected ·
/// unavailable.
void main() {
  Future<TestViewModels> pumpRow(
    WidgetTester tester,
    TrackRow row, {
    TestViewModels? models,
    bool reduce = false,
  }) => pumpPage(
    tester,
    Material(child: row),
    viewModels: models,
    settle: false,
    disableAnimations: reduce,
  );

  /// The row's own fill: the first DecoratedBox under it with a colour.
  Color? fillOf(WidgetTester t) {
    for (final box in t.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(TrackRow),
        matching: find.byType(DecoratedBox),
      ),
    )) {
      final d = box.decoration;
      if (d is BoxDecoration && d.borderRadius != null && d.color != null) {
        return d.color;
      }
    }
    return null;
  }

  TextStyle? titleStyle(WidgetTester t, String title) =>
      t.widget<Text>(find.text(title)).style;

  group('live track', () {
    testWidgets(
      'title is primary, fill is primaryContainer 40 %, bars replace the index',
      (tester) async {
        final track = testTrack(title: 'Live One');
        final models = TestViewModels()..playback.emitPlaying(track);
        await pumpRow(
          tester,
          TrackRow(track: track, leading: TrackRowLeading.trackNumber),
          models: models,
        );
        final scheme = OmnisonicTheme.darkTheme.colorScheme;
        expect(titleStyle(tester, 'Live One')!.color, scheme.primary);
        expect(fillOf(tester), scheme.primaryContainer.withValues(alpha: 0.4));
        expect(find.byType(NowPlayingEqualizer), findsOneWidget);
      },
    );

    testWidgets('is recognisable without colour: semantics say now playing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final track = testTrack(title: 'Live One');
      final models = TestViewModels()..playback.emitPlaying(track);
      await pumpRow(
        tester,
        TrackRow(track: track, onTap: () {}),
        models: models,
      );
      expect(
        find.bySemanticsLabel(RegExp('Live One.*now playing')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('bars move while playing and hold still when paused', (
      tester,
    ) async {
      final track = testTrack(title: 'Live One');
      final models = TestViewModels()..playback.emitPlaying(track);
      await pumpRow(tester, TrackRow(track: track), models: models);

      List<double> heights() => [
        for (final b in tester.widgetList<SizedBox>(
          find.descendant(
            of: find.byType(NowPlayingEqualizer),
            matching: find.byType(SizedBox),
          ),
        ))
          if (b.width == NowPlayingEqualizer.barWidth) b.height!,
      ];

      await tester.pump(const Duration(milliseconds: 100));
      final a = heights();
      await tester.pump(const Duration(milliseconds: 200));
      expect(heights(), isNot(a), reason: 'playing: the bars move');

      models.playback.emitPlaying(track, isPlaying: false);
      await tester.pump();
      final paused = heights();
      await tester.pump(const Duration(milliseconds: 300));
      expect(heights(), paused, reason: 'paused: the bars hold still');
    });

    testWidgets('art leading: bars over a scrim on the thumbnail', (
      tester,
    ) async {
      final track = testTrack();
      final models = TestViewModels()..playback.emitPlaying(track);
      await pumpRow(tester, TrackRow(track: track), models: models);
      expect(
        find.descendant(
          of: find.byType(TrackRow),
          matching: find.byType(NowPlayingEqualizer),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('a track that is not playing has no equalizer and no fill', (
    tester,
  ) async {
    await pumpRow(tester, TrackRow(track: testTrack(), isCurrent: false));
    expect(find.byType(NowPlayingEqualizer), findsNothing);
    expect(fillOf(tester), Colors.transparent);
  });

  testWidgets('hover fills with well, and shows play in the index slot', (
    tester,
  ) async {
    await pumpRow(
      tester,
      TrackRow(
        track: testTrack(trackNumber: 7),
        leading: TrackRowLeading.trackNumber,
        isCurrent: false,
        onTap: () {},
      ),
    );
    expect(find.text('7'), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(TrackRow)));
    await tester.pump();
    expect(fillOf(tester), OmnisonicSurfaces.dark.well);
    expect(find.text('7'), findsNothing);
    expect(find.byIcon(OmnisonicIcons.playArrow), findsOneWidget);
    await mouse.moveTo(const Offset(-50, -50));
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('selected uses wellHover', (tester) async {
    await pumpRow(
      tester,
      TrackRow(track: testTrack(), isCurrent: false, selected: true),
    );
    expect(fillOf(tester), OmnisonicSurfaces.dark.wellHover);
  });

  group('unavailable', () {
    testWidgets('is half opacity, shows cloud-off and explains itself', (
      tester,
    ) async {
      await pumpRow(
        tester,
        TrackRow(
          track: testTrack(),
          isCurrent: false,
          unavailable: true,
          onTap: () {},
        ),
      );
      expect(
        tester
            .widget<Opacity>(
              find
                  .descendant(
                    of: find.byType(TrackRow),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0.5,
      );
      expect(find.byIcon(OmnisonicIcons.cloudOff), findsOneWidget);
      expect(find.byTooltip('Server offline'), findsOneWidget);
    });

    testWidgets('is announced, and still tappable', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpRow(
        tester,
        TrackRow(
          track: testTrack(title: 'Gone'),
          isCurrent: false,
          unavailable: true,
          onTap: () => taps++,
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('Gone.*server offline')),
        findsOneWidget,
      );
      await tester.tap(find.byType(TrackRow));
      expect(taps, 1);
      handle.dispose();
    });
  });

  testWidgets('durations use the tabular timecode style', (tester) async {
    await pumpRow(tester, TrackRow(track: testTrack(), isCurrent: false));
    final style = tester.widget<Text>(find.text('3:24')).style!;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: album list with a live track (${mode.name})', (
      tester,
    ) async {
      final tracks = [
        for (var i = 1; i <= 5; i++)
          testTrack(id: 'server1_$i', title: 'Track $i', trackNumber: i),
      ];
      final models = TestViewModels()
        ..playback.emitPlaying(tracks[1], queue: tracks, currentIndex: 1);
      await pumpPage(
        tester,
        Material(
          color: Colors.transparent,
          child: ListView(
            children: [
              for (var i = 0; i < tracks.length; i++)
                TrackRow(
                  track: tracks[i],
                  leading: TrackRowLeading.trackNumber,
                  qualityLabel: 'FLAC',
                  unavailable: i == 3,
                  selected: i == 2,
                  onTap: () {},
                  onShowActions: () {},
                ),
            ],
          ),
        ),
        viewModels: models,
        themeMode: mode,
        settle: false,
        disableAnimations: true,
      );
      await tester.pump();
      await expectLater(
        find.byType(ListView),
        matchesGoldenFile('goldens/track_list_live_${mode.name}.png'),
      );
    });
  }
}
