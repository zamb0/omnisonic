import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/shell_art_tint.dart';

/// With no cover the background is the Aurora mesh; with one, two washes of
/// its colour. The switcher tweened a single seed colour, which cannot say
/// "no cover", so the first track of a session cut from the mesh to the
/// washes on the first frame, and clearing the queue cut back on the last.
void main() {
  setUp(() => AuroraMesh.driftEnabled = false);

  Future<void> pump(WidgetTester tester, Color? seed) => tester.pumpWidget(
    MaterialApp(
      home: AnimatedTintSwitcher(
        seed: seed,
        child: const SizedBox.expand(),
      ),
    ),
  );

  double meshOpacity(WidgetTester tester) =>
      tester.widget<AuroraMesh>(find.byType(AuroraMesh)).opacity;

  testWidgets('the first cover fades in over the mesh', (tester) async {
    await pump(tester, null);
    expect(meshOpacity(tester), 1);

    await pump(tester, Colors.teal);
    await tester.pump(const Duration(milliseconds: 300));

    expect(meshOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.byType(AuroraMesh), findsNothing);
  });

  testWidgets('losing the cover fades back to the mesh', (tester) async {
    await pump(tester, Colors.teal);
    expect(find.byType(AuroraMesh), findsNothing);

    await pump(tester, null);
    await tester.pump(const Duration(milliseconds: 300));
    expect(meshOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(meshOpacity(tester), 1);
  });

  testWidgets('the content is not remounted by a cross-fade', (tester) async {
    final key = GlobalKey();
    Future<void> pumpWith(Color? seed) => tester.pumpWidget(
      MaterialApp(
        home: AnimatedTintSwitcher(
          seed: seed,
          child: _Probe(key: key),
        ),
      ),
    );
    await pumpWith(null);
    final state = key.currentState;
    await pumpWith(Colors.teal);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(key.currentState, same(state));
  });
}

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
