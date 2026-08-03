import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/database/data_sources/local_music_data_source.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/entities/track.dart';

void main() {
  late AppDatabase database;
  late LocalMusicDataSource dataSource;

  Track track(String id, {String title = 'Song'}) => Track(
    id: id,
    title: title,
    artist: 'Artist',
    album: 'Album',
    duration: const Duration(minutes: 3),
    serverId: 'server1',
    streamUrl: 'http://example.com/stream/$id',
    quality: AudioQuality.high,
    lastModified: DateTime(2026),
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = LocalMusicDataSource(database);

    await database.serverDao.insertServer(
      MusicServer(
        id: 'server1',
        name: 'Test Server',
        url: 'http://example.com',
        username: 'user',
        status: ServerStatus.online,
        createdAt: DateTime(2026),
      ),
      'password',
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('syncMusicData', () {
    test('keeps download and star state across a sync', () async {
      await dataSource.syncMusicData('server1', tracks: [track('t1')]);
      await database.musicDao.updateTrackCacheStatus('t1', true, '/tmp/t1.mp3');
      await (database.update(database.tracksTable)
            ..where((t) => t.id.equals('t1')))
          .write(const TracksTableCompanion(isStarred: Value(true)));

      // Same track comes back from the server with updated metadata.
      await dataSource.syncMusicData(
        'server1',
        tracks: [track('t1', title: 'Renamed Song')],
      );

      final stored = await database.musicDao.getTrackById('t1');
      expect(stored!.title, 'Renamed Song');
      expect(stored.isCached, isTrue);
      expect(stored.cachePath, '/tmp/t1.mp3');
      expect(stored.isStarred, isTrue);
    });

    test('removes tracks the server no longer reports', () async {
      await dataSource.syncMusicData(
        'server1',
        tracks: [track('t1'), track('t2')],
      );

      await dataSource.syncMusicData('server1', tracks: [track('t1')]);

      final remaining = await database.musicDao.getTracksByServerId('server1');
      expect(remaining.map((t) => t.id), ['t1']);
    });

    test('leaves playlist entries for surviving tracks intact', () async {
      await dataSource.syncMusicData(
        'server1',
        tracks: [track('t1'), track('t2')],
      );
      await database
          .into(database.playlistsTable)
          .insert(
            PlaylistsTableCompanion.insert(
              id: 'p1',
              name: 'Mix',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          );
      await database
          .into(database.playlistTracksTable)
          .insert(
            PlaylistTracksTableCompanion.insert(
              playlistId: 'p1',
              trackId: 't1',
              position: 0,
            ),
          );

      await dataSource.syncMusicData(
        'server1',
        tracks: [track('t1'), track('t2')],
      );

      final entries = await database.select(database.playlistTracksTable).get();
      expect(entries, hasLength(1));
      expect(entries.single.trackId, 't1');
    });
  });

  group('foreign keys', () {
    test('deleting a server cascades to its tracks', () async {
      await dataSource.syncMusicData('server1', tracks: [track('t1')]);

      await database.serverDao.deleteServer('server1');

      final remaining = await database.musicDao.getTracksByServerId('server1');
      expect(remaining, isEmpty);
    });
  });

  group('updateTrackCacheStatus', () {
    test('clears the cache path when passed null', () async {
      await dataSource.syncMusicData('server1', tracks: [track('t1')]);
      await database.musicDao.updateTrackCacheStatus('t1', true, '/tmp/t1.mp3');

      await database.musicDao.updateTrackCacheStatus('t1', false, null);

      final stored = await database.musicDao.getTrackById('t1');
      expect(stored!.isCached, isFalse);
      expect(stored.cachePath, isNull);
    });
  });

  group('getTracksByIds', () {
    test('returns only the requested tracks and ignores unknown ids', () async {
      await dataSource.syncMusicData(
        'server1',
        tracks: [track('t1'), track('t2'), track('t3')],
      );

      final result = await database.musicDao.getTracksByIds([
        't1',
        't3',
        'missing',
      ]);

      expect(result.map((t) => t.id).toSet(), {'t1', 't3'});
    });
  });
}
