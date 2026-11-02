import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The album cards' play and shuffle actions used to live only in a hover
/// overlay, which touch screens never show.
void main() {
  testWidgets('long press offers the hover actions on touch', (tester) async {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.library.emitSmartCollections(recentlyAddedAlbums: testAlbums(3));

    await pumpPage(
      tester,
      HomePage(),
      viewModels: models,
      size: TestSizes.phone,
      settle: false,
    );
    await tester.pump();

    await tester.longPress(find.text('Album 1').first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.widgetWithText(ListTile, 'Play'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Shuffle'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Go to album'), findsOneWidget);
  });

  testWidgets('carousel items are keyed by entity, not position', (
    tester,
  ) async {
    final models = TestViewModels();
    final albums = testAlbums(3);
    models.servers.emitServers([testServer()]);
    models.library.emitSmartCollections(recentlyAddedAlbums: albums);

    await pumpPage(
      tester,
      HomePage(),
      viewModels: models,
      size: TestSizes.phone,
      settle: false,
    );
    await tester.pump();

    expect(find.byKey(ValueKey(albums.first.id)), findsOneWidget);
  });
}
