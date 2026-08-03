import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omnisonic/core/database/app_database.dart';
import 'package:omnisonic/core/database/data_sources/local_music_data_source.dart';
import 'package:omnisonic/core/entities/music_server.dart';
import 'package:omnisonic/core/entities/server_status.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/repositories/server_repository.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/core/services/server_connection_service.dart';
import 'package:omnisonic/core/services/source_selection_service.dart';
import 'package:omnisonic/core/services/subsonic_api_client.dart';
import 'package:omnisonic/core/services/subsonic_models.dart';
import 'package:omnisonic/features/music/data/repositories/music_repository_impl.dart';

import 'music_repository_sync_test.mocks.dart';

@GenerateMocks([
  SubsonicApiClient,
  ServerRepository,
  ServerConnectionService,
  SourceSelectionService,
])
void main() {
  late AppDatabase database;
  late MockSubsonicApiClient apiClient;
  late MockServerRepository serverRepository;
  late MockServerConnectionService connectionService;
  late MusicRepositoryImpl repository;

  final server = MusicServer(
    id: 'server1',
    name: 'Test Server',
    url: 'http://example.com',
    username: 'user',
    status: ServerStatus.online,
    createdAt: DateTime(2026),
  );

  /// Wraps [data] the way a successful Subsonic call does.
  SubsonicResponse<T> ok<T>(T data) => SubsonicResponse<T>(
    subsonicResponse: SubsonicResponseData<T>(
      status: 'ok',
      version: '1.16.1',
      data: data,
    ),
  );

  SubsonicAlbum album(int index) => SubsonicAlbum(
    id: 'album$index',
    name: 'Album $index',
    artist: 'Artist',
    songCount: 1,
    duration: 180,
  );

  SubsonicSong song(String albumId) => SubsonicSong(
    id: 'song-$albumId',
    isDir: false,
    title: 'Song of $albumId',
    album: 'Album',
    artist: 'Artist',
    albumId: albumId,
    duration: 180,
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    apiClient = MockSubsonicApiClient();
    serverRepository = MockServerRepository();
    connectionService = MockServerConnectionService();

    repository = MusicRepositoryImpl(
      localDataSource: LocalMusicDataSource(database),
      apiClient: apiClient,
      serverRepository: serverRepository,
      connectionService: connectionService,
      deduplicationEngine: DeduplicationEngine(),
      sourceSelectionService: MockSourceSelectionService(),
    );

    await database.serverDao.insertServer(server, 'password');

    when(serverRepository.getServerById('server1'))
        .thenAnswer((_) async => ResultHelper.success(server));
    when(serverRepository.updateLastSync(any, any))
        .thenAnswer((_) async => ResultHelper.success(null));
    when(connectionService.getServerPassword('server1'))
        .thenAnswer((_) async => ResultHelper.success('password'));

    when(apiClient.getArtists(any, any))
        .thenAnswer((_) async => ok(ArtistsResponse(index: const [])));
    when(apiClient.getStreamUrl(any, any, any)).thenReturn('http://stream');
    when(apiClient.getCoverArtUrl(any, any, any)).thenReturn('http://cover');
  });

  tearDown(() async => database.close());

  /// Stubs an album list of [total] albums served in pages of [pageSize],
  /// plus a one-song detail response for each.
  void stubAlbums({required int total, int pageSize = 500}) {
    final albums = [for (var i = 0; i < total; i++) album(i)];

    when(
      apiClient.getAlbums(
        any,
        any,
        type: anyNamed('type'),
        size: anyNamed('size'),
        offset: anyNamed('offset'),
      ),
    ).thenAnswer((invocation) async {
      final offset = invocation.namedArguments[#offset] as int? ?? 0;
      final page = albums.skip(offset).take(pageSize).toList();
      return ok(AlbumsResponse(album: page));
    });

    when(apiClient.getAlbum(any, any, any)).thenAnswer((invocation) async {
      final albumId = invocation.positionalArguments[2] as String;
      return ok(
        AlbumResponse(
          id: albumId,
          name: 'Album',
          artist: 'Artist',
          songCount: 1,
          duration: 180,
          song: [song(albumId)],
        ),
      );
    });
  }

  test('imports tracks for every album, not just the first ten', () async {
    stubAlbums(total: 25);

    final result = await repository.syncFromServer('server1');

    expect(result.isSuccess, isTrue);
    final tracks = await database.musicDao.getTracksByServerId('server1');
    expect(tracks, hasLength(25));
  });

  test('pages through album lists longer than one response', () async {
    // Three full pages plus a short one, so the loop has to keep going past
    // the first 500 and stop on the short page.
    stubAlbums(total: 1200);

    final result = await repository.syncFromServer('server1');

    expect(result.isSuccess, isTrue);
    final albums = await database.musicDao.getAlbumsByServerId('server1');
    expect(albums, hasLength(1200));

    final offsets = verify(
      apiClient.getAlbums(
        any,
        any,
        type: anyNamed('type'),
        size: anyNamed('size'),
        offset: captureAnyNamed('offset'),
      ),
    ).captured;
    expect(offsets, containsAll(<int>[0, 500, 1000]));
  });
}
