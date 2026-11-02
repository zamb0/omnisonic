import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/repositories/repositories.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/playlist_view_model.dart';

import '../../helpers/entity_factories.dart';

/// Regression for #53 point 4: the playlist detail page stayed on "No tracks"
/// because the view model notified before the tracks had arrived.
void main() {
  test('selectPlaylist notifies after the tracks are loaded', () async {
    final playlist = testPlaylist();
    final tracks = testTracks(3);
    final gate = Completer<void>();
    final repo = _FakePlaylistRepository(playlist, tracks, gate);
    final vm = PlaylistViewModel(repo, _FakeManagePlaylistUseCase());
    await pumpEventQueue();

    final seen = <({bool loading, int count})>[];
    vm.addListener(
      () => seen.add((
        loading: vm.isLoadingTracks,
        count: vm.selectedPlaylistTracks.length,
      )),
    );

    final done = vm.selectPlaylist(playlist.id);
    await pumpEventQueue();
    expect(vm.isLoadingTracks, isTrue);
    expect(vm.selectedPlaylistTracks, isEmpty);

    gate.complete();
    await done;

    expect(vm.isLoadingTracks, isFalse);
    expect(vm.selectedPlaylistTracks, hasLength(3));
    expect(seen.last, (loading: false, count: 3));
    vm.dispose();
  });

  group('moveTrackInPlaylist (#59)', () {
    test('moves the row at once, before the server answers', () async {
      final tracks = testTracks(4);
      final (vm, useCase) = await _selected(tracks);
      useCase.gate = Completer<void>();

      final done = vm.moveTrackInPlaylist(testPlaylist().id, 0, 2);
      expect(vm.selectedPlaylistTracks.map((t) => t.id), [
        tracks[1].id,
        tracks[2].id,
        tracks[0].id,
        tracks[3].id,
      ]);

      // A second drag in the same window is not dropped.
      final second = vm.moveTrackInPlaylist(testPlaylist().id, 3, 0);
      expect(vm.selectedPlaylistTracks.first.id, tracks[3].id);

      useCase.gate!.complete();
      expect(await done, isTrue);
      expect(await second, isTrue);
      expect(useCase.calls, hasLength(2));
      vm.dispose();
    });

    test('rolls back to the server order and reports on failure', () async {
      final tracks = testTracks(3);
      final (vm, useCase) = await _selected(tracks);
      useCase.succeed = false;

      final ok = await vm.moveTrackInPlaylist(testPlaylist().id, 0, 2);

      expect(ok, isFalse);
      expect(vm.selectedPlaylistTracks.map((t) => t.id), [
        for (final t in tracks) t.id,
      ]);
      expect(vm.actionError, startsWith("Couldn't move the track"));
      expect(vm.actionError, isNot(contains('500')));
      // An action failure never becomes the page's load error.
      expect(vm.errorMessage, isNull);
      vm.dispose();
    });
  });
}

Future<(PlaylistViewModel, _FakeManagePlaylistUseCase)> _selected(
  List<Track> tracks,
) async {
  final gate = Completer<void>()..complete();
  final useCase = _FakeManagePlaylistUseCase();
  final vm = PlaylistViewModel(
    _FakePlaylistRepository(testPlaylist(), tracks, gate),
    useCase,
  );
  await vm.selectPlaylist(testPlaylist().id);
  return (vm, useCase);
}

class _FakePlaylistRepository extends Fake implements PlaylistRepository {
  _FakePlaylistRepository(this.playlist, this.tracks, this.gate);
  final Playlist playlist;
  final List<Track> tracks;
  final Completer<void> gate;

  @override
  Stream<List<Playlist>> observePlaylists() => const Stream.empty();

  @override
  Future<Result<List<Playlist>>> getAllPlaylists() async =>
      ResultHelper.success([playlist]);

  @override
  Future<Result<Playlist?>> getPlaylistById(String playlistId) async =>
      ResultHelper.success(playlist);

  @override
  Future<Result<List<Track>>> getPlaylistTracks(String playlistId) async {
    await gate.future;
    return ResultHelper.success(tracks);
  }
}

class _FakeManagePlaylistUseCase extends Fake implements ManagePlaylistUseCase {
  final calls = <ManagePlaylistParams>[];
  bool succeed = true;
  Completer<void>? gate;

  @override
  Future<Result<PlaylistOperationResult>> call(
    ManagePlaylistParams params,
  ) async {
    calls.add(params);
    if (gate != null) await gate!.future;
    return succeed
        ? ResultHelper.success(const PlaylistOperationResult.success())
        : ResultHelper.failure(const ServerFailure('500 from upstream'));
  }
}
