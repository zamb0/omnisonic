import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #55: the mobile bar was announced twice — once for the bar, once for
/// the track info inside it, with the same label.
void main() {
  testWidgets('the mini player is announced once', (tester) async {
    final handle = tester.ensureSemantics();
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.playback.emitPlaying(testTrack(title: 'Naima'));

    await pumpShell(tester, viewModels: models, settle: false);
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('Now playing: Naima')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the seek bar reads as a time, not a percentage', (tester) async {
    final handle = tester.ensureSemantics();
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.playback.emitPlaying(
      testTrack(duration: const Duration(minutes: 4)),
      position: const Duration(minutes: 1),
    );

    await pumpShell(
      tester,
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
    );
    // The bar slides in; its semantics are off screen until it lands.
    await tester.pump(const Duration(seconds: 1));

    final values = <String>[];
    void walk(SemanticsNode node) {
      if (node.value.isNotEmpty) values.add(node.value);
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(values, contains('1:00 of 4:00'));
    handle.dispose();
  });
}
