import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The TabBar's controller was a DefaultTabController keyed on the active
/// tab, so every `?tab=` change built a new one already at the new index:
/// the underline started sliding on the tap, then snapped into place a frame
/// later.
void main() {
  testWidgets('tapping a tab slides the underline instead of snapping', (
    tester,
  ) async {
    final models = TestViewModels();
    models.library.emitCollection(
      tracks: testTracks(4),
      albums: testAlbums(4),
      artists: testArtists(4),
    );
    await pumpShell(
      tester,
      location: AppRouter.library,
      size: TestSizes.phone,
      viewModels: models,
      routes: testShellRoutes(
        builders: {AppRouter.library: (context, state) => const LibraryPage()},
      ),
    );

    await tester.tap(find.widgetWithText(Tab, 'Artists'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final controller =
        tester.widget<TabBar>(find.byType(TabBar)).controller ??
        DefaultTabController.of(tester.element(find.byType(TabBar)));
    expect(controller.index, 1);
    expect(controller.animation!.value, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(controller.animation!.value, 1);
  });
}
