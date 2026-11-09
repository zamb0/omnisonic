import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/services/subsonic_api_client.dart';
import '../../../../core/services/subsonic_models.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/id_generator.dart';

/// A server and the password to talk to it.
class ServerSession {
  const ServerSession(this.server, this.password);

  final MusicServer server;
  final String password;
}

/// A playlist read from a server, with the tracks its entries describe.
class ServerPlaylist {
  const ServerPlaylist({required this.playlist, required this.tracks});

  /// The playlist with app-wide IDs. Each track appears once: the local
  /// store keys a playlist's entries by track.
  final Playlist playlist;

  /// Every entry as a [Track], so a playlist can reference tracks the
  /// library has not synced yet.
  final List<Track> tracks;
}

/// The Subsonic playlist endpoints, translated to domain objects and
/// [Result]s. IDs going in and out are raw Subsonic IDs on [ServerSession]'s
/// server; the repository adds and strips the server prefix.
@lazySingleton
class ServerPlaylistDataSource {
  ServerPlaylistDataSource(this._api, this._servers);

  final SubsonicApiClient _api;
  final ServerRepository _servers;

  /// The server with [serverId] and its stored password.
  Future<Result<ServerSession>> session(String serverId) async {
    final server = (await _servers.getServerById(serverId)).valueOrNull;
    if (server == null) {
      return ResultHelper.failure(
        ValidationFailure('the playlist\'s server is no longer set up.'),
      );
    }
    final password = (await _servers.getCredentials(server.id)).valueOrNull;
    if (password == null) {
      return ResultHelper.failure(
        AuthenticationFailure('No password stored for ${server.name}'),
      );
    }
    return ResultHelper.success(ServerSession(server, password));
  }

  /// The playlists the user can see on the server, without their entries.
  Future<Result<List<SubsonicPlaylist>>> list(ServerSession session) =>
      _guard(() async {
        final response = await _api.getPlaylists(
          session.server,
          session.password,
        );
        return response.data?.playlist ?? const <SubsonicPlaylist>[];
      });

  /// One playlist with its entries.
  Future<Result<ServerPlaylist>> fetch(
    ServerSession session,
    String playlistId,
  ) => _guard(() async {
    final response = await _api.getPlaylist(
      session.server,
      session.password,
      playlistId,
    );
    final data = response.data;
    if (data == null) {
      throw SubsonicApiException('Playlist $playlistId not found', '70');
    }
    return toServerPlaylist(session, data);
  });

  /// Creates a playlist holding [songIds] and returns its ID.
  Future<Result<String>> create(
    ServerSession session,
    String name, {
    List<String> songIds = const [],
  }) => _guard(() async {
    final response = await _api.createPlaylist(
      session.server,
      session.password,
      name: name,
      songIds: songIds,
    );
    final created = response.data;
    if (created != null) return created.id;

    // Servers before API 1.14 answer with nothing: find the playlist just
    // made, the newest one with this name.
    final all =
        (await _api.getPlaylists(
          session.server,
          session.password,
        )).data?.playlist ??
        const <SubsonicPlaylist>[];
    final named = all.where((p) => p.name == name).toList()
      ..sort(
        (a, b) =>
            (b.created ?? DateTime(0)).compareTo(a.created ?? DateTime(0)),
      );
    if (named.isEmpty) {
      throw SubsonicApiException('Created playlist "$name" not found', null);
    }
    return named.first.id;
  });

  /// Changes details and/or adds and removes entries.
  Future<Result<void>> update(
    ServerSession session,
    String playlistId, {
    String? name,
    String? comment,
    bool? isPublic,
    List<String> songIdsToAdd = const [],
    List<int> songIndexesToRemove = const [],
  }) => _guard(
    () => _api.updatePlaylist(
      session.server,
      session.password,
      playlistId,
      name: name,
      comment: comment,
      isPublic: isPublic,
      songIdsToAdd: songIdsToAdd,
      songIndexesToRemove: songIndexesToRemove,
    ),
  );

  /// Replaces the playlist's entries with [songIds], in that order.
  Future<Result<void>> replaceEntries(
    ServerSession session,
    String playlistId,
    List<String> songIds,
  ) => _guard(
    () => _api.createPlaylist(
      session.server,
      session.password,
      playlistId: playlistId,
      songIds: songIds,
    ),
  );

  /// The raw entry IDs of the playlist, in server order, duplicates kept.
  Future<Result<List<String>>> entryIds(
    ServerSession session,
    String playlistId,
  ) => _guard(() async {
    final response = await _api.getPlaylist(
      session.server,
      session.password,
      playlistId,
    );
    return [for (final song in response.data?.entry ?? const []) song.id];
  });

  Future<Result<void>> delete(ServerSession session, String playlistId) =>
      _guard(
        () => _api.deletePlaylist(session.server, session.password, playlistId),
      );

  /// Maps a server playlist to domain objects with app-wide IDs.
  ServerPlaylist toServerPlaylist(ServerSession session, SubsonicPlaylist p) {
    final server = session.server;
    final tracks = [
      for (final song in p.entry ?? const <SubsonicSong>[])
        song.toDomainTrack(
          server.id,
          _api.getStreamUrl(server, session.password, song.id),
          server,
          session.password,
          _api,
        ),
    ];
    final trackIds = <String>[];
    final seen = <String>{};
    for (final track in tracks) {
      if (seen.add(track.id)) trackIds.add(track.id);
    }

    final created = p.created ?? p.changed ?? DateTime.now();
    return ServerPlaylist(
      playlist: Playlist(
        id: IdGenerator.generateUniqueId(server.id, p.id),
        name: p.name,
        createdAt: created,
        updatedAt: p.changed ?? created,
        description: (p.comment?.isEmpty ?? true) ? null : p.comment,
        trackIds: trackIds,
        duration: p.duration == null ? null : Duration(seconds: p.duration!),
        isPublic: p.public ?? false,
        coverArtUrl: p.coverArt == null || p.coverArt!.isEmpty
            ? null
            : _api.getCoverArtUrl(server, session.password, p.coverArt!),
        owner: p.owner,
      ),
      tracks: tracks,
    );
  }

  /// Runs a request, turning the client's exceptions into failures.
  Future<Result<T>> _guard<T>(Future<T> Function() request) async {
    try {
      return ResultHelper.success(await request());
    } on AuthenticationException catch (e) {
      return ResultHelper.failure(AuthenticationFailure(e.message));
    } on NetworkException catch (e) {
      return ResultHelper.failure(NetworkFailure(e.message));
    } on SubsonicApiException catch (e) {
      AppLog.warn('Playlist request refused: ${e.message} (${e.code})');
      // The server answered and said no: say why, rather than the generic
      // "didn't respond" a ServerFailure reads as.
      return ResultHelper.failure(switch (e.code) {
        '50' => const ValidationFailure(
          'the server doesn\'t allow this account to change that playlist.',
        ),
        '70' => const ValidationFailure(
          'the playlist is no longer on the server.',
        ),
        _ => ServerFailure(e.message, e.code),
      });
    } on ServerException catch (e) {
      AppLog.warn('Playlist request refused: ${e.message}');
      return ResultHelper.failure(ServerFailure(e.message));
    } catch (e) {
      AppLog.warn('Playlist request failed: $e');
      return ResultHelper.failure(UnknownFailure('$e'));
    }
  }
}
