import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #56: switching tabs rebuilt Library from scratch, losing the search.
void main() {
  testWidgets('Library keeps its search across a tab switch', (tester) async {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.library.emitCollection(albums: testAlbums(12));

    await pumpShell(
      tester,
      location: AppRouter.library,
      viewModels: models,
      routes: testShellRoutes(
        builders: {AppRouter.library: (context, state) => const LibraryPage()},
      ),
      settle: false,
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Album 1');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('of 12 albums'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(LibraryPage))).go(AppRouter.home);
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsNothing);

    GoRouter.of(
      tester.element(find.text('stub:${AppRouter.home}')),
    ).go(AppRouter.library);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Album 1'), findsOneWidget);
    expect(find.textContaining('of 12 albums'), findsOneWidget);
  });
}
