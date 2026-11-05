import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/cover_art.dart';

import '../../helpers/widget_harness.dart';

void main() {
  LinearGradient? gradientOf(WidgetTester t) {
    for (final box in t.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(CoverArt),
        matching: find.byType(DecoratedBox),
      ),
    )) {
      final d = box.decoration;
      if (d is BoxDecoration && d.gradient is LinearGradient) {
        return d.gradient as LinearGradient;
      }
    }
    return null;
  }

  Future<void> pump(WidgetTester t, Widget w) =>
      pumpPage(t, Center(child: w), settle: false);

  testWidgets('the placeholder hue follows the seed', (t) async {
    await pump(t, const CoverArt(url: null, size: 100, seed: 'album-1'));
    final one = gradientOf(t)!;
    await pump(t, const CoverArt(url: null, size: 100, seed: 'album-2'));
    final two = gradientOf(t)!;
    await pump(t, const CoverArt(url: null, size: 100, seed: 'album-1'));
    final again = gradientOf(t)!;

    expect(
      one.colors,
      isNot(two.colors),
      reason: 'different seeds, different hue',
    );
    expect(one.colors, again.colors, reason: 'same seed, same hue');
    for (final c in [...one.colors, ...two.colors]) {
      expect(c.a, 1, reason: 'opaque: a shadow must not show through');
    }
  });

  testWidgets('the placeholder note is at 40 %', (t) async {
    await pump(t, const CoverArt(url: null, size: 100));
    final icon = t.widget<Icon>(find.byType(Icon));
    expect(icon.color!.a, closeTo(0.4, 0.01));
  });

  testWidgets('radius by size: xs, sm, art, then artHero from 200', (t) async {
    double radiusOf(WidgetTester t) =>
        (t
                    .widget<ClipRRect>(
                      find
                          .descendant(
                            of: find.byType(CoverArt),
                            matching: find.byType(ClipRRect),
                          )
                          .first,
                    )
                    .borderRadius
                as BorderRadius)
            .topLeft
            .x;
    for (final (size, expected) in [
      (40.0, OmnisonicRadius.xs),
      (56.0, OmnisonicRadius.sm),
      (120.0, OmnisonicRadius.art),
      (200.0, OmnisonicRadius.artHero),
      (240.0, OmnisonicRadius.artHero),
    ]) {
      await pump(t, CoverArt(url: null, size: size));
      expect(radiusOf(t), expected, reason: '$size px');
    }
  });
}
