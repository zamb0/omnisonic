import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';

import '../../helpers/entity_factories.dart';

/// The playlist and rating endpoints as a Subsonic server (Navidrome) sees
/// them: the query each call sends, and how its JSON answer is read.
void main() {
  late List<Uri> sent;
  late Map<String, dynamic> Function(Uri uri) answer;
  late SubsonicApiClient api;
  final server = testServer(url: 'https://music.example.test');

  Map<String, dynamic> ok([Map<String, dynamic> body = const {}]) => {
    'subsonic-response': {
      'status': 'ok',
      'version': '1.16.1',
      'type': 'navidrome',
      'serverVersion': '0.53.3',
      'openSubsonic': true,
      ...body,
    },
  };

  setUp(() {
    sent = [];
    answer = (_) => ok();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent.add(options.uri);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: answer(options.uri),
            ),
          );
        },
      ),
    );
    api = SubsonicApiClient(dio: dio);
  });

  List<String> all(String key) => sent.single.queryParametersAll[key] ?? [];

  test('createPlaylist sends one songId per track', () async {
    answer = (_) => ok({
      'playlist': {
        'id': 'pl1',
        'name': 'Mix',
        'owner': 'me',
        'public': false,
        'songCount': 2,
        'duration': 400,
        'created': '2026-11-09T10:00:00.123456789Z',
        'changed': '2026-11-09T10:00:00.123456789Z',
        'entry': [
          {'id': 'a', 'isDir': false, 'title': 'A'},
          {'id': 'b', 'isDir': false, 'title': 'B'},
        ],
      },
    });

    final response = await api.createPlaylist(
      server,
      'pw',
      name: 'Mix',
      songIds: ['a', 'b'],
    );

    expect(sent.single.path, endsWith('/rest/createPlaylist'));
    expect(all('name'), ['Mix']);
    expect(all('songId'), ['a', 'b']);
    expect(all('playlistId'), isEmpty);
    expect(response.data!.id, 'pl1');
    expect(response.data!.entry!.map((s) => s.id), ['a', 'b']);
  });

  test('createPlaylist on an old server answers without a playlist', () async {
    final response = await api.createPlaylist(server, 'pw', name: 'Mix');

    expect(response.isSuccess, isTrue);
    expect(response.data, isNull);
  });

  test('updatePlaylist names additions and removals', () async {
    await api.updatePlaylist(
      server,
      'pw',
      'pl1',
      name: 'New name',
      comment: '',
      isPublic: true,
      songIdsToAdd: ['c'],
      songIndexesToRemove: [0, 2],
    );

    expect(sent.single.path, endsWith('/rest/updatePlaylist'));
    expect(all('playlistId'), ['pl1']);
    expect(all('name'), ['New name']);
    expect(all('comment'), ['']);
    expect(all('public'), ['true']);
    expect(all('songIdToAdd'), ['c']);
    expect(all('songIndexToRemove'), ['0', '2']);
  });

  test('getPlaylists reads Navidrome\'s list', () async {
    answer = (_) => ok({
      'playlists': {
        'playlist': [
          {
            'id': 'pl1',
            'name': 'Mine',
            'comment': 'note',
            'owner': 'me',
            'public': true,
            'songCount': 12,
            'duration': 3000,
            'created': '2026-01-01T00:00:00Z',
            'changed': '2026-02-01T00:00:00.5Z',
            'coverArt': 'pl-pl1_0',
          },
          {'id': 'smart', 'name': 'Top rated', 'readonly': true},
        ],
      },
    });

    final response = await api.getPlaylists(server, 'pw');

    final playlists = response.data!.playlist!;
    expect(playlists.map((p) => p.id), ['pl1', 'smart']);
    expect(playlists.first.songCount, 12);
    expect(playlists.first.changed, DateTime.utc(2026, 2, 1, 0, 0, 0, 500));
    expect(playlists.last.readonly, isTrue);
  });

  test('an empty server has no playlists rather than an error', () async {
    answer = (_) => ok({'playlists': <String, dynamic>{}});

    final response = await api.getPlaylists(server, 'pw');

    expect(response.data!.playlist, isNull);
  });

  test('setRating sends the stars, 0 clearing them', () async {
    await api.setRating(server, 'pw', 'song1', 0);

    expect(sent.single.path, endsWith('/rest/setRating'));
    expect(all('id'), ['song1']);
    expect(all('rating'), ['0']);
  });
}
