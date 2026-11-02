import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/database/data_sources/local_music_data_source.dart';
import 'package:omnisonic/core/database/data_sources/local_playlist_data_source.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/features/music/data/repositories/playlist_repository_impl.dart';

void main() {
  late AppDatabase database;
  late LocalMusicDataSource musicDataSource;
  late PlaylistRepositoryImpl repository;

  Track track(String id) => Track(
    id: id,
    title: 'Song $id',
    artist: 'Artist',
    album: 'Album',
    duration: const Duration(minutes: 3),
    serverId: 'server1',
    streamUrl: 'http://example.com/$id',
    quality: AudioQuality.high,
    lastModified: DateTime(2026),
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    musicDataSource = LocalMusicDataSource(database);
    repository = PlaylistRepositoryImpl(
      localPlaylistDataSource: LocalPlaylistDataSource(database),
      localMusicDataSource: musicDataSource,
    );

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
    await musicDataSource.syncMusicData(
      'server1',
      tracks: [track('t1'), track('t2'), track('t3')],
    );
  });

  tearDown(() async => database.close());

  Future<String> createPlaylist(List<String> trackIds) async {
    final created = await repository.createPlaylist(name: 'Mix');
    var playlist = created.valueOrNull!;
    for (final id in trackIds) {
      final result = await repository.addTrackToPlaylist(playlist.id, id);
      playlist = result.valueOrNull ?? playlist;
    }
    return playlist.id;
  }

  group('getPlaylistTracks', () {
    test('returns the tracks in playlist order', () async {
      final id = await createPlaylist(['t3', 't1']);

      final result = await repository.getPlaylistTracks(id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.map((t) => t.id).toList(), ['t3', 't1']);
    });

    test('skips tracks that are no longer in the library', () async {
      final id = await createPlaylist(['t1', 't2']);
      await database.musicDao.deleteTrack('t2');

      final result = await repository.getPlaylistTracks(id);

      // The old implementation threw out of a firstWhere here, because its
      // orElse sat outside the try that was meant to skip deleted tracks.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.map((t) => t.id).toList(), ['t1']);
    });

    test('fails for a playlist that does not exist', () async {
      final result = await repository.getPlaylistTracks('nope');

      expect(result.isFailure, isTrue);
    });
  });

  group('addTrackToPlaylist', () {
    test('rejects a track that is not in the library', () async {
      final created = await repository.createPlaylist(name: 'Mix');

      final result = await repository.addTrackToPlaylist(
        created.valueOrNull!.id,
        'missing',
      );

      expect(result.isFailure, isTrue);
    });
  });
}
