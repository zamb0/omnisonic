import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/servers/presentation/widgets/server_list_tile.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

void main() {
  for (final size in [TestSizes.phone, TestSizes.tablet]) {
    testWidgets('the stats line starts on the text column (${size.width})', (
      tester,
    ) async {
      // It used to float in the middle of the card, under nothing.
      final server = testServer(name: 'Living Room');
      await pumpPage(
        tester,
        ListView(children: [ServerListTile(server: server, albumCount: 63)]),
        size: size,
      );
      final title = tester.getTopLeft(find.text('Living Room'));
      final stats = tester.getTopLeft(find.text('63 albums'));
      // The stat's icon sits before its label: compare the row's start.
      final statRow = tester.getTopLeft(
        find
            .ancestor(of: find.text('63 albums'), matching: find.byType(Row))
            .first,
      );
      expect(statRow.dx, closeTo(title.dx, 1));
      expect(stats.dy, greaterThan(title.dy));
    });
  }
}
