import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

/// Lists and grids mount their placeholders lazily, a few per frame as they
/// scroll in. Each box's sweep started at zero on its own mount, so
/// neighbouring boxes shimmered out of step.
void main() {
  List<double> stopsOf(WidgetTester tester, Key key) {
    final container = tester.widget<Container>(
      find.descendant(of: find.byKey(key), matching: find.byType(Container)),
    );
    final gradient = (container.decoration! as BoxDecoration).gradient!;
    return (gradient as LinearGradient).stops!;
  }

  testWidgets('a box mounted later sweeps in step with the others', (
    tester,
  ) async {
    const first = Key('first');
    const second = Key('second');
    Widget build({required bool both}) => MaterialApp(
      home: Column(
        children: [
          const SkeletonBox(key: first, width: 100, height: 20),
          if (both) const SkeletonBox(key: second, width: 100, height: 20),
        ],
      ),
    );

    await tester.pumpWidget(build(both: false));
    // Far enough into the sweep that the band is on the box, not clamped
    // off its start.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(build(both: true));
    await tester.pump(const Duration(milliseconds: 16));

    expect(stopsOf(tester, second), stopsOf(tester, first));
  });
}
