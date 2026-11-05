import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/utils/artist_grouping.dart';

import '../../helpers/entity_factories.dart';

/// #67: albums were deduplicated across servers, artists were not.
void main() {
  test('an artist on two servers is listed once', () {
    final result = dedupeArtists([
      testArtist(id: 'server1_ar1', name: 'Aurora Vale'),
      testArtist(id: 'server2_ar9', name: 'aurora vale', serverId: 'server2'),
      testArtist(id: 'server1_ar2', name: 'Kenji Mori'),
    ], const []);

    expect(result.artists.map((a) => a.name), ['Aurora Vale', 'Kenji Mori']);
    final aurora = result.artists.first;
    expect(
      result.memberIds[aurora.id],
      unorderedEquals(['server1_ar1', 'server2_ar9']),
    );
  });

  test('the merged album count counts a shared album once', () {
    final result = dedupeArtists(
      [
        testArtist(id: 'server1_ar1', name: 'Aurora Vale', albumCount: 2),
        testArtist(
          id: 'server2_ar9',
          name: 'Aurora Vale',
          serverId: 'server2',
          albumCount: 1,
        ),
      ],
      [
        testAlbum(
          id: 'server1_a1',
          title: 'Glass Horizons',
          artist: 'Aurora Vale',
        ),
        testAlbum(
          id: 'server1_a2',
          title: 'Second Light',
          artist: 'Aurora Vale',
        ),
        testAlbum(
          id: 'server2_a1',
          title: 'Glass Horizons',
          artist: 'Aurora Vale',
          serverId: 'server2',
          artistId: 'server2_ar9',
        ),
      ],
    );

    expect(result.artists.single.albumCount, 2);
  });

  test('the copy with an image represents the group', () {
    final result = dedupeArtists([
      testArtist(id: 'server1_ar1', name: 'Aurora Vale'),
      testArtist(
        id: 'server2_ar9',
        name: 'Aurora Vale',
        serverId: 'server2',
        imageUrl: 'http://example.test/a.jpg',
      ),
    ], const []);

    expect(result.artists.single.id, 'server2_ar9');
  });
}
