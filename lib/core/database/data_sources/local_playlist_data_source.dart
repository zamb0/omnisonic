import '../app_database.dart';
import '../../entities/playlist.dart';
import '../../errors/result.dart';
import '../../errors/failures.dart';

/// Local data source for playlist operations
class LocalPlaylistDataSource {
  const LocalPlaylistDataSource(this._database);

  final AppDatabase _database;

  /// Get all playlists from local database
  Future<Result<List<Playlist>>> getAllPlaylists() async {
    try {
      final playlists = await _database.playlistDao.getAllPlaylists();
      return ResultHelper.success(playlists);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get playlists: $e'));
    }
  }

  /// Get playlist by ID
  Future<Result<Playlist?>> getPlaylistById(String id) async {
    try {
      final playlist = await _database.playlistDao.getPlaylistById(id);
      return ResultHelper.success(playlist);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get playlist: $e'));
    }
  }

  /// Insert playlist into local database
  Future<Result<void>> insertPlaylist(Playlist playlist) async {
    try {
      await _database.playlistDao.insertPlaylist(playlist);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to insert playlist: $e'));
    }
  }

  /// Update playlist in local database
  Future<Result<void>> updatePlaylist(Playlist playlist) async {
    try {
      await _database.playlistDao.updatePlaylist(playlist);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to update playlist: $e'));
    }
  }

  /// Delete playlist from local database
  Future<Result<void>> deletePlaylist(String id) async {
    try {
      await _database.playlistDao.deletePlaylist(id);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to delete playlist: $e'));
    }
  }

  /// Add track to playlist
  Future<Result<void>> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      await _database.playlistDao.addTrackToPlaylist(playlistId, trackId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to add track to playlist: $e'));
    }
  }

  /// Remove track from playlist
  Future<Result<void>> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      await _database.playlistDao.removeTrackFromPlaylist(playlistId, trackId);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to remove track from playlist: $e'));
    }
  }

  /// Reorder tracks in playlist
  Future<Result<void>> reorderPlaylistTracks(String playlistId, List<String> newTrackIds) async {
    try {
      await _database.playlistDao.reorderPlaylistTracks(playlistId, newTrackIds);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to reorder playlist tracks: $e'));
    }
  }

  /// Move track within playlist
  Future<Result<void>> moveTrackInPlaylist(String playlistId, int fromIndex, int toIndex) async {
    try {
      await _database.playlistDao.moveTrackInPlaylist(playlistId, fromIndex, toIndex);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to move track in playlist: $e'));
    }
  }

  /// Watch all playlists for changes
  Stream<List<Playlist>> watchAllPlaylists() {
    return _database.playlistDao.watchAllPlaylists();
  }

  /// Watch specific playlist for changes
  Stream<Playlist?> watchPlaylistById(String id) {
    return _database.playlistDao.watchPlaylistById(id);
  }

  /// Check if playlist exists
  Future<Result<bool>> playlistExists(String id) async {
    try {
      final playlist = await _database.playlistDao.getPlaylistById(id);
      return ResultHelper.success(playlist != null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to check playlist existence: $e'));
    }
  }

  /// Get playlists containing a specific track
  Future<Result<List<Playlist>>> getPlaylistsContainingTrack(String trackId) async {
    try {
      final allPlaylists = await _database.playlistDao.getAllPlaylists();
      final playlistsWithTrack = allPlaylists
          .where((playlist) => playlist.trackIds.contains(trackId))
          .toList();
      return ResultHelper.success(playlistsWithTrack);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get playlists containing track: $e'));
    }
  }

  /// Clear all playlists (for testing/reset purposes)
  Future<Result<void>> clearAllPlaylists() async {
    try {
      final playlists = await _database.playlistDao.getAllPlaylists();
      for (final playlist in playlists) {
        await _database.playlistDao.deletePlaylist(playlist.id);
      }
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to clear playlists: $e'));
    }
  }

  /// Create a new playlist with tracks
  Future<Result<Playlist>> createPlaylistWithTracks(String name, List<String> trackIds, {
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final now = DateTime.now();
      final playlist = Playlist(
        id: _generatePlaylistId(),
        name: name,
        createdAt: now,
        updatedAt: now,
        description: description,
        trackIds: trackIds,
        isPublic: isPublic,
      );

      await _database.playlistDao.insertPlaylist(playlist);
      return ResultHelper.success(playlist);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to create playlist: $e'));
    }
  }

  /// Duplicate an existing playlist
  Future<Result<Playlist>> duplicatePlaylist(String playlistId, String newName) async {
    try {
      final originalPlaylist = await _database.playlistDao.getPlaylistById(playlistId);
      if (originalPlaylist == null) {
        return ResultHelper.failure(DatabaseFailure('Original playlist not found'));
      }

      final now = DateTime.now();
      final duplicatedPlaylist = Playlist(
        id: _generatePlaylistId(),
        name: newName,
        createdAt: now,
        updatedAt: now,
        description: originalPlaylist.description,
        trackIds: List.from(originalPlaylist.trackIds),
        isPublic: false, // Duplicated playlists are private by default
      );

      await _database.playlistDao.insertPlaylist(duplicatedPlaylist);
      return ResultHelper.success(duplicatedPlaylist);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to duplicate playlist: $e'));
    }
  }

  /// Get playlist statistics
  Future<Result<Map<String, dynamic>>> getPlaylistStats() async {
    try {
      final playlists = await _database.playlistDao.getAllPlaylists();
      
      final stats = {
        'totalPlaylists': playlists.length,
        'totalTracks': playlists.fold<int>(0, (sum, playlist) => sum + playlist.trackCount),
        'averageTracksPerPlaylist': playlists.isNotEmpty 
            ? playlists.fold<int>(0, (sum, playlist) => sum + playlist.trackCount) / playlists.length
            : 0.0,
        'publicPlaylists': playlists.where((p) => p.isPublic).length,
        'privatePlaylists': playlists.where((p) => !p.isPublic).length,
        'emptyPlaylists': playlists.where((p) => p.isEmpty).length,
      };

      return ResultHelper.success(stats);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure('Failed to get playlist stats: $e'));
    }
  }

  /// Generate a unique playlist ID
  String _generatePlaylistId() {
    return 'playlist_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate a random string for ID uniqueness
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[(random + index) % chars.length]).join();
  }
}