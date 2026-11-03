import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Skip controls with nowhere to go used to be painted at 0.3 opacity, below
/// Material's disabled range.
void main() {
  testWidgets('skip controls with nowhere to go read as disabled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.playback.emitPlaying(testTrack());

    await pumpShell(
      tester,
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
    );
    await tester.pump();

    for (final label in ['Previous track', 'Next track']) {
      final control = find.byTooltip(label).first;
      expect(
        tester.getSemantics(control),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );

      // The colour the glyph is actually painted in, wherever it came from.
      final glyph = tester.widget<RichText>(
        find.descendant(of: control, matching: find.byType(RichText)),
      );
      expect(glyph.text.style!.color!.a, closeTo(0.38, 0.01));
    }
    handle.dispose();
  });
}
