import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// "No screen has a flat canvas when there is no artwork" (#87).
void main() {
  for (final route in [
    AppRouter.home,
    AppRouter.search,
    AppRouter.library,
    AppRouter.favorites,
    AppRouter.servers,
    AppRouter.downloads,
    AppRouter.settings,
  ]) {
    for (final size in [TestSizes.phone, TestSizes.desktop]) {
      testWidgets('$route at ${size.width.round()}px sits on the Aurora mesh', (
        t,
      ) async {
        final models = TestViewModels();
        models.servers.emitServers([testServer()]);
        await pumpShell(t, location: route, size: size, viewModels: models);
        expect(find.byType(AuroraMesh), findsWidgets);
      });
    }
  }

  testWidgets('a cover on screen replaces the mesh with the cover tint', (
    t,
  ) async {
    // The mesh is only the fallback: with a tint seed there is none.
    await t.pumpWidget(
      const MaterialApp(home: ArtTintBackground(seed: Color(0xFF3366CC))),
    );
    expect(find.byType(AuroraMesh), findsNothing);
  });

  testWidgets('first run: Home is the hero with the Aurora Add server', (
    t,
  ) async {
    final models = TestViewModels();
    await pumpShell(
      t,
      size: TestSizes.phone,
      viewModels: models,
      routes: testShellRoutes(
        builders: {AppRouter.home: (context, state) => const HomePage()},
      ),
    );
    final empty = t.widget<EmptyState>(find.byType(EmptyState));
    expect(empty.hero, isTrue);
    expect(find.text('Omnisonic'), findsWidgets);
    expect(find.widgetWithText(AuroraButton, 'Add server'), findsOneWidget);
  });
}
