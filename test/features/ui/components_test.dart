import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/repositories/playback_repository.dart' as repo;
import 'package:omnisonic/features/playback/presentation/widgets/transport_controls.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #60: each shared component, on its own.
void main() {
  group('CoverArt', () {
    testWidgets('shows the placeholder with no URL, at the given size', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const Center(
          child: CoverArt(url: null, size: 48, fallbackIcon: Icons.person),
        ),
        settle: false,
      );
      expect(tester.getSize(find.byType(CoverArt)), const Size(48, 48));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('is excluded from semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        const Center(child: CoverArt(url: null, size: 48)),
        settle: false,
      );
      expect(
        find.descendant(
          of: find.byType(CoverArt),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('TrackRow', () {
    testWidgets('announces title, artist and length as one button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        Material(
          child: TrackRow(
            track: testTrack(title: 'So What', artist: 'Miles Davis'),
            onTap: () {},
          ),
        ),
        settle: false,
      );
      expect(
        find.bySemanticsLabel(RegExp('So What, Miles Davis, 3:24')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('long press, right-click and the more button show actions', (
      tester,
    ) async {
      var shown = 0;
      await pumpPage(
        tester,
        Material(
          child: TrackRow(
            track: testTrack(),
            onTap: () {},
            onShowActions: () => shown++,
          ),
        ),
        settle: false,
      );
      await tester.longPress(find.byType(TrackRow));
      await tester.tap(find.byType(TrackRow), buttons: kSecondaryButton);
      await tester.tap(find.byTooltip('More actions for Test Track'));
      await tester.pump();
      expect(shown, 3);
    });
  });

  testWidgets('StatusChip carries the label, not just a colour', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPage(
      tester,
      const Center(child: StatusChip(status: ServerStatus.offline)),
      settle: false,
    );
    expect(find.text('Offline'), findsOneWidget);
    expect(find.bySemanticsLabel('Status: Offline'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('InlineBanner shows its title, message and action', (
    tester,
  ) async {
    await pumpPage(
      tester,
      Center(
        child: InlineBanner(
          kind: BannerKind.error,
          title: 'Failed',
          message: 'Could not connect.',
          action: TextButton(onPressed: () {}, child: const Text('Retry')),
        ),
      ),
      settle: false,
    );
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Could not connect.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  group('DetailHeader', () {
    Widget header() => SingleChildScrollView(
      child: DetailHeader(
        title: 'A title',
        artwork: const ColoredBox(color: Color(0xFF000000)),
        actions: [
          FilledButton(onPressed: () {}, child: const Text('Play')),
          OutlinedButton(onPressed: () {}, child: const Text('Shuffle')),
          OutlinedButton(onPressed: () {}, child: const Text('Download')),
        ],
      ),
    );

    testWidgets('stacks with the smaller title on a phone', (tester) async {
      await pumpPage(tester, header(), size: const Size(360, 640));
      final title = tester.widget<Text>(find.text('A title'));
      expect(title.style!.fontSize, OmnisonicTypography.sectionTitle.fontSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sits beside the artwork with the hero title when wide', (
      tester,
    ) async {
      await pumpPage(tester, header(), size: TestSizes.desktop);
      final title = tester.widget<Text>(find.text('A title'));
      expect(title.style!.fontSize, OmnisonicTypography.heroTitle.fontSize);
      expect(title.style!.fontSize, 56);
    });

    testWidgets('the wide cover is 240 and sits on the artGlow shadow', (
      tester,
    ) async {
      await pumpPage(
        tester,
        SingleChildScrollView(
          child: DetailHeader(
            title: 'A title',
            tint: const Color(0xFF3366CC),
            artwork: const ColoredBox(
              key: Key('art'),
              color: Color(0xFF000000),
            ),
          ),
        ),
        size: TestSizes.desktop,
      );
      expect(
        tester.getSize(find.byKey(const Key('art'))),
        const Size(240, 240),
      );
      final shadows = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byKey(const Key('art')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => (d.decoration as BoxDecoration).boxShadow)
          .whereType<List<BoxShadow>>()
          .expand((s) => s);
      expect(shadows.single.color.a, closeTo(0.35, 0.01));
      expect(shadows.single.blurRadius, 40);
    });

    testWidgets('a circular artwork gets a round glow', (tester) async {
      await pumpPage(
        tester,
        SingleChildScrollView(
          child: DetailHeader(
            title: 'Artist',
            circularArtwork: true,
            artwork: const ColoredBox(
              key: Key('art'),
              color: Color(0xFF000000),
            ),
          ),
        ),
        size: TestSizes.desktop,
      );
      final round = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byKey(const Key('art')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration as BoxDecoration)
          .any((d) => d.shape == BoxShape.circle && d.boxShadow != null);
      expect(round, isTrue);
    });

    testWidgets('the eyebrow is primary, uppercase', (tester) async {
      await pumpPage(
        tester,
        SingleChildScrollView(
          child: DetailHeader(
            eyebrow: 'Album · 2024',
            title: 'A title',
            artwork: const ColoredBox(color: Color(0xFF000000)),
          ),
        ),
        size: TestSizes.desktop,
      );
      final eyebrow = tester.widget<Text>(find.text('ALBUM · 2024'));
      expect(
        eyebrow.style!.color,
        OmnisonicTheme.darkTheme.colorScheme.primary,
      );
    });

    group('tint wash', () {
      test('adds 15 points of saturation and stays in the canvas band', () {
        const tint = Color(0xFF668899);
        final before = HSLColor.fromColor(tint);
        final dark = HSLColor.fromColor(
          DetailHeader.washColor(tint, isDark: true),
        );
        final light = HSLColor.fromColor(
          DetailHeader.washColor(tint, isDark: false),
        );
        expect(
          dark.saturation,
          closeTo((before.saturation + 0.15).clamp(0, 1), 0.02),
        );
        expect(dark.lightness, lessThanOrEqualTo(0.45 + 0.01));
        expect(light.lightness, greaterThanOrEqualTo(0.7 - 0.01));
      });

      testWidgets('fades from the tint into nothing, full-bleed', (
        tester,
      ) async {
        await pumpPage(
          tester,
          SingleChildScrollView(
            child: DetailHeader(
              title: 'A title',
              tint: const Color(0xFF3366CC),
              artwork: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
          size: TestSizes.desktop,
        );
        final gradient = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(DetailHeader),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.gradient)
            .whereType<LinearGradient>()
            .first;
        expect(
          gradient.colors.first.a,
          closeTo(DetailHeader.washAlphaDark, 0.01),
        );
        expect(gradient.colors.last.a, 0);
      });
    });

    group('title', () {
      testWidgets(
        'a long title takes two lines, ends in an ellipsis and has a tooltip',
        (tester) async {
          const long =
              'An extremely long album title that keeps going and going and going '
              'and cannot possibly fit on two lines at this size no matter what';
          await pumpPage(
            tester,
            SingleChildScrollView(
              child: DetailHeader(
                title: long,
                artwork: const ColoredBox(color: Color(0xFF000000)),
              ),
            ),
            size: TestSizes.desktop,
          );
          final text = tester.widget<Text>(find.text(long));
          expect(text.maxLines, 2);
          expect(text.overflow, TextOverflow.ellipsis);
          expect(find.byTooltip(long), findsOneWidget);
        },
      );

      testWidgets('a short title has no tooltip', (tester) async {
        await pumpPage(tester, header(), size: TestSizes.desktop);
        expect(find.byType(Tooltip), findsNothing);
      });

      testWidgets('the full title stays in the semantics label', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        const long =
            'An extremely long album title that keeps going and going and going '
            'and cannot possibly fit on two lines at this size no matter what';
        await pumpPage(
          tester,
          SingleChildScrollView(
            child: DetailHeader(
              title: long,
              artwork: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
          size: TestSizes.desktop,
        );
        expect(find.bySemanticsLabel(long), findsOneWidget);
        handle.dispose();
      });
    });

    testWidgets('360x640 at 2.0x text: no overflow, long title and all', (
      tester,
    ) async {
      await pumpPage(
        tester,
        SingleChildScrollView(
          child: DetailHeader(
            eyebrow: 'Album · 2024 · merged from 3 servers',
            title: 'A rather long album title that needs to wrap around',
            artwork: const ColoredBox(color: Color(0xFF000000)),
            chips: const [
              MetadataChip(icon: Icons.album, label: '12 tracks'),
              MetadataChip(icon: Icons.schedule, label: '48 min'),
            ],
            actions: [
              AuroraButton(
                label: 'Play',
                icon: Icons.play_arrow,
                onPressed: () {},
              ),
              OmnisonicButton(label: 'Shuffle', onPressed: () {}),
            ],
          ),
        ),
        size: const Size(360, 640),
        textScale: 2.0,
        settle: false,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('showConfirmDialog resolves true only on confirm', (
    tester,
  ) async {
    bool? result;
    await pumpPage(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showConfirmDialog(
            context,
            title: 'Delete?',
            message: 'Gone for good.',
            confirmLabel: 'Delete',
            destructive: true,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  test('repeat modes differ by icon, not only by colour', () {
    final icons = {
      for (final mode in repo.RepeatMode.values)
        PlaybackModeVisuals.repeatIcon(mode),
    };
    expect(icons, hasLength(repo.RepeatMode.values.length));
    expect(
      PlaybackModeVisuals.shuffleIcon(true),
      isNot(PlaybackModeVisuals.shuffleIcon(false)),
    );
  });
}
