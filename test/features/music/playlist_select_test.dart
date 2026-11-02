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

class _FakeManagePlaylistUseCase extends Fake
    implements ManagePlaylistUseCase {}
