import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/widgets/album_card.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Regressions for #53 points 2 and 3.
void main() {
  testWidgets('hidden hover overlay does not take taps on touch', (
    tester,
  ) async {
    var stars = 0;
    var taps = 0;
    await pumpPage(
      tester,
      Center(
        child: SizedBox(
          width: 200,
          height: 260,
          child: AlbumCard(
            album: testAlbum(),
            onTap: () => taps++,
            onStar: () => stars++,
          ),
        ),
      ),
      settle: false,
    );

    // Where the invisible star button sits: 26px left of the art's centre.
    final art = tester.getRect(find.byType(AspectRatio).first);
    await tester.tapAt(art.center - const Offset(26, 0));
    await tester.pump();

    expect(stars, 0);
    expect(taps, 1);
  });

  testWidgets('card lays out in a Wrap, where height is unbounded', (
    tester,
  ) async {
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: Wrap(
          spacing: 12,
          children: [
            for (final album in testAlbums(4))
              SizedBox(
                width: 96,
                child: AlbumCard(album: album, width: 96, showMeta: false),
              ),
          ],
        ),
      ),
      settle: false,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AspectRatio).first), const Size(96, 96));
  });
}
