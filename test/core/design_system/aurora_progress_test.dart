import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
  theme: OmnisonicTheme.darkTheme,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
    child: w!,
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

void main() {
  const total = Duration(minutes: 4);

  AuroraProgress bar({
    Duration position = const Duration(minutes: 1),
    Duration duration = total,
    ValueChanged<Duration>? onSeek,
    ValueChanged<Duration?>? onChanged,
  }) => AuroraProgress(
    position: position,
    duration: duration,
    onSeek: onSeek ?? (_) {},
    onChanged: onChanged,
  );

  Size paintSize(WidgetTester t) => t.getSize(
    find
        .descendant(
          of: find.byType(AuroraProgress),
          matching: find.byType(CustomPaint),
        )
        .first,
  );

  testWidgets('a tap seeks to that point, once', (t) async {
    final seeks = <Duration>[];
    await t.pumpWidget(_host(bar(onSeek: seeks.add)));
    final rect = t.getRect(find.byType(AuroraProgress));
    await t.tapAt(Offset(rect.left + rect.width * 0.5, rect.center.dy));
    expect(seeks, [const Duration(minutes: 2)]);
  });

  testWidgets('a drag reports positions live and commits only on release', (
    t,
  ) async {
    final seeks = <Duration>[];
    final live = <Duration?>[];
    await t.pumpWidget(_host(bar(onSeek: seeks.add, onChanged: live.add)));
    final rect = t.getRect(find.byType(AuroraProgress));
    final gesture = await t.startGesture(
      Offset(rect.left + 10, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + rect.width * 0.25, rect.center.dy));
    await gesture.moveTo(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await t.pump();
    expect(seeks, isEmpty, reason: 'no seek while dragging');
    expect(live.whereType<Duration>(), isNotEmpty);
    await gesture.up();
    await t.pump();
    expect(seeks, hasLength(1));
    expect(seeks.single.inSeconds, closeTo(180, 8));
    expect(live.last, isNull, reason: 'the drag is announced as over');
  });

  group('keyboard', () {
    testWidgets('arrows seek 5 s either way', (t) async {
      final seeks = <Duration>[];
      await t.pumpWidget(_host(bar(onSeek: seeks.add)));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(seeks, [
        const Duration(minutes: 1, seconds: 5),
        const Duration(seconds: 55),
      ]);
    });

    testWidgets('seeking never leaves 0..duration', (t) async {
      final seeks = <Duration>[];
      await t.pumpWidget(
        _host(bar(position: const Duration(seconds: 2), onSeek: seeks.add)),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(seeks.single, Duration.zero);

      seeks.clear();
      await t.pumpWidget(
        _host(
          bar(position: total - const Duration(seconds: 2), onSeek: seeks.add),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(seeks.single, total);
    });
  });

  testWidgets(
    'screen readers get a slider reading "1:00 of 4:00" with actions',
    (t) async {
      final handle = t.ensureSemantics();
      final seeks = <Duration>[];
      await t.pumpWidget(_host(bar(onSeek: seeks.add)));
      final data = t.getSemantics(find.byType(AuroraProgress));
      expect(data.value, '1:00 of 4:00');
      expect(data.label, 'Seek');
      expect(data.flagsCollection.isSlider, isTrue);
      t.semantics.increase(find.semantics.byLabel('Seek'));
      t.semantics.decrease(find.semantics.byLabel('Seek'));
      expect(seeks, [
        const Duration(minutes: 1, seconds: 5),
        const Duration(seconds: 55),
      ]);
      handle.dispose();
    },
  );

  testWidgets('with no duration it is inert', (t) async {
    final seeks = <Duration>[];
    await t.pumpWidget(_host(bar(duration: Duration.zero, onSeek: seeks.add)));
    await t.tapAt(t.getCenter(find.byType(AuroraProgress)));
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(seeks, isEmpty);
  });

  testWidgets('hover grows the track 4 -> 6 and shows the thumb', (t) async {
    await t.pumpWidget(_host(bar()));
    CustomPainter painter() => t
        .widget<CustomPaint>(
          find
              .descendant(
                of: find.byType(AuroraProgress),
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .painter!;
    double emphasis() => (painter() as dynamic).emphasis as double;
    expect(emphasis(), 0);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(-10, -10));
    await mouse.moveTo(t.getCenter(find.byType(AuroraProgress)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(emphasis(), 1);
    expect(paintSize(t).height, AuroraProgress.hitHeight);
    await mouse.moveTo(const Offset(-10, -10));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(emphasis(), 0);
  });

  test('the spec dimensions', () {
    expect(AuroraProgress.trackHeight, 4);
    expect(AuroraProgress.trackHeightActive, 6);
    expect(AuroraProgress.thumbDiameter, 14);
    expect(AuroraProgress.step, const Duration(seconds: 5));
  });
}
