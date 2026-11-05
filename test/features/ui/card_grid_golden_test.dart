import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// A grid of album and artist cards with no artwork — the generative
/// placeholders — in both themes.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: card grid without covers (${mode.name})', (
      tester,
    ) async {
      final albums = testAlbums(4);
      final artists = testArtists(2);
      await pumpPage(
        tester,
        Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Material(
              type: MaterialType.transparency,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    height: 520,
                    child: ResponsiveGridView.media(
                      meta: true,
                      itemCount: albums.length,
                      itemBuilder: (context, i) => AlbumCard(
                        album: albums[i],
                        sourceServerIds: i == 1
                            ? const ['server1', 'server2']
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 240,
                    child: ResponsiveGridView.media(
                      subtitle: false,
                      meta: true,
                      itemCount: artists.length,
                      itemBuilder: (context, i) =>
                          ArtistCard(artist: artists[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        themeMode: mode,
        settle: false,
        disableAnimations: true,
      );
      await tester.pump();
      await expectLater(
        find.byType(ListView),
        matchesGoldenFile('goldens/card_grid_${mode.name}.png'),
      );
    });
  }
}
