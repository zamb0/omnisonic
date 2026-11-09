import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/database/data_sources/local_music_data_source.dart';
import 'package:omnisonic/core/database/data_sources/local_playlist_data_source.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/music_repository.dart';
import 'package:omnisonic/core/repositories/server_repository.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/services/subsonic_models.dart';
import 'package:omnisonic/features/music/data/datasources/server_playlist_data_source.dart';
import 'package:omnisonic/features/music/data/repositories/playlist_repository_impl.dart';

import '../../helpers/entity_factories.dart';

/// Playlists that live on a Subsonic server (Navidrome): read and written
/// there, mirrored locally.
void main() {
  late AppDatabase database;
  late LocalMusicDataSource music;
  late LocalPlaylistDataSource localPlaylists;
  late _FakeSubsonicServer server;
  late _FakeMusicRepository musicRepository;
  late PlaylistRepositoryImpl repository;

  final home = testServer(id: 'srv1', name: 'Home', username: 'me');
  final other = testServer(id: 'srv2', name: 'Other', username: 'me');

  Track libraryTrack(String serverId, String songId, {String? title}) =>
      testTrack(
        id: '${serverId}_$songId',
        serverId: serverId,
        title: title ?? 'Song $songId',
      );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    music = LocalMusicDataSource(database);
    localPlaylists = LocalPlaylistDataSource(database);
    for (final s in [home, other]) {
      await database.serverDao.insertServer(s, 'password');
    }
    await music.syncMusicData(
      'srv1',
      tracks: [
        for (final id in ['s1', 's2', 's3']) libraryTrack('srv1', id),
      ],
    );
    await music.syncMusicData('srv2', tracks: [libraryTrack('srv2', 'x1')]);

    server = _FakeSubsonicServer();
    musicRepository = _FakeMusicRepository();
    final servers = _FakeServerRepository([home, other]);
    repository = PlaylistRepositoryImpl(
      localPlaylistDataSource: localPlaylists,
      localMusicDataSource: music,
      serverPlaylistDataSource: ServerPlaylistDataSource(server, servers),
      serverRepository: servers,
      musicRepository: musicRepository,
    );
  });

  tearDown(() => database.close());

  Future<Playlist?> stored(String id) async =>
      (await localPlaylists.getPlaylistById(id)).valueOrNull;

  group('sync', () {
    test('brings in server playlists, in server order', () async {
      server.add('p1', 'Road trip', ['s3', 's1', 'new']);

      final result = await repository.syncFromServers();

      expect(result.isSuccess, isTrue);
      final playlist = (await stored('srv1_p1'))!;
      expect(playlist.name, 'Road trip');
      expect(playlist.serverId, 'srv1');
      expect(playlist.trackIds, ['srv1_s3', 'srv1_s1', 'srv1_new']);
      // A track the library has not synced yet is stored with it.
      final tracks = await repository.getPlaylistTracks('srv1_p1');
      expect(tracks.valueOrNull!.map((t) => t.title), [
        'Song s3',
        'Song s1',
        'Server song new',
      ]);
    });

    test('drops playlists deleted on the server, keeps local ones', () async {
      server.add('p1', 'Gone soon', ['s1']);
      await repository.syncFromServers();
      final local = await repository.createPlaylist(name: 'Mine');

      server.playlists.remove('p1');
      await repository.syncFromServers();

      expect(await stored('srv1_p1'), isNull);
      expect(await stored(local.valueOrNull!.id), isNotNull);
    });

    test('does not refetch a playlist that has not changed', () async {
      server.add('p1', 'Stable', ['s1']);
      await repository.syncFromServers();
      server.calls.clear();

      await repository.syncFromServers();

      expect(server.calls.where((c) => c.startsWith('getPlaylist ')), isEmpty);
    });
  });

  group('writes', () {
    Future<Playlist> synced(
      String id,
      List<String> songs, {
      String owner = 'me',
    }) async {
      server.add(id, 'List $id', songs, owner: owner);
      await repository.syncFromServers();
      server.calls.clear();
      return (await stored('srv1_$id'))!;
    }

    test('a playlist created on a server is created there', () async {
      final result = await repository.createPlaylist(
        name: 'Fresh',
        description: 'New one',
        isPublic: true,
        serverId: 'srv1',
      );

      final created = result.valueOrNull!;
      expect(created.serverId, 'srv1');
      final remote = server.playlists[created.id.substring('srv1_'.length)]!;
      expect(remote.name, 'Fresh');
      expect(remote.comment, 'New one');
      expect(remote.public, isTrue);
      expect(await stored(created.id), isNotNull);
    });

    test('adding a track appends it on the server', () async {
      final playlist = await synced('p1', ['s1']);

      final result = await repository.addTrackToPlaylist(
        playlist.id,
        'srv1_s2',
      );

      expect(result.isSuccess, isTrue);
      expect(server.calls, contains('updatePlaylist p1 add=[s2] remove=[]'));
      expect(server.playlists['p1']!.entries, ['s1', 's2']);
      expect((await stored(playlist.id))!.trackIds, ['srv1_s1', 'srv1_s2']);
    });

    test('a track from another server goes in as its copy there', () async {
      final playlist = await synced('p1', ['s1']);
      musicRepository.groups = {
        'g': [libraryTrack('srv2', 'x1'), libraryTrack('srv1', 's3')],
      };

      await repository.addTrackToPlaylist(playlist.id, 'srv2_x1');

      expect(server.playlists['p1']!.entries, ['s1', 's3']);
    });

    test('a track the server does not have is refused, by name', () async {
      final playlist = await synced('p1', ['s1']);

      final result = await repository.addTrackToPlaylist(
        playlist.id,
        'srv2_x1',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, contains('isn\'t on Home'));
      expect(server.calls, isEmpty);
    });

    test('removing a track removes every occurrence on the server', () async {
      final playlist = await synced('p1', ['s1', 's2', 's1', 's3']);
      expect(playlist.trackIds, ['srv1_s1', 'srv1_s2', 'srv1_s3']);

      await repository.removeTrackFromPlaylist(playlist.id, 'srv1_s1');

      expect(server.calls, contains('updatePlaylist p1 add=[] remove=[0, 2]'));
      expect(server.playlists['p1']!.entries, ['s2', 's3']);
    });

    test('a reorder rewrites the entries in the new order', () async {
      final playlist = await synced('p1', ['s1', 's2', 's3']);

      await repository.moveTrackInPlaylist(playlist.id, 2, 0);

      expect(server.calls, contains('createPlaylist id=p1 songs=[s3, s1, s2]'));
      expect((await stored(playlist.id))!.trackIds, [
        'srv1_s3',
        'srv1_s1',
        'srv1_s2',
      ]);
    });

    test('details are saved on the server', () async {
      final playlist = await synced('p1', ['s1']);

      await repository.updatePlaylist(
        playlist.copyWith(
          name: 'Renamed',
          description: 'About',
          isPublic: true,
        ),
      );

      final remote = server.playlists['p1']!;
      expect(remote.name, 'Renamed');
      expect(remote.comment, 'About');
      expect(remote.public, isTrue);
      expect(
        server.calls.where((c) => c.startsWith('createPlaylist')),
        isEmpty,
      );
    });

    test('someone else\'s playlist is read-only', () async {
      final playlist = await synced('p1', ['s1'], owner: 'bob');

      final rename = await repository.updatePlaylist(
        playlist.copyWith(name: 'Mine now'),
      );
      final delete = await repository.deletePlaylist(playlist.id);

      expect(rename.fold((f) => f.message, (_) => null), contains('bob'));
      expect(delete.isFailure, isTrue);
      expect(server.calls, isEmpty);
      expect(await stored(playlist.id), isNotNull);
    });

    test('deleting removes it on the server and here', () async {
      final playlist = await synced('p1', ['s1']);

      final result = await repository.deletePlaylist(playlist.id);

      expect(result.isSuccess, isTrue);
      expect(server.playlists, isEmpty);
      expect(await stored(playlist.id), isNull);
    });

    test('a refused write leaves the local copy as it was', () async {
      final playlist = await synced('p1', ['s1']);
      server.refuseWrites = true;

      final result = await repository.addTrackToPlaylist(
        playlist.id,
        'srv1_s2',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect((await stored(playlist.id))!.trackIds, ['srv1_s1']);
    });
  });
}

class _RemotePlaylist {
  _RemotePlaylist(this.name, this.entries, this.owner);

  String name;
  String? comment;
  bool public = false;
  List<String> entries;
  final String owner;
  DateTime changed = DateTime.utc(2026, 1, 1);
}

/// A Subsonic server's playlist endpoints, in memory.
class _FakeSubsonicServer extends SubsonicApiClient {
  final playlists = <String, _RemotePlaylist>{};
  final calls = <String>[];
  bool refuseWrites = false;
  var _nextId = 100;
  var _clock = 0;

  void add(String id, String name, List<String> songs, {String owner = 'me'}) {
    playlists[id] = _RemotePlaylist(name, [...songs], owner);
  }

  void _touch(_RemotePlaylist playlist) => playlist.changed = DateTime.utc(
    2026,
    2,
    1,
  ).add(Duration(hours: ++_clock));

  void _checkWrite() {
    if (refuseWrites) {
      // Navidrome's answer to editing a playlist the user may not change.
      throw const SubsonicApiException('Not authorized', '50');
    }
  }

  static SubsonicResponse<T> _ok<T>(T data) => SubsonicResponse(
    subsonicResponse: SubsonicResponseData(
      status: 'ok',
      version: '1.16.1',
      data: data,
    ),
  );

  SubsonicPlaylist _toJson(String id, {bool withEntries = true}) {
    final p = playlists[id]!;
    return SubsonicPlaylist(
      id: id,
      name: p.name,
      comment: p.comment,
      owner: p.owner,
      public: p.public,
      songCount: p.entries.length,
      changed: p.changed,
      created: DateTime.utc(2025),
      entry: withEntries
          ? [
              for (final song in p.entries)
                SubsonicSong(
                  id: song,
                  isDir: false,
                  title: 'Server song $song',
                  duration: 200,
                ),
            ]
          : null,
    );
  }

  @override
  Future<SubsonicResponse<PlaylistsResponse>> getPlaylists(
    MusicServer server,
    String password,
  ) async {
    // Only the "Home" server has playlists.
    if (server.id != 'srv1') return _ok(const PlaylistsResponse());
    calls.add('getPlaylists');
    return _ok(
      PlaylistsResponse(
        playlist: [
          for (final id in playlists.keys) _toJson(id, withEntries: false),
        ],
      ),
    );
  }

  @override
  Future<SubsonicResponse<SubsonicPlaylist>> getPlaylist(
    MusicServer server,
    String password,
    String playlistId,
  ) async {
    calls.add('getPlaylist $playlistId');
    if (!playlists.containsKey(playlistId)) {
      throw const SubsonicApiException('Playlist not found', '70');
    }
    return _ok(_toJson(playlistId));
  }

  @override
  Future<SubsonicResponse<SubsonicPlaylist?>> createPlaylist(
    MusicServer server,
    String password, {
    String? name,
    String? playlistId,
    List<String> songIds = const [],
  }) async {
    _checkWrite();
    if (playlistId != null) {
      calls.add('createPlaylist id=$playlistId songs=$songIds');
      final playlist = playlists[playlistId]!..entries = [...songIds];
      _touch(playlist);
      return _ok(_toJson(playlistId));
    }
    final id = 'n${_nextId++}';
    calls.add('createPlaylist name=$name songs=$songIds');
    add(id, name!, songIds);
    return _ok(_toJson(id));
  }

  @override
  Future<SubsonicResponse<PingResponse>> updatePlaylist(
    MusicServer server,
    String password,
    String playlistId, {
    String? name,
    String? comment,
    bool? isPublic,
    List<String> songIdsToAdd = const [],
    List<int> songIndexesToRemove = const [],
  }) async {
    _checkWrite();
    calls.add(
      'updatePlaylist $playlistId add=$songIdsToAdd '
      'remove=$songIndexesToRemove',
    );
    final p = playlists[playlistId]!;
    if (name != null) p.name = name;
    if (comment != null) p.comment = comment.isEmpty ? null : comment;
    if (isPublic != null) p.public = isPublic;
    final remove = songIndexesToRemove.toSet();
    p.entries = [
      for (var i = 0; i < p.entries.length; i++)
        if (!remove.contains(i)) p.entries[i],
      ...songIdsToAdd,
    ];
    _touch(p);
    return _ok(const PingResponse());
  }

  @override
  Future<SubsonicResponse<PingResponse>> deletePlaylist(
    MusicServer server,
    String password,
    String playlistId,
  ) async {
    _checkWrite();
    calls.add('deletePlaylist $playlistId');
    playlists.remove(playlistId);
    return _ok(const PingResponse());
  }
}

class _FakeServerRepository extends Fake implements ServerRepository {
  _FakeServerRepository(this.servers);

  final List<MusicServer> servers;

  @override
  Future<Result<List<MusicServer>>> getAllServers() async =>
      ResultHelper.success(servers);

  @override
  Future<Result<MusicServer?>> getServerById(String serverId) async =>
      ResultHelper.success(servers.where((s) => s.id == serverId).firstOrNull);

  @override
  Future<Result<String?>> getCredentials(String serverId) async =>
      ResultHelper.success('password');
}

class _FakeMusicRepository extends Fake implements MusicRepository {
  Map<String, List<Track>> groups = {};

  @override
  Future<Result<Map<String, List<Track>>>> getDuplicateGroups() async =>
      ResultHelper.success(groups);
}
