import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/services/subsonic_models.dart';

import '../../helpers/entity_factories.dart';

/// Track ratings: schema version 5 adds the column, and a sync carries the
/// server's rating into it.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('omnisonic_db'));
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'a version 4 database gains the rating column and keeps its tracks',
    () async {
      final file = File('${dir.path}/app.sqlite');
      final server = testServer(id: 'srv');
      final track = testTrack(id: 'srv_t1', serverId: 'srv');

      final v5 = AppDatabase.forTesting(NativeDatabase(file));
      await v5.serverDao.insertServer(server, 'pw');
      await v5.musicDao.insertTracks([track]);
      await v5.close();

      // Turned back into a database as version 4 left it, without the
      // column, right before drift reads its version and migrates.
      var downgraded = false;
      final upgraded = AppDatabase.forTesting(
        NativeDatabase(
          file,
          setup: (raw) {
            raw.execute('ALTER TABLE tracks_table DROP COLUMN rating');
            raw.execute('PRAGMA user_version = 4');
            downgraded = true;
          },
        ),
      );
      addTearDown(upgraded.close);

      final kept = await upgraded.musicDao.getTrackById(track.id);
      expect(downgraded, isTrue);
      expect(kept, isNotNull);
      expect(kept!.rating, 0);
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, 5);

      await upgraded.musicDao.updateTrack(kept.copyWith(rating: 3));
      expect((await upgraded.musicDao.getTrackById(track.id))!.rating, 3);
    },
  );

  test('a sync takes the rating from the server', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final server = testServer(id: 'srv');
    await database.serverDao.insertServer(server, 'pw');

    final api = SubsonicApiClient();
    Future<int> syncWithRating(int? userRating) async {
      final track = SubsonicSong.fromJson({
        'id': 't1',
        'isDir': false,
        'title': 'Song',
        'userRating': ?userRating,
      }).toDomainTrack('srv', 'url', server, 'pw', api);
      await database.musicDao.upsertTracks([track]);
      return (await database.musicDao.getTrackById('srv_t1'))!.rating;
    }

    expect(await syncWithRating(4), 4);
    // Cleared on the server (Navidrome drops the field when unrated).
    expect(await syncWithRating(null), 0);
  });
}
