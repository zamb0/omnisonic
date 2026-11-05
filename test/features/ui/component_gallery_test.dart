import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/component_gallery_page.dart';

import '../../helpers/widget_harness.dart';

/// The gallery: every component, variant × state, light and dark side by
/// side — the base for review and for these goldens.
void main() {
  Future<void> pumpGallery(
    WidgetTester t, {
    Size size = const Size(1500, 1000),
  }) async {
    await pumpPage(
      t,
      const ComponentGalleryPage(),
      size: size,
      settle: false,
      disableAnimations: true,
    );
    await t.pump();
  }

  test('the route is registered in debug builds only', () {
    final paths = AppRouter.router.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toList();
    expect(paths, contains(AppRouter.devGallery));
    expect(AppRouter.devGallery, '/dev/gallery');
  });

  testWidgets('every section renders without an exception', (t) async {
    await pumpGallery(t);
    expect(t.takeException(), isNull);
    for (final id in ComponentGalleryPage.sectionIds) {
      expect(
        find.byKey(ComponentGalleryPage.sectionKey(id)),
        findsOneWidget,
        reason: id,
      );
    }
  });

  testWidgets('each section is shown in both themes', (t) async {
    await pumpGallery(t);
    // Two themed panels per section.
    final panels = find.descendant(
      of: find.byKey(ComponentGalleryPage.sectionKey('buttons')),
      matching: find.byType(Theme),
    );
    expect(panels, findsWidgets);
    final brightnesses = {
      for (final element
          in find
              .descendant(
                of: find.byKey(ComponentGalleryPage.sectionKey('buttons')),
                matching: find.byType(AuroraButton),
              )
              .evaluate())
        Theme.of(element).brightness,
    };
    expect(brightnesses, {Brightness.dark, Brightness.light});
  });

  testWidgets('side by side when wide, stacked when narrow', (t) async {
    await pumpGallery(t);
    final wide = t
        .getSize(find.byKey(ComponentGalleryPage.sectionKey('badges')))
        .height;
    await pumpGallery(t, size: const Size(500, 1000));
    final narrow = t
        .getSize(find.byKey(ComponentGalleryPage.sectionKey('badges')))
        .height;
    expect(narrow, greaterThan(wide));
    expect(t.takeException(), isNull);
  });

  testWidgets('it covers every component variant', (t) async {
    await pumpGallery(t);
    // At least one of each, in each theme (so >= 2).
    for (final (type, name) in <(Type, String)>[
      (AuroraButton, 'AuroraButton'),
      (OmnisonicButton, 'OmnisonicButton'),
      (PlayDisc, 'PlayDisc'),
      (OmnisonicIconButton, 'OmnisonicIconButton'),
      (OmnisonicSegmented<int>, 'OmnisonicSegmented'),
      (AuroraProgress, 'AuroraProgress'),
      (AuroraProgressLine, 'AuroraProgressLine'),
    ]) {
      expect(find.byType(type), findsAtLeastNWidgets(2), reason: name);
    }
  });

  for (final id in ComponentGalleryPage.sectionIds) {
    testWidgets('golden: gallery · $id', (t) async {
      await pumpGallery(t, size: const Size(1500, 1000));
      await t.ensureVisible(find.byKey(ComponentGalleryPage.sectionKey(id)));
      await t.pump();
      await expectLater(
        find.byKey(ComponentGalleryPage.sectionKey(id)),
        matchesGoldenFile('goldens/gallery_$id.png'),
      );
    });
  }
}
