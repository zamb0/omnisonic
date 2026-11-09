import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/music_repository.dart';
import '../../../../core/repositories/playlist_repository.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/database/data_sources/local_playlist_data_source.dart';
import '../../../../core/database/data_sources/local_music_data_source.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/id_generator.dart';
import '../datasources/server_playlist_data_source.dart';

/// Playlists, local and on the servers.
///
/// A local playlist ([Playlist.isLocal]) lives only in the database and can
/// mix tracks from every server. A server playlist is mirrored from its
/// server, which stays the source of truth: every change is sent there first
/// and the playlist is then read back and stored, so the local copy is always
/// what the server has. [syncFromServers] brings in changes made elsewhere
/// (the server's web UI, another client).
@LazySingleton(as: PlaylistRepository)
class PlaylistRepositoryImpl implements PlaylistRepository {
  const PlaylistRepositoryImpl({
    required LocalPlaylistDataSource localPlaylistDataSource,
    required LocalMusicDataSource localMusicDataSource,
    required ServerPlaylistDataSource serverPlaylistDataSource,
    required ServerRepository serverRepository,
    required MusicRepository musicRepository,
  }) : _localPlaylistDataSource = localPlaylistDataSource,
       _localMusicDataSource = localMusicDataSource,
       _remote = serverPlaylistDataSource,
       _serverRepository = serverRepository,
       _musicRepository = musicRepository;

  final LocalPlaylistDataSource _localPlaylistDataSource;
  final LocalMusicDataSource _localMusicDataSource;
  final ServerPlaylistDataSource _remote;
  final ServerRepository _serverRepository;
  final MusicRepository _musicRepository;

  /// How many playlists are fetched from one server at a time during a sync.
  static const int _fetchConcurrency = 4;

  @override
  Future<Result<Playlist>> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
    String? serverId,
  }) async {
    if (serverId == null) {
      return await _localPlaylistDataSource.createPlaylistWithTracks(
        name,
        [], // Start with empty track list
        description: description,
        isPublic: isPublic,
      );
    }

    final session = await _remote.session(serverId);
    if (session.isFailure) return Left(session.failureOrNull!);
    final s = session.valueOrNull!;

    final created = await _remote.create(s, name);
    if (created.isFailure) return Left(created.failureOrNull!);
    final remoteId = created.valueOrNull!;

    // createPlaylist only takes a name; the rest is a second call.
    if ((description?.isNotEmpty ?? false) || isPublic) {
      final details = await _remote.update(
        s,
        remoteId,
        comment: description,
        isPublic: isPublic,
      );
      if (details.isFailure) {
        AppLog.warn(
          'Playlist created but its details were not saved: '
          '${details.failureOrNull!.message}',
        );
      }
    }
    return _refresh(s, remoteId);
  }

  @override
  Future<Result<Playlist>> updatePlaylist(Playlist playlist) async {
    if (playlist.isLocal) {
      final updateResult = await _localPlaylistDataSource.updatePlaylist(
        playlist,
      );
      if (updateResult.isFailure) {
        return Left(updateResult.failureOrNull!);
      }
    } else {
      final previous = await _localPlaylistDataSource.getPlaylistById(
        playlist.id,
      );
      if (previous.isFailure) return Left(previous.failureOrNull!);
      if (previous.valueOrNull == null) {
        return Left(DataFailure('Playlist not found'));
      }
      return _commit(previous.valueOrNull!, playlist);
    }

    // Return the updated playlist
    final getResult = await _localPlaylistDataSource.getPlaylistById(
      playlist.id,
    );
    if (getResult.isFailure) {
      return Left(getResult.failureOrNull!);
    }

    final updatedPlaylist = getResult.valueOrNull;
    if (updatedPlaylist == null) {
      return Left(DataFailure('Playlist not found after update'));
    }

    return Right(updatedPlaylist);
  }

  @override
  Future<Result<void>> deletePlaylist(String playlistId) async {
    final playlist = (await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    )).valueOrNull;
    if (playlist != null && !playlist.isLocal) {
      final session = await _remote.session(playlist.serverId!);
      if (session.isFailure) return Left(session.failureOrNull!);
      final s = session.valueOrNull!;
      final readOnly = _readOnly(s, playlist);
      if (readOnly != null) return Left(readOnly);

      final deleted = await _remote.delete(
        s,
        IdGenerator.extractSubsonicId(playlist.id),
      );
      if (deleted.isFailure) return Left(deleted.failureOrNull!);
    }
    return await _localPlaylistDataSource.deletePlaylist(playlistId);
  }

  @override
  Future<Result<void>> syncFromServers() async {
    final servers = (await _serverRepository.getAllServers()).valueOrNull;
    final available = [
      for (final server in servers ?? const <MusicServer>[])
        if (server.isAvailable) server,
    ];
    if (available.isEmpty) return const Right(null);

    final results = await Future.wait(available.map(_syncServer));
    final failures = [
      for (final result in results)
        if (result.isFailure) result.failureOrNull!,
    ];
    for (final failure in failures) {
      AppLog.warn('Playlist sync failed: ${failure.message}');
    }
    // One unreachable server should not hide the others' playlists.
    return failures.length == results.length
        ? Left(failures.first)
        : const Right(null);
  }

  /// Mirrors one server's playlists: new and changed ones are fetched and
  /// stored, ones gone from the server are dropped.
  Future<Result<void>> _syncServer(MusicServer server) async {
    final session = await _remote.session(server.id);
    if (session.isFailure) return Left(session.failureOrNull!);
    final s = session.valueOrNull!;

    final listed = await _remote.list(s);
    if (listed.isFailure) return Left(listed.failureOrNull!);

    final stored =
        (await _localPlaylistDataSource.getAllPlaylists()).valueOrNull;
    final known = {
      for (final playlist in stored ?? const <Playlist>[])
        if (playlist.serverId == server.id) playlist.id: playlist,
    };

    final toFetch = <String>[];
    for (final remote in listed.valueOrNull!) {
      final id = IdGenerator.generateUniqueId(server.id, remote.id);
      final local = known.remove(id);
      // `changed` moves on every edit, so an unchanged one needs no request
      // for its entries. Stored dates keep whole seconds only.
      final unchanged =
          local != null &&
          remote.changed != null &&
          local.updatedAt.millisecondsSinceEpoch ~/ 1000 ==
              remote.changed!.millisecondsSinceEpoch ~/ 1000;
      if (!unchanged) toFetch.add(remote.id);
    }

    for (var start = 0; start < toFetch.length; start += _fetchConcurrency) {
      await Future.wait(
        toFetch.skip(start).take(_fetchConcurrency).map((remoteId) async {
          final refreshed = await _refresh(s, remoteId);
          if (refreshed.isFailure) {
            AppLog.warn(
              'Could not sync playlist $remoteId from ${server.name}: '
              '${refreshed.failureOrNull!.message}',
            );
          }
        }),
      );
    }

    // Deleted on the server (or no longer shared with this user).
    for (final gone in known.values) {
      await _localPlaylistDataSource.deletePlaylist(gone.id);
    }
    return const Right(null);
  }

  /// Reads a playlist back from its server and stores it.
  Future<Result<Playlist>> _refresh(ServerSession s, String remoteId) async {
    final fetched = await _remote.fetch(s, remoteId);
    if (fetched.isFailure) return Left(fetched.failureOrNull!);
    final serverPlaylist = fetched.valueOrNull!;

    // Entries can name tracks the library has not synced yet; the store
    // needs them to exist. Tracks already there are left as they are.
    final ids = serverPlaylist.playlist.trackIds;
    final existing = (await _localMusicDataSource.getTracksByIds(
      ids,
    )).valueOrNull;
    final have = {for (final track in existing ?? const <Track>[]) track.id};
    final missing = <String, Track>{
      for (final track in serverPlaylist.tracks)
        if (!have.contains(track.id)) track.id: track,
    };
    if (missing.isNotEmpty) {
      final inserted = await _localMusicDataSource.insertTracks(
        missing.values.toList(),
      );
      if (inserted.isFailure) return Left(inserted.failureOrNull!);
    }

    final saved = await _localPlaylistDataSource.savePlaylist(
      serverPlaylist.playlist,
    );
    if (saved.isFailure) return Left(saved.failureOrNull!);
    return Right(serverPlaylist.playlist);
  }

  /// Applies the change from [previous] to [updated]: locally for a local
  /// playlist, on the server (then read back) for a server one.
  Future<Result<Playlist>> _commit(Playlist previous, Playlist updated) async {
    if (updated.isLocal) {
      final result = await _localPlaylistDataSource.updatePlaylist(updated);
      if (result.isFailure) return Left(result.failureOrNull!);
      return Right(updated);
    }

    final session = await _remote.session(previous.serverId!);
    if (session.isFailure) return Left(session.failureOrNull!);
    final s = session.valueOrNull!;
    final readOnly = _readOnly(s, previous);
    if (readOnly != null) return Left(readOnly);

    final remoteId = IdGenerator.extractSubsonicId(previous.id);
    final detailsChanged =
        updated.name != previous.name ||
        (updated.description ?? '') != (previous.description ?? '') ||
        updated.isPublic != previous.isPublic;
    if (detailsChanged) {
      final result = await _remote.update(
        s,
        remoteId,
        name: updated.name,
        // An empty comment clears it; null would leave the old one.
        comment: updated.description ?? '',
        isPublic: updated.isPublic,
      );
      if (result.isFailure) return Left(result.failureOrNull!);
    }

    if (!_sameIds(previous.trackIds, updated.trackIds)) {
      final result = await _pushEntries(
        s,
        remoteId,
        previous.trackIds,
        updated.trackIds,
      );
      if (result.isFailure) return Left(result.failureOrNull!);
    }

    return _refresh(s, remoteId);
  }

  /// Sends a change of entries with the smallest request that expresses it:
  /// an append, a removal, or — for anything else, e.g. a reorder, which
  /// the API has no call for — the whole list.
  Future<Result<void>> _pushEntries(
    ServerSession s,
    String remoteId,
    List<String> before,
    List<String> after,
  ) async {
    final songIds = [for (final id in after) IdGenerator.extractSubsonicId(id)];

    if (after.length == before.length + 1 &&
        _sameIds(before, after.sublist(0, before.length))) {
      return _remote.update(s, remoteId, songIdsToAdd: [songIds.last]);
    }

    if (after.length == before.length - 1) {
      final removed = before.where((id) => !after.contains(id)).firstOrNull;
      if (removed != null && _sameIds([...before]..remove(removed), after)) {
        // Removal goes by position on the server, which may list the track
        // more than once: every occurrence goes, as the user saw just one.
        final entries = await _remote.entryIds(s, remoteId);
        if (entries.isFailure) return Left(entries.failureOrNull!);
        final song = IdGenerator.extractSubsonicId(removed);
        final indexes = [
          for (var i = 0; i < entries.valueOrNull!.length; i++)
            if (entries.valueOrNull![i] == song) i,
        ];
        if (indexes.isEmpty) return const Right(null);
        return _remote.update(s, remoteId, songIndexesToRemove: indexes);
      }
    }

    return _remote.replaceEntries(s, remoteId, songIds);
  }

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Why [playlist] cannot be changed by this account, or null if it can.
  ///
  /// Other users' public playlists are listed too, and only their owner may
  /// change them.
  Failure? _readOnly(ServerSession s, Playlist playlist) {
    final owner = playlist.owner;
    if (owner == null || owner.isEmpty || owner == s.server.username) {
      return null;
    }
    return ValidationFailure(
      '"${playlist.name}" belongs to $owner on ${s.server.name}, so only '
      'they can change it.',
    );
  }

  /// The ID of [trackId]'s copy on [serverId]: itself if it is already
  /// there, otherwise a duplicate the library merged it with.
  ///
  /// A server playlist can only hold that server's tracks.
  Future<Result<String>> _trackOnServer(String trackId, String serverId) async {
    if (IdGenerator.extractServerId(trackId) == serverId) {
      return Right(trackId);
    }

    final groups = (await _musicRepository.getDuplicateGroups()).valueOrNull;
    for (final group in groups?.values ?? const <List<Track>>[]) {
      if (!group.any((t) => t.id == trackId)) continue;
      final copy = group.where((t) => t.serverId == serverId).firstOrNull;
      if (copy != null) return Right(copy.id);
    }

    final track = (await _localMusicDataSource.getTrackById(
      trackId,
    )).valueOrNull;
    final server = (await _serverRepository.getServerById(
      serverId,
    )).valueOrNull;
    return Left(
      ValidationFailure(
        '"${track?.title ?? 'This track'}" isn\'t on '
        '${server?.name ?? 'that server'}, so it can\'t go in a playlist '
        'there.',
      ),
    );
  }

  @override
  Future<Result<List<Playlist>>> getAllPlaylists() async {
    return await _localPlaylistDataSource.getAllPlaylists();
  }

  @override
  Future<Result<Playlist?>> getPlaylistById(String playlistId) async {
    return await _localPlaylistDataSource.getPlaylistById(playlistId);
  }

  @override
  Future<Result<List<Track>>> getPlaylistTracks(String playlistId) async {
    // Get the playlist first
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    );
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    // Load only the tracks this playlist references
    final tracksResult = await _localMusicDataSource.getTracksByIds(
      playlist.trackIds,
    );
    if (tracksResult.isFailure) {
      return Left(tracksResult.failureOrNull!);
    }

    final tracksById = {
      for (final track in tracksResult.valueOrNull!) track.id: track,
    };

    // Maintain the order of tracks as specified in the playlist, skipping the
    // ones that are no longer in the library.
    final playlistTracks = <Track>[];
    for (final trackId in playlist.trackIds) {
      final track = tracksById[trackId];
      if (track != null) {
        playlistTracks.add(track);
      }
    }

    return Right(playlistTracks);
  }

  @override
  Future<Result<Playlist>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    // Verify track exists — by primary key, not by scanning the library
    final trackResult = await _localMusicDataSource.getTrackById(trackId);
    if (trackResult.isFailure) {
      return Left(trackResult.failureOrNull!);
    }
    if (trackResult.valueOrNull == null) {
      return Left(DataFailure('Track not found: $trackId'));
    }

    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    );
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    var toAdd = trackId;
    if (!playlist.isLocal) {
      final onServer = await _trackOnServer(trackId, playlist.serverId!);
      if (onServer.isFailure) return Left(onServer.failureOrNull!);
      toAdd = onServer.valueOrNull!;
    }

    final updatedPlaylist = playlist.addTrack(toAdd);
    if (identical(updatedPlaylist, playlist)) return Right(playlist);
    return _commit(playlist, updatedPlaylist);
  }

  @override
  Future<Result<Playlist>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    );
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    var toRemove = trackId;
    // The track may have gone in as its copy on the playlist's server (see
    // addTrackToPlaylist), e.g. when undoing that add.
    if (!playlist.isLocal && !playlist.trackIds.contains(trackId)) {
      final onServer = await _trackOnServer(trackId, playlist.serverId!);
      if (onServer.isSuccess) toRemove = onServer.valueOrNull!;
    }

    final updatedPlaylist = playlist.removeTrack(toRemove);
    if (identical(updatedPlaylist, playlist)) return Right(playlist);
    return _commit(playlist, updatedPlaylist);
  }

  @override
  Future<Result<Playlist>> reorderPlaylistTracks(
    String playlistId,
    List<String> trackIds,
  ) async {
    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    );
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    try {
      final updatedPlaylist = playlist.reorderTracks(trackIds);
      return await _commit(playlist, updatedPlaylist);
    } on ArgumentError catch (e) {
      return Left(ValidationFailure('Invalid track IDs for reordering: $e'));
    }
  }

  @override
  Future<Result<Playlist>> moveTrackInPlaylist(
    String playlistId,
    int fromIndex,
    int toIndex,
  ) async {
    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    );
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    try {
      final updatedPlaylist = playlist.moveTrack(fromIndex, toIndex);
      return await _commit(playlist, updatedPlaylist);
    } on RangeError catch (e) {
      return Left(ValidationFailure('Invalid indices for moving track: $e'));
    }
  }

  @override
  Stream<List<Playlist>> observePlaylists() {
    return _localPlaylistDataSource.watchAllPlaylists();
  }

  @override
  Stream<Playlist?> observePlaylist(String playlistId) {
    return _localPlaylistDataSource.watchPlaylistById(playlistId);
  }

  @override
  Future<Result<List<Playlist>>> searchPlaylists(String query) async {
    final allPlaylistsResult = await _localPlaylistDataSource.getAllPlaylists();
    if (allPlaylistsResult.isFailure) {
      return Left(allPlaylistsResult.failureOrNull!);
    }

    final allPlaylists = allPlaylistsResult.valueOrNull!;
    final filteredPlaylists = allPlaylists.where((playlist) {
      final nameMatch = playlist.name.toLowerCase().contains(
        query.toLowerCase(),
      );
      final descriptionMatch =
          playlist.description?.toLowerCase().contains(query.toLowerCase()) ??
          false;
      return nameMatch || descriptionMatch;
    }).toList();

    return Right(filteredPlaylists);
  }

  @override
  Future<Result<List<Playlist>>> getRecentPlaylists({int limit = 10}) async {
    final allPlaylistsResult = await _localPlaylistDataSource.getAllPlaylists();
    if (allPlaylistsResult.isFailure) {
      return Left(allPlaylistsResult.failureOrNull!);
    }

    final allPlaylists = allPlaylistsResult.valueOrNull!;
    allPlaylists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentPlaylists = allPlaylists.take(limit).toList();

    return Right(recentPlaylists);
  }

  @override
  Future<Result<List<Playlist>>> getFavoritePlaylists() async {
    // For now, return empty list as favorites functionality is not implemented
    // This would typically involve a separate favorites table or flag
    return Right(<Playlist>[]);
  }

  @override
  Future<Result<void>> markPlaylistAsFavorite(String playlistId) async {
    // Placeholder implementation - would need favorites table
    return Right(null);
  }

  @override
  Future<Result<void>> removePlaylistFromFavorites(String playlistId) async {
    // Placeholder implementation - would need favorites table
    return Right(null);
  }

  @override
  Future<Result<Playlist>> duplicatePlaylist(
    String playlistId,
    String newName,
  ) async {
    final source = (await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    )).valueOrNull;
    if (source == null || source.isLocal) {
      return await _localPlaylistDataSource.duplicatePlaylist(
        playlistId,
        newName,
      );
    }

    // A copy of a server playlist goes on the same server, as a new
    // playlist this account owns, whoever owned the original.
    final session = await _remote.session(source.serverId!);
    if (session.isFailure) return Left(session.failureOrNull!);
    final s = session.valueOrNull!;
    final created = await _remote.create(
      s,
      newName,
      songIds: [
        for (final id in source.trackIds) IdGenerator.extractSubsonicId(id),
      ],
    );
    if (created.isFailure) return Left(created.failureOrNull!);
    return _refresh(s, created.valueOrNull!);
  }

  @override
  Future<Result<String>> exportPlaylist(
    String playlistId, {
    String format = 'm3u',
  }) async {
    // Get playlist tracks
    final tracksResult = await getPlaylistTracks(playlistId);
    if (tracksResult.isFailure) {
      return Left(tracksResult.failureOrNull!);
    }

    final tracks = tracksResult.valueOrNull!;

    // Get playlist info
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(
      playlistId,
    );
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    // Generate export content based on format
    switch (format.toLowerCase()) {
      case 'm3u':
        return Right(_generateM3UContent(playlist, tracks));
      case 'pls':
        return Right(_generatePLSContent(playlist, tracks));
      default:
        return Left(ValidationFailure('Unsupported export format: $format'));
    }
  }

  @override
  Future<Result<Playlist>> importPlaylist(
    String content,
    String format,
    String name,
  ) async {
    try {
      List<String> trackIds;

      switch (format.toLowerCase()) {
        case 'm3u':
          trackIds = _parseM3UContent(content);
          break;
        case 'pls':
          trackIds = _parsePLSContent(content);
          break;
        default:
          return Left(ValidationFailure('Unsupported import format: $format'));
      }

      // Create playlist with parsed track IDs
      return await _localPlaylistDataSource.createPlaylistWithTracks(
        name,
        trackIds,
      );
    } catch (e) {
      return Left(DataFailure('Failed to import playlist: $e'));
    }
  }

  /// Generate M3U playlist content
  String _generateM3UContent(Playlist playlist, List<Track> tracks) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#PLAYLIST:${playlist.name}');

    for (final track in tracks) {
      buffer.writeln(
        '#EXTINF:${track.duration.inSeconds},${track.artist} - ${track.title}',
      );
      buffer.writeln(track.streamUrl);
    }

    return buffer.toString();
  }

  /// Generate PLS playlist content
  String _generatePLSContent(Playlist playlist, List<Track> tracks) {
    final buffer = StringBuffer();
    buffer.writeln('[playlist]');

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final index = i + 1;
      buffer.writeln('File$index=${track.streamUrl}');
      buffer.writeln('Title$index=${track.artist} - ${track.title}');
      buffer.writeln('Length$index=${track.duration.inSeconds}');
    }

    buffer.writeln('NumberOfEntries=${tracks.length}');
    buffer.writeln('Version=2');

    return buffer.toString();
  }

  /// Parse M3U playlist content to extract track IDs
  List<String> _parseM3UContent(String content) {
    // Simplified parsing - in real implementation, would need to match URLs to track IDs
    final lines = content.split('\n');
    final trackIds = <String>[];

    for (final line in lines) {
      if (line.trim().isNotEmpty && !line.startsWith('#')) {
        // This would need to match the URL to an existing track ID
        // For now, just use the line as a placeholder
        trackIds.add('track_${trackIds.length}');
      }
    }

    return trackIds;
  }

  /// Parse PLS playlist content to extract track IDs
  List<String> _parsePLSContent(String content) {
    // Simplified parsing - in real implementation, would need to match URLs to track IDs
    final lines = content.split('\n');
    final trackIds = <String>[];

    for (final line in lines) {
      if (line.startsWith('File')) {
        // This would need to match the URL to an existing track ID
        // For now, just use a placeholder
        trackIds.add('track_${trackIds.length}');
      }
    }

    return trackIds;
  }
}
