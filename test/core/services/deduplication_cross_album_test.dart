import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';

import '../../helpers/entity_factories.dart';

/// #67: deduplication is for the same track on different servers, not for
/// two recordings that happen to share a title, artist and length.
void main() {
  final engine = DeduplicationEngine();

  test('same title on two albums of one server stays two tracks', () {
    final groups = engine.detectDuplicates([
      testTrack(
        id: 'server1_t1',
        title: 'Midnight Drive',
        album: 'Glass Horizons',
      ),
      testTrack(
        id: 'server1_t2',
        title: 'Midnight Drive',
        album: 'Second Light',
      ),
    ]);

    expect(groups, isEmpty);
  });

  test('same title on two albums across servers stays two tracks', () {
    final groups = engine.detectDuplicates([
      testTrack(
        id: 'server1_t1',
        title: 'Midnight Drive',
        album: 'Glass Horizons',
      ),
      testTrack(
        id: 'server2_t2',
        serverId: 'server2',
        title: 'Midnight Drive',
        album: 'Second Light',
      ),
    ]);

    expect(groups, isEmpty);
  });

  test('two copies on one server are not duplicates of each other', () {
    final groups = engine.detectDuplicates([
      testTrack(id: 'server1_t1', title: 'Night Shift'),
      testTrack(id: 'server1_t2', title: 'Night Shift'),
    ]);

    expect(groups, isEmpty);
  });

  test('a group holds one copy per server', () {
    final groups = engine.detectDuplicates([
      testTrack(id: 'server1_t1', title: 'Night Shift'),
      testTrack(id: 'server2_t1', serverId: 'server2', title: 'Night Shift'),
      testTrack(id: 'server1_t2', title: 'Night Shift'),
    ]);

    expect(groups, hasLength(1));
    final group = groups.values.single;
    expect(group.map((t) => t.serverId).toSet(), {'server1', 'server2'});
    expect(group, hasLength(2));
  });

  test('the same track on two servers is still merged', () {
    final groups = engine.detectDuplicates([
      testTrack(
        id: 'server1_t1',
        title: 'Midnight Drive',
        album: 'Night Shift',
      ),
      testTrack(
        id: 'server2_t1',
        serverId: 'server2',
        title: 'Midnight Drive',
        album: 'Night Shift',
      ),
    ]);

    expect(groups, hasLength(1));
  });
}
