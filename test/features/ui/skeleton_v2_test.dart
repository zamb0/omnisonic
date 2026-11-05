import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/widget_harness.dart';

void main() {
  LinearGradient gradient(WidgetTester t) => t
      .widgetList<Container>(
        find.descendant(
          of: find.byType(SkeletonBox),
          matching: find.byType(Container),
        ),
      )
      .map((c) => (c.decoration as BoxDecoration).gradient)
      .whereType<LinearGradient>()
      .first;

  testWidgets('dark: container-highest base, a diagonal 6 % white sheen', (
    t,
  ) async {
    await pumpPage(
      t,
      const Center(child: SkeletonBox(width: 100, height: 40)),
      settle: false,
    );
    final g = gradient(t);
    final scheme = OmnisonicTheme.darkTheme.colorScheme;
    expect(g.begin, Alignment.topLeft);
    expect(g.end, Alignment.bottomRight);
    expect(g.colors.first, scheme.surfaceContainerHighest);
    expect(
      g.colors[1],
      Color.alphaBlend(
        OmnisonicColors.neutralWhite.withValues(alpha: 0.06),
        scheme.surfaceContainerHighest,
      ),
    );
    expect(g.colors.last, scheme.surfaceContainerHighest);
  });

  testWidgets('light: the same ladder rung, a stronger sheen', (t) async {
    await pumpPage(
      t,
      const Center(child: SkeletonBox(width: 100, height: 40)),
      themeMode: ThemeMode.light,
      settle: false,
    );
    final g = gradient(t);
    final scheme = OmnisonicTheme.lightTheme.colorScheme;
    expect(g.colors.first, scheme.surfaceContainerHighest);
    expect(g.colors[1], isNot(g.colors.first));
  });

  testWidgets('the sheen sweeps', (t) async {
    await pumpPage(
      t,
      const Center(child: SkeletonBox(width: 100, height: 40)),
      settle: false,
    );
    final a = gradient(t).stops;
    await t.pump(const Duration(milliseconds: 750));
    expect(gradient(t).stops, isNot(a));
  });

  testWidgets('with reduce motion it holds still', (t) async {
    await pumpPage(
      t,
      const Center(child: SkeletonBox(width: 100, height: 40)),
      settle: false,
      disableAnimations: true,
    );
    final b = gradient(t).stops;
    await t.pump(const Duration(milliseconds: 750));
    expect(gradient(t).stops, b);
  });

  testWidgets('the card skeleton has the real card\'s shapes', (t) async {
    await pumpPage(
      t,
      const Center(child: SkeletonCard(width: 160)),
      settle: false,
      disableAnimations: true,
    );
    final art = t.widgetList<SkeletonBox>(find.byType(SkeletonBox)).first;
    expect(art.width, 160);
    expect(art.height, 160, reason: 'a square cover');
    expect(art.borderRadius, BorderRadius.circular(OmnisonicRadius.art));
  });

  testWidgets('the tile skeleton has a 48 px thumbnail like a TrackRow', (
    t,
  ) async {
    await pumpPage(
      t,
      const SkeletonTile(),
      settle: false,
      disableAnimations: true,
    );
    final thumb = t.widgetList<SkeletonBox>(find.byType(SkeletonBox)).first;
    expect(thumb.width, 48);
    expect(thumb.height, 48);
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: skeletons (${mode.name})', (t) async {
      await pumpPage(
        t,
        Builder(
          builder: (context) => Material(
            color: Theme.of(context).colorScheme.surface,
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SkeletonCard(width: 120),
                      SizedBox(width: 12),
                      SkeletonCard(width: 120),
                      SizedBox(width: 12),
                      SkeletonCard(width: 100),
                    ],
                  ),
                ),
                for (var i = 0; i < 4; i++) const SkeletonTile(),
              ],
            ),
          ),
        ),
        themeMode: mode,
        settle: false,
        disableAnimations: true,
      );
      await t.pump();
      await expectLater(
        find.byType(ListView),
        matchesGoldenFile('goldens/skeleton_v2_${mode.name}.png'),
      );
    });
  }
}
