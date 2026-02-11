import 'dart:async';
import 'package:rxdart/rxdart.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/music_repository.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/database/data_sources/local_music_data_source.dart';
import '../../../../core/services/subsonic_api_client.dart';
import '../../../../core/services/server_connection_service.dart';
import '../../../../core/services/deduplication_engine.dart';
import '../../../../core/services/source_selection_service.dart';
import '../../../../core/utils/id_generator.dart';

/// Implementation of MusicRepository that combines remote and local data sources
class MusicRepositoryImpl implements MusicRepository {
  final LocalMusicDataSource _localDataSource;
  final SubsonicApiClient _apiClient;
  final ServerRepository _serverRepository;
  final ServerConnectionService _connectionService;
  final DeduplicationEngine _deduplicationEngine;
  final SourceSelectionService _sourceSelectionService;
  
  // Stream controllers for reactive updates
  final _collectionController = BehaviorSubject<UnifiedCollection>();
  
  // Cache for deduplication results
  final Map<String, List<Track>> _duplicateGroupsCache = {};
  DateTime? _lastDeduplicationUpdate;
  
  MusicRepositoryImpl({
    required LocalMusicDataSource localDataSource,
    required SubsonicApiClient apiClient,
    required ServerRepository serverRepository,
    required ServerConnectionService connectionService,
    required DeduplicationEngine deduplicationEngine,
    required SourceSelectionService sourceSelectionService,
  })  : _localDataSource = localDataSource,
        _apiClient = apiClient,
        _serverRepository = serverRepository,
        _connectionService = connectionService,
        _deduplicationEngine = deduplicationEngine,
        _sourceSelectionService = sourceSelectionService;

  @override
  Future<Result<List<Track>>> getAllTracks() async {
    return await _localDataSource.getAllTracks();
  }

  @override
  Future<Result<List<Album>>> getAllAlbums() async {
    return await _localDataSource.getAllAlbums();
  }

  @override
  Future<Result<List<Artist>>> getAllArtists() async {
    return await _localDataSource.getAllArtists();
  }

  @override
  Future<Result<List<Track>>> getAlbumTracks(String albumId) async {
    // First try to get tracks from local database
    final localResult = await _localDataSource.getTracksByAlbumId(albumId);
    
    if (localResult.isSuccess && localResult.valueOrNull!.isNotEmpty) {
      return localResult;
    }
    
    // If no local tracks, fetch from server
    print('🔄 No local tracks for album $albumId, fetching from server...');
    
    try {
      // Get album details to find the server
      final albumResult = await _localDataSource.getAlbumById(albumId);
      if (albumResult.isFailure || albumResult.valueOrNull == null) {
        return ResultHelper.failure(DataFailure('Album not found'));
      }
      
      final album = albumResult.valueOrNull!;
      
      // Get server and password
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }
      
      final servers = serversResult.valueOrNull!;
      final server = servers.firstWhere(
        (s) => s.id == album.serverId,
        orElse: () => throw Exception('Server not found'),
      );
      
      final passwordResult = await _connectionService.getServerPassword(server.id);
      if (passwordResult.isFailure) {
        return ResultHelper.failure(passwordResult.failureOrNull!);
      }
      
      final password = passwordResult.valueOrNull!;
      
      // Extract original Subsonic ID and fetch from server
      final originalAlbumId = IdGenerator.extractSubsonicId(albumId);
      final albumResponse = await _apiClient.getAlbum(server, password, originalAlbumId);
      
      if (!albumResponse.isSuccess || albumResponse.data == null) {
        return ResultHelper.failure(NetworkFailure('Failed to fetch album tracks'));
      }
      
      final albumData = albumResponse.data!;
      final tracks = <Track>[];
      
      // Convert Subsonic songs to domain tracks
      for (final subsonicSong in albumData.song) {
        final streamUrl = _apiClient.getStreamUrl(server, password, subsonicSong.id);
        final domainTrack = subsonicSong.toDomainTrack(server.id, streamUrl, server, password, _apiClient);
        tracks.add(domainTrack);
      }
      
      // Save tracks to local database
      if (tracks.isNotEmpty) {
        await _localDataSource.insertTracks(tracks);
        print('✅ Fetched and saved ${tracks.length} tracks for album ${album.title}');
      }
      
      return ResultHelper.success(tracks);
    } catch (e) {
      print('❌ Error fetching album tracks: $e');
      return ResultHelper.failure(NetworkFailure('Failed to fetch album tracks: $e'));
    }
  }

  @override
  Future<Result<List<Album>>> getArtistAlbums(String artistId) async {
    return await _localDataSource.getAlbumsByArtistId(artistId);
  }

  @override
  Future<Result<List<Track>>> searchTracks(String query) async {
    return await _localDataSource.searchTracks(query);
  }

  @override
  Future<Result<List<Album>>> searchAlbums(String query) async {
    return await _localDataSource.searchAlbums(query);
  }

  @override
  Future<Result<List<Artist>>> searchArtists(String query) async {
    return await _localDataSource.searchArtists(query);
  }

  @override
  Stream<UnifiedCollection> observeCollection() {
    // Initialize stream if not already done
    if (!_collectionController.hasValue) {
      _updateUnifiedCollection();
    }
    
    return _collectionController.stream;
  }

  @override
  Future<Result<void>> syncFromServers() async {
    try {
      final serversResult = await _serverRepository.getOnlineServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!;
      final syncResults = <Result<void>>[];

      // Sync from each server in parallel
      final futures = servers.map((server) => syncFromServer(server.id));
      final results = await Future.wait(futures);
      syncResults.addAll(results);

      // Check if any sync failed
      final failures = syncResults.where((r) => r.isFailure).toList();
      if (failures.isNotEmpty) {
        // Return first failure, but log others
        return ResultHelper.failure(failures.first.failureOrNull!);
      }

      // Update unified collection after successful sync
      await _updateUnifiedCollection();
      
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Sync failed: $e'));
    }
  }

  @override
  Future<Result<void>> syncFromServer(String serverId) async {
    try {
      final serverResult = await _serverRepository.getServerById(serverId);
      if (serverResult.isFailure) {
        return ResultHelper.failure(serverResult.failureOrNull!);
      }

      final server = serverResult.valueOrNull;
      if (server == null) {
        return ResultHelper.failure(ValidationFailure('Server not found: $serverId'));
      }

      if (server.status != ServerStatus.online) {
        return ResultHelper.failure(ServerFailure('Server is offline: ${server.name}'));
      }

      // Get server password
      final passwordResult = await _connectionService.getServerPassword(serverId);
      if (passwordResult.isFailure) {
        return ResultHelper.failure(passwordResult.failureOrNull!);
      }

      final password = passwordResult.valueOrNull!;

      // Fetch data from server
      final artistsResult = await _fetchArtistsFromServer(server, password);
      final albumsResult = await _fetchAlbumsFromServer(server, password);
      final tracksResult = await _fetchTracksFromServer(server, password);

      if (artistsResult.isFailure) {
        return ResultHelper.failure(artistsResult.failureOrNull!);
      }
      if (albumsResult.isFailure) {
        return ResultHelper.failure(albumsResult.failureOrNull!);
      }
      if (tracksResult.isFailure) {
        return ResultHelper.failure(tracksResult.failureOrNull!);
      }

      // Sync data to local database
      print('🔄 Syncing to database: ${artistsResult.valueOrNull?.length ?? 0} artists, ${albumsResult.valueOrNull?.length ?? 0} albums, ${tracksResult.valueOrNull?.length ?? 0} tracks');
      final syncResult = await _localDataSource.syncMusicData(
        serverId,
        artists: artistsResult.valueOrNull,
        albums: albumsResult.valueOrNull,
        tracks: tracksResult.valueOrNull,
      );

      if (syncResult.isFailure) {
        print('❌ Database sync failed: ${syncResult.failureOrNull!.message}');
        return ResultHelper.failure(syncResult.failureOrNull!);
      }

      print('✅ Database sync completed successfully');

      // Update server last sync time
      await _serverRepository.updateLastSync(serverId, DateTime.now());

      // Update unified collection after successful sync
      await _updateUnifiedCollection();

      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Server sync failed: $e'));
    }
  }

  @override
  Future<Result<List<Track>>> getRecentlyPlayed({int limit = 50}) async {
    // This would require playback history tracking
    // For now, return empty list as this feature needs playback integration
    return ResultHelper.success([]);
  }

  @override
  Future<Result<List<Track>>> getRecentlyAdded({int limit = 50}) async {
    try {
      final allTracksResult = await _localDataSource.getAllTracks();
      if (allTracksResult.isFailure) {
        return ResultHelper.failure(allTracksResult.failureOrNull!);
      }

      final tracks = allTracksResult.valueOrNull!;
      
      // Sort by creation date (using lastModified as proxy) and take most recent
      tracks.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final recentTracks = tracks.take(limit).toList();

      return ResultHelper.success(recentTracks);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get recently added: $e'));
    }
  }

  /// Gets the best available source for a track from duplicate group
  @override
  Future<Result<Track>> getBestSourceForTrack(String trackId) async {
    try {
      // First, find which duplicate group contains this track
      final duplicateGroupsResult = await getDuplicateGroups();
      if (duplicateGroupsResult.isFailure) {
        return ResultHelper.failure(duplicateGroupsResult.failureOrNull!);
      }

      final duplicateGroups = duplicateGroupsResult.valueOrNull!;
      List<Track>? trackGroup;

      // Find the group containing the requested track
      for (final group in duplicateGroups.values) {
        if (group.any((track) => track.id == trackId)) {
          trackGroup = group;
          break;
        }
      }

      // If track is not in any duplicate group, get it directly
      if (trackGroup == null) {
        final allTracksResult = await getAllTracks();
        if (allTracksResult.isFailure) {
          return ResultHelper.failure(allTracksResult.failureOrNull!);
        }

        final track = allTracksResult.valueOrNull!
            .firstWhere((t) => t.id == trackId, orElse: () => throw StateError('Track not found'));
        
        trackGroup = [track];
      }

      // Use source selection service to get the best source
      return await _sourceSelectionService.selectBestSource(trackGroup);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get best source: $e'));
    }
  }

  /// Gets fallback source when primary source fails
  @override
  Future<Result<Track>> getFallbackSource(String trackId, String failedTrackId) async {
    try {
      final duplicateGroupsResult = await getDuplicateGroups();
      if (duplicateGroupsResult.isFailure) {
        return ResultHelper.failure(duplicateGroupsResult.failureOrNull!);
      }

      final duplicateGroups = duplicateGroupsResult.valueOrNull!;
      List<Track>? trackGroup;

      // Find the group containing the requested track
      for (final group in duplicateGroups.values) {
        if (group.any((track) => track.id == trackId)) {
          trackGroup = group;
          break;
        }
      }

      if (trackGroup == null) {
        return ResultHelper.failure(ValidationFailure('Track not found in any duplicate group'));
      }

      return await _sourceSelectionService.selectFallbackSource(trackGroup, failedTrackId);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get fallback source: $e'));
    }
  }

  @override
  Future<Result<List<Track>>> filterTracks({
    String? genre,
    int? year,
    String? serverId,
    AudioQuality? minQuality,
  }) async {
    try {
      final allTracksResult = await _localDataSource.getAllTracks();
      if (allTracksResult.isFailure) {
        return ResultHelper.failure(allTracksResult.failureOrNull!);
      }

      var tracks = allTracksResult.valueOrNull!;

      // Apply filters
      if (genre != null) {
        tracks = tracks.where((t) => t.genre?.toLowerCase() == genre.toLowerCase()).toList();
      }
      
      if (year != null) {
        tracks = tracks.where((t) => t.year == year).toList();
      }
      
      if (serverId != null) {
        tracks = tracks.where((t) => t.serverId == serverId).toList();
      }
      
      if (minQuality != null) {
        tracks = tracks.where((t) => _compareAudioQuality(t.quality, minQuality) >= 0).toList();
      }

      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to filter tracks: $e'));
    }
  }

  @override
  Future<Result<Map<String, List<Track>>>> getDuplicateGroups() async {
    try {
      // Check if we need to update deduplication cache
      final shouldUpdate = _lastDeduplicationUpdate == null ||
          DateTime.now().difference(_lastDeduplicationUpdate!) > const Duration(hours: 1);

      if (shouldUpdate || _duplicateGroupsCache.isEmpty) {
        await _updateDuplicateGroups();
      }

      return ResultHelper.success(Map.from(_duplicateGroupsCache));
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get duplicate groups: $e'));
    }
  }

  @override
  Future<Result<void>> markAsDuplicates(List<String> trackIds) async {
    // This would require implementing user preference storage
    // For now, return success as this is a future enhancement
    return ResultHelper.success(null);
  }

  @override
  Future<Result<void>> markAsUnique(List<String> trackIds) async {
    // This would require implementing user preference storage
    // For now, return success as this is a future enhancement
    return ResultHelper.success(null);
  }

  /// Fetches artists from a specific server
  Future<Result<List<Artist>>> _fetchArtistsFromServer(
    MusicServer server,
    String password,
  ) async {
    try {
      final response = await _apiClient.getArtists(server, password);
      
      if (!response.isSuccess) {
        return ResultHelper.failure(ServerFailure('Failed to fetch artists from ${server.name}'));
      }

      final artistsResponse = response.data;
      if (artistsResponse == null) {
        return ResultHelper.success([]);
      }

      // Convert Subsonic artists to domain artists
      final artists = <Artist>[];
      for (final index in artistsResponse.index) {
        for (final subsonicArtist in index.artist) {
          final domainArtist = subsonicArtist.toDomainArtist(server.id, server, password, _apiClient);
          artists.add(domainArtist);
        }
      }
      
      print('🎵 Fetched ${artists.length} artists from ${server.name}');
      return ResultHelper.success(artists);
    } catch (e) {
      print('❌ Error fetching artists: $e');
      return ResultHelper.failure(NetworkFailure('Failed to fetch artists: $e'));
    }
  }

  /// Fetches albums from a specific server
  Future<Result<List<Album>>> _fetchAlbumsFromServer(
    MusicServer server,
    String password,
  ) async {
    try {
      // Subsonic getAlbumList2 requires a 'type' parameter
      final response = await _apiClient.getAlbums(
        server, 
        password,
        type: 'alphabeticalByName', // Get albums sorted alphabetically
        size: 500, // Limit to 500 albums per request
      );
      
      if (!response.isSuccess) {
        return ResultHelper.failure(ServerFailure('Failed to fetch albums from ${server.name}'));
      }

      final albumsResponse = response.data;
      if (albumsResponse == null) {
        return ResultHelper.success([]);
      }

      // Convert Subsonic albums to domain albums
      final albums = <Album>[];
      for (final subsonicAlbum in albumsResponse.album) {
        final domainAlbum = subsonicAlbum.toDomainAlbum(server.id, server, password, _apiClient);
        albums.add(domainAlbum);
      }

      print('💿 Fetched ${albums.length} albums from ${server.name}');
      return ResultHelper.success(albums);
    } catch (e) {
      print('❌ Error fetching albums: $e');
      return ResultHelper.failure(NetworkFailure('Failed to fetch albums: $e'));
    }
  }

  /// Fetches tracks from a specific server
  Future<Result<List<Track>>> _fetchTracksFromServer(
    MusicServer server,
    String password,
  ) async {
    try {
      // First get all albums to then fetch their tracks
      final albumsResult = await _fetchAlbumsFromServer(server, password);
      if (albumsResult.isFailure) {
        return ResultHelper.failure(albumsResult.failureOrNull!);
      }

      final albums = albumsResult.valueOrNull!;
      final tracks = <Track>[];

      // Fetch tracks for each album
      for (final album in albums.take(10)) { // Limit to first 10 albums for now
        try {
          // Extract original Subsonic ID from unique ID
          final originalAlbumId = IdGenerator.extractSubsonicId(album.id);
          
          final albumResponse = await _apiClient.getAlbum(server, password, originalAlbumId);
          
          if (albumResponse.isSuccess && albumResponse.data != null) {
            final albumData = albumResponse.data!;
            
            // Convert Subsonic songs to domain tracks
            for (final subsonicSong in albumData.song) {
              final streamUrl = _apiClient.getStreamUrl(server, password, subsonicSong.id);
              final domainTrack = subsonicSong.toDomainTrack(server.id, streamUrl, server, password, _apiClient);
              tracks.add(domainTrack);
            }
          }
        } catch (e) {
          print('⚠️ Failed to fetch tracks for album ${album.title}: $e');
          // Continue with other albums
        }
      }

      print('🎵 Fetched ${tracks.length} tracks from ${server.name}');
      return ResultHelper.success(tracks);
    } catch (e) {
      print('❌ Error fetching tracks: $e');
      return ResultHelper.failure(NetworkFailure('Failed to fetch tracks: $e'));
    }
  }

  /// Updates the unified collection and notifies observers
  Future<void> _updateUnifiedCollection() async {
    try {
      print('🔄 Updating unified collection...');
      final tracksResult = await getAllTracks();
      final albumsResult = await getAllAlbums();
      final artistsResult = await getAllArtists();
      final duplicatesResult = await getDuplicateGroups();

      if (tracksResult.isSuccess && 
          albumsResult.isSuccess && 
          artistsResult.isSuccess &&
          duplicatesResult.isSuccess) {
        
        final tracks = tracksResult.valueOrNull!;
        final albums = albumsResult.valueOrNull!;
        final artists = artistsResult.valueOrNull!;
        final duplicateGroups = duplicatesResult.valueOrNull!;

        print('📊 Collection updated: ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists');

        // Convert duplicate groups to the expected format
        final duplicateGroupsMap = <String, List<String>>{};
        duplicateGroups.forEach((groupId, tracks) {
          duplicateGroupsMap[groupId] = tracks.map((t) => t.id).toList();
        });

        final collection = UnifiedCollection(
          tracks: tracks,
          albums: albums,
          artists: artists,
          duplicateGroups: duplicateGroupsMap,
          lastUpdated: DateTime.now(),
        );

        _collectionController.add(collection);
        print('✅ Unified collection updated and broadcasted');
      } else {
        print('❌ Failed to update unified collection - some data sources failed');
      }
    } catch (e) {
      // Log error but don't throw - this is for reactive updates
      print('❌ Error updating unified collection: $e');
    }
  }

  /// Updates duplicate groups cache using similarity algorithm
  Future<void> _updateDuplicateGroups() async {
    try {
      final tracksResult = await getAllTracks();
      if (tracksResult.isFailure) return;

      final tracks = tracksResult.valueOrNull!;
      
      // Use the deduplication engine to detect duplicates
      final duplicateGroups = _deduplicationEngine.detectDuplicates(tracks);
      
      _duplicateGroupsCache.clear();
      _duplicateGroupsCache.addAll(duplicateGroups);
      _lastDeduplicationUpdate = DateTime.now();
    } catch (e) {
      // Log error but don't throw
    }
  }

  /// Determines audio quality based on bitrate and format
  AudioQuality _determineAudioQuality(int? bitRate, String? suffix) {
    if (suffix?.toLowerCase() == 'flac') {
      return AudioQuality.lossless;
    }
    
    if (bitRate == null) return AudioQuality.medium;
    
    if (bitRate >= 320) return AudioQuality.high;
    if (bitRate >= 192) return AudioQuality.medium;
    return AudioQuality.low;
  }

  /// Compares audio quality levels
  int _compareAudioQuality(AudioQuality quality1, AudioQuality quality2) {
    const qualityOrder = [
      AudioQuality.low,
      AudioQuality.medium,
      AudioQuality.high,
      AudioQuality.lossless,
    ];
    
    return qualityOrder.indexOf(quality1).compareTo(qualityOrder.indexOf(quality2));
  }

  /// Generates a stream URL for a track with unique ID
  /// Extracts the original Subsonic ID and server ID to make the API call
  @override
  Future<Result<String>> getTrackStreamUrl(String uniqueTrackId) async {
    try {
      // Extract server ID and Subsonic ID from unique ID
      final serverId = IdGenerator.extractServerId(uniqueTrackId);
      final subsonicTrackId = IdGenerator.extractSubsonicId(uniqueTrackId);
      
      // Get server details
      final serverResult = await _serverRepository.getServerById(serverId);
      if (serverResult.isFailure) {
        return ResultHelper.failure(serverResult.failureOrNull!);
      }
      
      final server = serverResult.valueOrNull!;
      
      // Get server password
      final passwordResult = await _connectionService.getServerPassword(serverId);
      if (passwordResult.isFailure) {
        return ResultHelper.failure(passwordResult.failureOrNull!);
      }
      
      final password = passwordResult.valueOrNull!;
      
      // Generate stream URL using original Subsonic ID
      final streamUrl = _apiClient.getStreamUrl(server, password, subsonicTrackId);
      
      return ResultHelper.success(streamUrl);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to generate stream URL: $e'));
    }
  }

  /// DEBUG: Clear all data and resync (for testing unique IDs)
  @override
  Future<Result<void>> debugClearAndResync() async {
    try {
      print('🧹 DEBUG: Clearing all database data...');
      
      // Clear all data from database
      await _localDataSource.clearAllData();
      
      print('✅ DEBUG: Database cleared, starting fresh sync...');
      
      // Resync all servers
      final result = await syncFromServers();
      
      if (result.isSuccess) {
        print('✅ DEBUG: Fresh sync completed successfully');
      } else {
        print('❌ DEBUG: Fresh sync failed: ${result.failureOrNull}');
      }
      
      return result;
    } catch (e) {
      print('❌ DEBUG: Clear and resync failed: $e');
      return ResultHelper.failure(UnknownFailure('Debug clear and resync failed: $e'));
    }
  }

  /// Disposes resources
  void dispose() {
    _collectionController.close();
  }
}