import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

void main() {
  Future<void> pumpRail(
    WidgetTester t, {
    ThemeMode mode = ThemeMode.dark,
  }) async {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.library.emitCollection(
      albums: testAlbums(4),
      artists: testArtists(2),
      tracks: testTracks(7),
    );
    models.library.emitStarred(tracks: testTracks(3));
    await pumpPage(
      t,
      Builder(
        builder: (context) => Material(
          color: Theme.of(context).colorScheme.surface,
          child: const SizedBox(
            width: 300,
            height: 700,
            child: LibraryStatsRail(),
          ),
        ),
      ),
      viewModels: models,
      themeMode: mode,
      size: const Size(400, 800),
      settle: false,
      disableAnimations: true,
    );
    await t.pump();
  }

  testWidgets('tiles carry an icon, a tabular number and a label', (t) async {
    await pumpRail(t);
    for (final label in ['albums', 'artists', 'tracks', 'favorites']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    final number = t.widget<Text>(find.text('4'));
    expect(
      number.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(
      number.style!.fontSize,
      OmnisonicTypography.sectionTitleSmall.fontSize,
    );
  });

  testWidgets('favourites are heat, the rest muted', (t) async {
    await pumpRail(t);
    Color iconColor(IconData icon) => t.widget<Icon>(find.byIcon(icon)).color!;
    expect(iconColor(OmnisonicIcons.favorite), OmnisonicBrand.dark.heat);
    expect(
      iconColor(OmnisonicIcons.albumOutline),
      OmnisonicTheme.darkTheme.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('the favourites tile counts the starred tracks', (t) async {
    await pumpRail(t);
    expect(find.text('3'), findsOneWidget);
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: stats rail (${mode.name})', (t) async {
      await pumpRail(t, mode: mode);
      await expectLater(
        find.byType(LibraryStatsRail),
        matchesGoldenFile('goldens/stats_rail_${mode.name}.png'),
      );
    });
  }
}
