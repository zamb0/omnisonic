import '../entities/entities.dart';
import '../errors/result.dart';

/// Repository interface for music-related operations
abstract class MusicRepository {
  /// Gets all tracks from all connected servers
  Future<Result<List<Track>>> getAllTracks();

  /// Gets all albums from all connected servers
  Future<Result<List<Album>>> getAllAlbums();

  /// Gets all artists from all connected servers
  Future<Result<List<Artist>>> getAllArtists();

  /// Gets tracks for a specific album
  Future<Result<List<Track>>> getAlbumTracks(String albumId);

  /// Gets albums for a specific artist
  Future<Result<List<Album>>> getArtistAlbums(String artistId);

  /// Gets tracks for a specific artist
  Future<Result<List<Track>>> getArtistTracks(String artistId);

  /// Searches for tracks across all servers
  Future<Result<List<Track>>> searchTracks(String query);

  /// Searches for albums across all servers
  Future<Result<List<Album>>> searchAlbums(String query);

  /// Searches for artists across all servers
  Future<Result<List<Artist>>> searchArtists(String query);

  /// Observes the unified music collection
  Stream<UnifiedCollection> observeCollection();

  /// Syncs metadata from all connected servers
  Future<Result<void>> syncFromServers();

  /// Syncs metadata from a specific server
  Future<Result<void>> syncFromServer(String serverId);

  /// Gets recently played tracks
  Future<Result<List<Track>>> getRecentlyPlayed({int limit = 50});

  /// Gets recently added tracks
  Future<Result<List<Track>>> getRecentlyAdded({int limit = 50});

  /// Gets most played tracks
  Future<Result<List<Track>>> getMostPlayed({int limit = 50});

  /// Gets recently added albums from the server
  Future<Result<List<Album>>> getRecentlyAddedAlbums({int limit = 20});

  /// Gets recently played albums from the server
  Future<Result<List<Album>>> getRecentlyPlayedAlbums({int limit = 20});

  /// Gets most played albums from the server
  Future<Result<List<Album>>> getMostPlayedAlbums({int limit = 20});

  /// Gets all starred (favorited) albums from all servers
  Future<Result<List<Album>>> getStarredAlbums();

  /// Gets all starred (favorited) artists from all servers
  Future<Result<List<Artist>>> getStarredArtists();

  /// Gets all starred (favorited) tracks from all servers
  Future<Result<List<Track>>> getStarredTracks();

  /// Gets all available genres from all servers
  Future<Result<List<Genre>>> getGenres();

  /// Stars (favorites) an album on all servers that have it
  Future<Result<void>> starAlbum(String albumId);

  /// Unstars (removes from favorites) an album on all servers
  Future<Result<void>> unstarAlbum(String albumId);

  /// Filters tracks by various criteria
  Future<Result<List<Track>>> filterTracks({
    String? genre,
    int? year,
    String? serverId,
    AudioQuality? minQuality,
  });

  /// Gets duplicate groups for deduplication management
  Future<Result<Map<String, List<Track>>>> getDuplicateGroups();

  /// Marks tracks as duplicates manually
  Future<Result<void>> markAsDuplicates(List<String> trackIds);

  /// Marks tracks as unique (not duplicates)
  Future<Result<void>> markAsUnique(List<String> trackIds);

  /// Gets the best available source for a track from duplicate group
  Future<Result<Track>> getBestSourceForTrack(String trackId);

  /// Gets fallback source when primary source fails
  Future<Result<Track>> getFallbackSource(String trackId, String failedTrackId);

  /// Generates a stream URL for a track with unique ID
  Future<Result<String>> getTrackStreamUrl(String uniqueTrackId);

  /// DEBUG: Clear all data and resync (for testing unique IDs)
  Future<Result<void>> debugClearAndResync();
}

/// Unified collection containing all music from connected servers
class UnifiedCollection {
  const UnifiedCollection({
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.duplicateGroups,
    required this.lastUpdated,
  });

  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final Map<String, List<String>> duplicateGroups;
  final DateTime lastUpdated;

  /// Returns the total number of unique tracks (after deduplication)
  int get uniqueTrackCount => tracks.length;

  /// Returns the total number of albums
  int get albumCount => albums.length;

  /// Returns the total number of artists
  int get artistCount => artists.length;

  /// Returns the number of duplicate groups
  int get duplicateGroupCount => duplicateGroups.length;

  /// Returns true if the collection is empty
  bool get isEmpty => tracks.isEmpty && albums.isEmpty && artists.isEmpty;

  /// Returns true if the collection is not empty
  bool get isNotEmpty => !isEmpty;

  UnifiedCollection copyWith({
    List<Track>? tracks,
    List<Album>? albums,
    List<Artist>? artists,
    Map<String, List<String>>? duplicateGroups,
    DateTime? lastUpdated,
  }) {
    return UnifiedCollection(
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      duplicateGroups: duplicateGroups ?? this.duplicateGroups,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
