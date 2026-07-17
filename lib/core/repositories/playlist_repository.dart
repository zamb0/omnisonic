import '../entities/entities.dart';
import '../errors/result.dart';

/// Repository interface for playlist management operations
abstract class PlaylistRepository {
  /// Creates a new playlist
  Future<Result<Playlist>> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  });

  /// Updates an existing playlist
  Future<Result<Playlist>> updatePlaylist(Playlist playlist);

  /// Deletes a playlist by ID
  Future<Result<void>> deletePlaylist(String playlistId);

  /// Gets all playlists
  Future<Result<List<Playlist>>> getAllPlaylists();

  /// Gets a playlist by ID
  Future<Result<Playlist?>> getPlaylistById(String playlistId);

  /// Gets tracks for a specific playlist
  Future<Result<List<Track>>> getPlaylistTracks(String playlistId);

  /// Adds a track to a playlist
  Future<Result<Playlist>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  );

  /// Removes a track from a playlist
  Future<Result<Playlist>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  );

  /// Reorders tracks in a playlist
  Future<Result<Playlist>> reorderPlaylistTracks(
    String playlistId,
    List<String> trackIds,
  );

  /// Moves a track within a playlist
  Future<Result<Playlist>> moveTrackInPlaylist(
    String playlistId,
    int fromIndex,
    int toIndex,
  );

  /// Observes changes to playlists
  Stream<List<Playlist>> observePlaylists();

  /// Observes changes to a specific playlist
  Stream<Playlist?> observePlaylist(String playlistId);

  /// Searches playlists by name
  Future<Result<List<Playlist>>> searchPlaylists(String query);

  /// Gets recently created playlists
  Future<Result<List<Playlist>>> getRecentPlaylists({int limit = 10});

  /// Gets user's favorite playlists
  Future<Result<List<Playlist>>> getFavoritePlaylists();

  /// Marks a playlist as favorite
  Future<Result<void>> markPlaylistAsFavorite(String playlistId);

  /// Removes a playlist from favorites
  Future<Result<void>> removePlaylistFromFavorites(String playlistId);

  /// Duplicates a playlist
  Future<Result<Playlist>> duplicatePlaylist(String playlistId, String newName);

  /// Exports a playlist to external format
  Future<Result<String>> exportPlaylist(
    String playlistId, {
    String format = 'm3u',
  });

  /// Imports a playlist from external format
  Future<Result<Playlist>> importPlaylist(
    String content,
    String format,
    String name,
  );
}
