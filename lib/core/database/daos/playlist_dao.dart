import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import '../../entities/playlist.dart';

part 'playlist_dao.g.dart';

@DriftAccessor(tables: [PlaylistsTable, PlaylistTracksTable])
class PlaylistDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistDaoMixin {
  PlaylistDao(super.db);

  // Convert between entity and database models
  Playlist _fromData(PlaylistData data, List<String> trackIds) {
    return Playlist(
      id: data.id,
      name: data.name,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      description: data.description,
      trackIds: trackIds,
      duration: data.durationMs != null
          ? Duration(milliseconds: data.durationMs!)
          : null,
      isPublic: data.isPublic,
      coverArtUrl: data.coverArtUrl,
      owner: data.owner,
    );
  }

  PlaylistsTableCompanion _toCompanion(Playlist playlist) {
    return PlaylistsTableCompanion(
      id: Value(playlist.id),
      name: Value(playlist.name),
      createdAt: Value(playlist.createdAt),
      updatedAt: Value(playlist.updatedAt),
      description: Value.absentIfNull(playlist.description),
      durationMs: Value.absentIfNull(playlist.duration?.inMilliseconds),
      isPublic: Value(playlist.isPublic),
      coverArtUrl: Value.absentIfNull(playlist.coverArtUrl),
      owner: Value.absentIfNull(playlist.owner),
    );
  }

  // CRUD operations
  Future<List<Playlist>> getAllPlaylists() async {
    final playlistsData = await select(playlistsTable).get();
    if (playlistsData.isEmpty) return const [];

    // One query for every playlist's tracks instead of one query per
    // playlist, which is what the loop over _getPlaylistTrackIds cost.
    final entries = await (select(
      playlistTracksTable,
    )..orderBy([(tbl) => OrderingTerm(expression: tbl.position)])).get();

    final trackIdsByPlaylist = <String, List<String>>{};
    for (final entry in entries) {
      trackIdsByPlaylist
          .putIfAbsent(entry.playlistId, () => [])
          .add(entry.trackId);
    }

    return [
      for (final playlistData in playlistsData)
        _fromData(
          playlistData,
          trackIdsByPlaylist[playlistData.id] ?? const [],
        ),
    ];
  }

  Future<Playlist?> getPlaylistById(String id) async {
    final playlistData = await (select(
      playlistsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (playlistData == null) return null;

    final trackIds = await _getPlaylistTrackIds(id);
    return _fromData(playlistData, trackIds);
  }

  Future<List<String>> _getPlaylistTrackIds(String playlistId) async {
    final trackData =
        await (select(playlistTracksTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId))
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.position)]))
            .get();
    return trackData.map((data) => data.trackId).toList();
  }

  Future<void> insertPlaylist(Playlist playlist) async {
    await transaction(() async {
      // Insert playlist
      await into(playlistsTable).insert(_toCompanion(playlist));

      // Insert playlist tracks
      await _insertPlaylistTracks(playlist.id, playlist.trackIds);
    });
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await transaction(() async {
      // Update playlist
      await update(playlistsTable).replace(_toCompanion(playlist));

      // Delete existing tracks and insert new ones
      await (delete(
        playlistTracksTable,
      )..where((tbl) => tbl.playlistId.equals(playlist.id))).go();
      await _insertPlaylistTracks(playlist.id, playlist.trackIds);
    });
  }

  /// Inserts [playlist] or overwrites every column of the stored one, then
  /// replaces its tracks.
  Future<void> upsertPlaylist(Playlist playlist) async {
    await transaction(() async {
      await into(playlistsTable).insertOnConflictUpdate(
        PlaylistsTableCompanion(
          id: Value(playlist.id),
          name: Value(playlist.name),
          createdAt: Value(playlist.createdAt),
          updatedAt: Value(playlist.updatedAt),
          // Explicit nulls: a description cleared on the server has to clear
          // here too, which an absent value would not.
          description: Value(playlist.description),
          durationMs: Value(playlist.duration?.inMilliseconds),
          isPublic: Value(playlist.isPublic),
          coverArtUrl: Value(playlist.coverArtUrl),
          owner: Value(playlist.owner),
        ),
      );
      await (delete(
        playlistTracksTable,
      )..where((tbl) => tbl.playlistId.equals(playlist.id))).go();
      await _insertPlaylistTracks(playlist.id, playlist.trackIds);
    });
  }

  Future<void> _insertPlaylistTracks(
    String playlistId,
    List<String> trackIds,
  ) async {
    final companions = trackIds.asMap().entries.map((entry) {
      return PlaylistTracksTableCompanion(
        playlistId: Value(playlistId),
        trackId: Value(entry.value),
        position: Value(entry.key),
      );
    }).toList();

    if (companions.isNotEmpty) {
      await batch((batch) {
        batch.insertAll(playlistTracksTable, companions);
      });
    }
  }

  Future<void> deletePlaylist(String id) async {
    await transaction(() async {
      // Delete playlist tracks first (due to foreign key)
      await (delete(
        playlistTracksTable,
      )..where((tbl) => tbl.playlistId.equals(id))).go();

      // Delete playlist
      await (delete(playlistsTable)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  // Playlist track operations
  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    // Get current max position
    final maxPositionQuery = selectOnly(playlistTracksTable)
      ..addColumns([playlistTracksTable.position.max()])
      ..where(playlistTracksTable.playlistId.equals(playlistId));

    final maxPositionResult = await maxPositionQuery.getSingleOrNull();
    final nextPosition =
        (maxPositionResult?.read(playlistTracksTable.position.max()) ?? -1) + 1;

    await into(playlistTracksTable).insert(
      PlaylistTracksTableCompanion(
        playlistId: Value(playlistId),
        trackId: Value(trackId),
        position: Value(nextPosition),
      ),
    );

    // Update playlist updated_at
    await (update(playlistsTable)..where((tbl) => tbl.id.equals(playlistId)))
        .write(PlaylistsTableCompanion(updatedAt: Value(DateTime.now())));
  }

  Future<void> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    await transaction(() async {
      // Get the position of the track to remove
      final trackToRemove =
          await (select(playlistTracksTable)..where(
                (tbl) =>
                    tbl.playlistId.equals(playlistId) &
                    tbl.trackId.equals(trackId),
              ))
              .getSingleOrNull();

      if (trackToRemove == null) return;

      // Remove the track
      await (delete(playlistTracksTable)..where(
            (tbl) =>
                tbl.playlistId.equals(playlistId) & tbl.trackId.equals(trackId),
          ))
          .go();

      // Update positions of tracks that come after the removed track
      await customUpdate(
        'UPDATE playlist_tracks SET position = position - 1 '
        'WHERE playlist_id = ? AND position > ?',
        variables: [
          Variable.withString(playlistId),
          Variable.withInt(trackToRemove.position),
        ],
        updates: {playlistTracksTable},
      );

      // Update playlist updated_at
      await (update(playlistsTable)..where((tbl) => tbl.id.equals(playlistId)))
          .write(PlaylistsTableCompanion(updatedAt: Value(DateTime.now())));
    });
  }

  Future<void> reorderPlaylistTracks(
    String playlistId,
    List<String> newTrackIds,
  ) async {
    await transaction(() async {
      // Delete existing tracks
      await (delete(
        playlistTracksTable,
      )..where((tbl) => tbl.playlistId.equals(playlistId))).go();

      // Insert tracks in new order
      await _insertPlaylistTracks(playlistId, newTrackIds);

      // Update playlist updated_at
      await (update(playlistsTable)..where((tbl) => tbl.id.equals(playlistId)))
          .write(PlaylistsTableCompanion(updatedAt: Value(DateTime.now())));
    });
  }

  Future<void> moveTrackInPlaylist(
    String playlistId,
    int fromIndex,
    int toIndex,
  ) async {
    final trackIds = await _getPlaylistTrackIds(playlistId);

    if (fromIndex < 0 ||
        fromIndex >= trackIds.length ||
        toIndex < 0 ||
        toIndex >= trackIds.length) {
      throw RangeError('Invalid index for moving track');
    }

    final trackId = trackIds.removeAt(fromIndex);
    trackIds.insert(toIndex, trackId);

    await reorderPlaylistTracks(playlistId, trackIds);
  }

  // Watch for changes
  Stream<List<Playlist>> watchAllPlaylists() {
    return select(playlistsTable).watch().asyncMap((playlistsData) async {
      final playlists = <Playlist>[];
      for (final playlistData in playlistsData) {
        final trackIds = await _getPlaylistTrackIds(playlistData.id);
        playlists.add(_fromData(playlistData, trackIds));
      }
      return playlists;
    });
  }

  Stream<Playlist?> watchPlaylistById(String id) {
    return (select(playlistsTable)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((playlistData) async {
          if (playlistData == null) return null;
          final trackIds = await _getPlaylistTrackIds(id);
          return _fromData(playlistData, trackIds);
        });
  }
}
