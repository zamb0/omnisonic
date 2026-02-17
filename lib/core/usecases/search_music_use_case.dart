import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../entities/entities.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../repositories/repositories.dart';
import 'usecase.dart';

/// Use case for searching music across all connected servers
/// 
/// This use case handles:
/// - Searching simultaneously across all connected servers
/// - Filtering results by type (tracks, albums, artists)
/// - Applying additional filters (genre, year, server, quality)
/// - Returning comprehensive search results
@injectable
class SearchMusicUseCase implements UseCase<SearchResults, SearchMusicParams> {
  const SearchMusicUseCase(
    this._musicRepository,
    this._serverRepository,
  );

  final MusicRepository _musicRepository;
  final ServerRepository _serverRepository;

  @override
  Future<Either<Failure, SearchResults>> call(SearchMusicParams params) async {
    try {
      if (params.query.trim().isEmpty) {
        return const Right(SearchResults.empty());
      }

      // Check if we have online servers
      final serversResult = await _serverRepository.getOnlineServers();
      if (serversResult.isFailure) {
        return Left(ServerFailure('Failed to get online servers: ${serversResult.failureOrNull}'));
      }

      final onlineServers = serversResult.valueOrNull!;
      if (onlineServers.isEmpty) {
        return Left(ServerFailure('No online servers available for search'));
      }

      List<Track> tracks = [];
      List<Album> albums = [];
      List<Artist> artists = [];

      // Search tracks if requested
      if (params.searchTypes.contains(SearchType.tracks)) {
        final tracksResult = await _musicRepository.searchTracks(params.query);
        if (tracksResult.isSuccess) {
          tracks = tracksResult.valueOrNull!;
          
          // Apply additional filters to tracks
          tracks = _applyTrackFilters(tracks, params);
        }
      }

      // Search albums if requested
      if (params.searchTypes.contains(SearchType.albums)) {
        final albumsResult = await _musicRepository.searchAlbums(params.query);
        if (albumsResult.isSuccess) {
          albums = albumsResult.valueOrNull!;
          
          // Apply server filter to albums if specified
          if (params.serverId != null) {
            albums = albums.where((album) => album.serverId == params.serverId).toList();
          }
        }
      }

      // Search artists if requested
      if (params.searchTypes.contains(SearchType.artists)) {
        final artistsResult = await _musicRepository.searchArtists(params.query);
        if (artistsResult.isSuccess) {
          artists = artistsResult.valueOrNull!;
          
          // Apply server filter to artists if specified
          if (params.serverId != null) {
            artists = artists.where((artist) => artist.serverId == params.serverId).toList();
          }
        }
      }

      // Apply result limits
      if (params.maxResults != null) {
        tracks = tracks.take(params.maxResults!).toList();
        albums = albums.take(params.maxResults!).toList();
        artists = artists.take(params.maxResults!).toList();
      }

      final searchResults = SearchResults(
        query: params.query,
        tracks: tracks,
        albums: albums,
        artists: artists,
        totalResults: tracks.length + albums.length + artists.length,
        searchTime: DateTime.now(),
      );

      return Right(searchResults);
    } catch (e) {
      return Left(UnknownFailure('Unexpected error during search: $e'));
    }
  }

  /// Applies additional filters to track search results
  List<Track> _applyTrackFilters(List<Track> tracks, SearchMusicParams params) {
    var filteredTracks = tracks;

    // Filter by genre
    if (params.genre != null) {
      filteredTracks = filteredTracks.where((track) => 
        track.genre?.toLowerCase().contains(params.genre!.toLowerCase()) ?? false
      ).toList();
    }

    // Filter by year
    if (params.year != null) {
      filteredTracks = filteredTracks.where((track) => track.year == params.year).toList();
    }

    // Filter by server
    if (params.serverId != null) {
      filteredTracks = filteredTracks.where((track) => track.serverId == params.serverId).toList();
    }

    // Filter by minimum quality
    if (params.minQuality != null) {
      filteredTracks = filteredTracks.where((track) => 
        track.quality.index >= params.minQuality!.index
      ).toList();
    }

    return filteredTracks;
  }
}

/// Parameters for the SearchMusicUseCase
class SearchMusicParams extends Params {
  const SearchMusicParams({
    required this.query,
    this.searchTypes = const [SearchType.tracks, SearchType.albums, SearchType.artists],
    this.genre,
    this.year,
    this.serverId,
    this.minQuality,
    this.maxResults,
  });

  /// The search query string
  final String query;
  
  /// Types of content to search for
  final List<SearchType> searchTypes;
  
  /// Optional genre filter
  final String? genre;
  
  /// Optional year filter
  final int? year;
  
  /// Optional server ID filter
  final String? serverId;
  
  /// Optional minimum audio quality filter
  final AudioQuality? minQuality;
  
  /// Optional maximum number of results per type
  final int? maxResults;

  @override
  List<Object?> get props => [
    query,
    searchTypes,
    genre,
    year,
    serverId,
    minQuality,
    maxResults,
  ];
}

/// Types of content that can be searched
enum SearchType {
  tracks,
  albums,
  artists,
}

/// Results from a music search operation
class SearchResults {
  const SearchResults({
    required this.query,
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.totalResults,
    required this.searchTime,
  });

  const SearchResults.empty()
      : query = '',
        tracks = const [],
        albums = const [],
        artists = const [],
        totalResults = 0,
        searchTime = null;

  final String query;
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final int totalResults;
  final DateTime? searchTime;

  /// Returns true if there are no results
  bool get isEmpty => totalResults == 0;
  
  /// Returns true if there are results
  bool get isNotEmpty => totalResults > 0;
  
  /// Returns true if tracks were found
  bool get hasTracks => tracks.isNotEmpty;
  
  /// Returns true if albums were found
  bool get hasAlbums => albums.isNotEmpty;
  
  /// Returns true if artists were found
  bool get hasArtists => artists.isNotEmpty;
}