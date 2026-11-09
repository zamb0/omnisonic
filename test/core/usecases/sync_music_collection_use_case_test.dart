import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/usecases/sync_music_collection_use_case.dart';

import '../../helpers/entity_factories.dart';
import 'sync_music_collection_use_case_test.mocks.dart';

/// #72: a fresh install has nothing to sync, which is not an error.
@GenerateMocks([MusicRepository, ServerRepository, PlaylistRepository])
void main() {
  late MockMusicRepository music;
  late MockServerRepository servers;
  late MockPlaylistRepository playlists;
  late SyncMusicCollectionUseCase useCase;

  setUp(() {
    music = MockMusicRepository();
    servers = MockServerRepository();
    playlists = MockPlaylistRepository();
    when(
      playlists.syncFromServers(),
    ).thenAnswer((_) async => ResultHelper.success(null));
    useCase = SyncMusicCollectionUseCase(music, servers, playlists);
    when(
      servers.getOnlineServers(),
    ).thenAnswer((_) async => ResultHelper.success(<MusicServer>[]));
  });

  test('no server configured gives NoServersFailure', () async {
    when(
      servers.getAllServers(),
    ).thenAnswer((_) async => ResultHelper.success(<MusicServer>[]));

    final result = await useCase(const SyncMusicCollectionParams());

    expect(result.fold((f) => f, (_) => null), isA<NoServersFailure>());
  });

  test('servers that are all offline still fail as a server problem', () async {
    when(
      servers.getAllServers(),
    ).thenAnswer((_) async => ResultHelper.success([testServer()]));

    final result = await useCase(const SyncMusicCollectionParams());

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });
}
