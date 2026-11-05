import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// docs/design-system.md §9.6, Now Playing.
void main() {
  TestViewModels populated() {
    final models = TestViewModels();
    final queue = testTracks(3);
    models.playback.emitPlaying(
      queue.first,
      queue: queue,
      position: const Duration(seconds: 51),
    );
    return models;
  }

  Future<void> pumpPlayer(WidgetTester t, {Size size = TestSizes.phone}) async {
    await pumpPage(
      t,
      const FullScreenPlayer(),
      viewModels: populated(),
      size: size,
      settle: false,
      disableAnimations: true,
    );
    await t.pump(const Duration(milliseconds: 500));
  }

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('desktop', TestSizes.desktop),
  ]) {
    group(name, () {
      testWidgets('tint background with the Aurora mesh at 30 %', (t) async {
        await pumpPlayer(t, size: size);
        expect(find.byType(ArtTintBackground), findsOneWidget);
        final mesh = t.widget<AuroraMesh>(find.byType(AuroraMesh));
        expect(mesh.opacity, 0.3);
        expect(mesh.brand, OmnisonicBrand.dark);
      });

      testWidgets('the cover is an artHero with the artGlow shadow', (t) async {
        await pumpPlayer(t, size: size);
        final cover = t.widget<CoverArt>(find.byType(CoverArt).first);
        expect(cover.radius, OmnisonicRadius.artHero);
        final glow = t
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.byType(CoverArt).first,
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => (d.decoration as BoxDecoration).boxShadow)
            .whereType<List<BoxShadow>>()
            .any(
              (shadows) => shadows.any(
                (s) => s.blurRadius == 40 && s.offset == const Offset(0, 16),
              ),
            );
        expect(glow, isTrue);
      });

      testWidgets('Aurora seek bar and a 64 PlayDisc', (t) async {
        await pumpPlayer(t, size: size);
        expect(find.byType(AuroraProgress), findsOneWidget);
        expect(
          t.widgetList<PlayDisc>(find.byType(PlayDisc)).map((d) => d.size),
          contains(PlayDiscSize.s64),
        );
        expect(
          find.text('0:51'),
          findsOneWidget,
          reason: 'elapsed in timecode',
        );
      });

      testWidgets('shows the quality as a badge', (t) async {
        await pumpPlayer(t, size: size);
        expect(find.byType(QualityBadge), findsOneWidget);
        expect(find.text('MP3 · High'), findsOneWidget);
      });
    });
  }

  group('QualityBadge', () {
    Future<void> pumpBadge(WidgetTester t, AudioQuality q) =>
        pumpPage(t, Center(child: QualityBadge(quality: q)), settle: false);

    Color edge(WidgetTester t) =>
        ((t
                            .widget<Container>(
                              find.descendant(
                                of: find.byType(QualityBadge),
                                matching: find.byType(Container),
                              ),
                            )
                            .decoration
                        as BoxDecoration)
                    .border
                as Border)
            .top
            .color;

    testWidgets('lossless and ultra take the tertiary edge', (t) async {
      final tertiary = OmnisonicTheme.darkTheme.colorScheme.tertiary;
      for (final q in [AudioQuality.lossless, AudioQuality.ultra]) {
        await pumpBadge(t, q);
        expect(edge(t), tertiary, reason: q.name);
      }
    });

    testWidgets('lossy qualities keep the hairline', (t) async {
      for (final q in [
        AudioQuality.low,
        AudioQuality.medium,
        AudioQuality.high,
      ]) {
        await pumpBadge(t, q);
        expect(edge(t), OmnisonicSurfaces.dark.hairline, reason: q.name);
      }
    });

    testWidgets('uses the mono technical style', (t) async {
      await pumpBadge(t, AudioQuality.lossless);
      expect(
        t.widget<Text>(find.text('FLAC · Lossless')).style!.fontFamily,
        contains('JetBrains'),
      );
    });
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('desktop', TestSizes.desktop),
  ]) {
    testWidgets('golden: Now Playing ($name)', (t) async {
      await pumpPlayer(t, size: size);
      await expectLater(
        find.byType(FullScreenPlayer),
        matchesGoldenFile('goldens/now_playing_$name.png'),
      );
    });
  }
}
