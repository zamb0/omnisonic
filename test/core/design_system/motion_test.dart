import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/utils/animation_utils.dart';

void main() {
  test('duration tokens match the spec', () {
    expect(AnimationManager.instantDuration.inMilliseconds, 100);
    expect(AnimationManager.fastDuration.inMilliseconds, 150);
    expect(AnimationManager.quickDuration.inMilliseconds, 200);
    expect(AnimationManager.normalDuration.inMilliseconds, 300);
    expect(AnimationManager.emphasisDuration.inMilliseconds, 450);
    expect(AnimationManager.tintDuration.inMilliseconds, 600);
  });

  test('exit runs at 70% of enter', () {
    expect(
      AnimationManager.exitOf(AnimationManager.emphasisDuration),
      const Duration(milliseconds: 315),
    );
  });

  test('stagger: 40 ms per item, capped at 12 items', () {
    expect(AnimationManager.staggered(0), Duration.zero);
    expect(AnimationManager.staggered(3).inMilliseconds, 120);
    expect(AnimationManager.staggered(11).inMilliseconds, 440);
    expect(AnimationManager.staggered(50).inMilliseconds, 440);
    expect(AnimationManager.staggered(-1), Duration.zero);
  });

  test('spring curve starts at 0, ends at 1, settles close to 1', () {
    const c = AnimationManager.springCurve;
    expect(c.transform(0), 0);
    expect(c.transform(1), 1);
    expect(c.transform(0.5), inInclusiveRange(0.9, 1.1));
    expect(c.transform(0.95), closeTo(1, 0.03));
  });

  testWidgets('adjustedDuration is zero with disableAnimations', (t) async {
    late Duration on, off;
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            on = AnimationUtils.adjustedDuration(
              context,
              AnimationManager.normalDuration,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            off = AnimationUtils.adjustedDuration(
              context,
              AnimationManager.normalDuration,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(on, Duration.zero);
    expect(off, AnimationManager.normalDuration);
  });

  group('PressScale', () {
    double scaleOf(WidgetTester t) =>
        t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    testWidgets('scales to 0.97 on press and back on release', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PressScale(
              child: ColoredBox(
                color: Color(0xFF000000),
                child: SizedBox(width: 50, height: 50),
              ),
            ),
          ),
        ),
      );
      expect(scaleOf(t), 1);
      final g = await t.startGesture(t.getCenter(find.byType(PressScale)));
      await t.pump();
      expect(scaleOf(t), 0.97);
      await g.up();
      await t.pump();
      expect(scaleOf(t), 1);
      await t.pumpAndSettle();
    });

    testWidgets('does not swallow taps of the child', (t) async {
      var taps = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: PressScale(
              child: GestureDetector(
                onTap: () => taps++,
                child: const ColoredBox(
                  color: Color(0xFF000000),
                  child: SizedBox(width: 50, height: 50),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byType(PressScale));
      await t.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('disabled returns the bare child', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: PressScale(enabled: false, child: SizedBox())),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('snaps with reduce motion', (t) async {
      await t.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Center(
              child: PressScale(
                child: ColoredBox(
                  color: Color(0xFF000000),
                  child: SizedBox(width: 50, height: 50),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        t.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero,
      );
    });
  });

  group('Staggered', () {
    Widget host(int index, {bool reduce = false}) => MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Staggered(index: index, child: const Text('x')),
    );

    testWidgets('starts transparent and ends opaque, lifted 8px', (t) async {
      await t.pumpWidget(host(2));
      double opacity() => t.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(opacity(), 0);
      await t.pump(const Duration(milliseconds: 500));
      expect(opacity(), 1);
      await t.pumpAndSettle();
    });

    testWidgets('reduce motion shows the child with no animation', (t) async {
      await t.pumpWidget(host(5, reduce: true));
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('x'), findsOneWidget);
    });
  });
}
