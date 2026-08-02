import 'dart:async';
import 'package:flutter/foundation.dart';
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
import '../../../../core/utils/app_log.dart';

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

  /// How many albums a single `getAlbumList2` call asks for. Subsonic caps
  /// this at 500, so it doubles as the paging stride.
  static const int _albumPageSize = 500;

  /// How many `getAlbum` requests are kept in flight while fetching tracks.
  /// Sequential fetching makes a first sync take one round-trip per album.
  static const int _albumFetchConcurrency = 6;

  MusicRepositoryImpl({
    required LocalMusicDataSource localDataSource,
    required SubsonicApiClient apiClient,
    required ServerRepository serverRepository,
    required ServerConnectionService connectionService,
    required DeduplicationEngine deduplicationEngine,
    required SourceSelectionService sourceSelectionService,
  }) : _localDataSource = localDataSource,
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
    AppLog.info('No local tracks for album, fetching from server');

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

      final passwordResult = await _connectionService.getServerPassword(
        server.id,
      );
      if (passwordResult.isFailure) {
        return ResultHelper.failure(passwordResult.failureOrNull!);
      }

      final password = passwordResult.valueOrNull!;

      // Extract original Subsonic ID and fetch from server
      final originalAlbumId = IdGenerator.extractSubsonicId(albumId);
      final albumResponse = await _apiClient.getAlbum(
        server,
        password,
        originalAlbumId,
      );

      if (!albumResponse.isSuccess || albumResponse.data == null) {
        return ResultHelper.failure(
          NetworkFailure('Failed to fetch album tracks'),
        );
      }

      final albumData = albumResponse.data!;
      final tracks = <Track>[];

      // Convert Subsonic songs to domain tracks
      for (final subsonicSong in albumData.song) {
        final streamUrl = _apiClient.getStreamUrl(
          server,
          password,
          subsonicSong.id,
        );
        final domainTrack = subsonicSong.toDomainTrack(
          server.id,
          streamUrl,
          server,
          password,
          _apiClient,
        );
        tracks.add(domainTrack);
      }

      // Save tracks to local database
      if (tracks.isNotEmpty) {
        await _localDataSource.insertTracks(tracks);
        AppLog.info('Fetched and saved ${tracks.length} tracks for album');
      }

      return ResultHelper.success(tracks);
    } catch (e) {
      AppLog.warn('Error fetching album tracks: $e');
      return ResultHelper.failure(
        NetworkFailure('Failed to fetch album tracks: $e'),
      );
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
        return ResultHelper.failure(
          ValidationFailure('Server not found: $serverId'),
        );
      }

      if (server.status != ServerStatus.online) {
        return ResultHelper.failure(
          ServerFailure('Server is offline: ${server.name}'),
        );
      }

      // Get server password
      final passwordResult = await _connectionService.getServerPassword(
        serverId,
      );
      if (passwordResult.isFailure) {
        return ResultHelper.failure(passwordResult.failureOrNull!);
      }

      final password = passwordResult.valueOrNull!;

      // Fetch data from server
      final artistsResult = await _fetchArtistsFromServer(server, password);
      if (artistsResult.isFailure) {
        return ResultHelper.failure(artistsResult.failureOrNull!);
      }

      final albumsResult = await _fetchAlbumsFromServer(server, password);
      if (albumsResult.isFailure) {
        return ResultHelper.failure(albumsResult.failureOrNull!);
      }

      // Tracks are fetched per album, so reuse the albums we already have
      // instead of asking the server for the same list twice.
      final tracksResult = await _fetchTracksFromServer(
        server,
        password,
        albumsResult.valueOrNull!,
      );
      if (tracksResult.isFailure) {
        return ResultHelper.failure(tracksResult.failureOrNull!);
      }

      // Sync data to local database
      AppLog.info(
        'Syncing to database: ${artistsResult.valueOrNull?.length ?? 0} artists, ${albumsResult.valueOrNull?.length ?? 0} albums, ${tracksResult.valueOrNull?.length ?? 0} tracks',
      );
      final syncResult = await _localDataSource.syncMusicData(
        serverId,
        artists: artistsResult.valueOrNull,
        albums: albumsResult.valueOrNull,
        tracks: tracksResult.valueOrNull,
      );

      if (syncResult.isFailure) {
        AppLog.warn(
          'Database sync failed: ${syncResult.failureOrNull!.message}',
        );
        return ResultHelper.failure(syncResult.failureOrNull!);
      }

      AppLog.info('Database sync completed successfully');

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
    try {
      // Get all active servers
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allTracks = <Track>[];

      // Get recently played albums from each server
      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final albumsResponse = await _apiClient.getAlbums(
            server,
            password,
            type: 'recent',
            size: limit,
          );

          if (albumsResponse.isSuccess && albumsResponse.data?.album != null) {
            // Get tracks from each album
            for (final album in albumsResponse.data!.album.take(10)) {
              try {
                final albumDetailResponse = await _apiClient.getAlbum(
                  server,
                  password,
                  album.id,
                );
                if (albumDetailResponse.isSuccess &&
                    albumDetailResponse.data?.song != null) {
                  for (final song in albumDetailResponse.data!.song) {
                    final streamUrl = _apiClient.getStreamUrl(
                      server,
                      password,
                      song.id,
                    );
                    final track = song.toDomainTrack(
                      server.id,
                      streamUrl,
                      server,
                      password,
                      _apiClient,
                    );
                    allTracks.add(track);
                  }
                }
              } catch (e) {
                AppLog.warn('Failed to get tracks for album ${album.id}: $e');
              }
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get recently played from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allTracks.take(limit).toList());
    } catch (e) {
      AppLog.warn('Error getting recently played: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get recently played: $e'),
      );
    }
  }

  @override
  Future<Result<List<Track>>> getRecentlyAdded({int limit = 50}) async {
    try {
      // Get all active servers
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allTracks = <Track>[];

      // Get recently added albums from each server
      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final albumsResponse = await _apiClient.getAlbums(
            server,
            password,
            type: 'newest',
            size: limit,
          );

          if (albumsResponse.isSuccess && albumsResponse.data?.album != null) {
            // Get tracks from each album
            for (final album in albumsResponse.data!.album.take(10)) {
              try {
                final albumDetailResponse = await _apiClient.getAlbum(
                  server,
                  password,
                  album.id,
                );
                if (albumDetailResponse.isSuccess &&
                    albumDetailResponse.data?.song != null) {
                  for (final song in albumDetailResponse.data!.song) {
                    final streamUrl = _apiClient.getStreamUrl(
                      server,
                      password,
                      song.id,
                    );
                    final track = song.toDomainTrack(
                      server.id,
                      streamUrl,
                      server,
                      password,
                      _apiClient,
                    );
                    allTracks.add(track);
                  }
                }
              } catch (e) {
                AppLog.warn('Failed to get tracks for album ${album.id}: $e');
              }
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get recently added from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allTracks.take(limit).toList());
    } catch (e) {
      AppLog.warn('Error getting recently added: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get recently added: $e'),
      );
    }
  }

  @override
  Future<Result<List<Track>>> getMostPlayed({int limit = 50}) async {
    try {
      // Get all active servers
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allTracks = <Track>[];

      // Get most played albums from each server
      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final albumsResponse = await _apiClient.getAlbums(
            server,
            password,
            type: 'frequent',
            size: limit,
          );

          if (albumsResponse.isSuccess && albumsResponse.data?.album != null) {
            // Get tracks from each album
            for (final album in albumsResponse.data!.album.take(10)) {
              try {
                final albumDetailResponse = await _apiClient.getAlbum(
                  server,
                  password,
                  album.id,
                );
                if (albumDetailResponse.isSuccess &&
                    albumDetailResponse.data?.song != null) {
                  for (final song in albumDetailResponse.data!.song) {
                    final streamUrl = _apiClient.getStreamUrl(
                      server,
                      password,
                      song.id,
                    );
                    final track = song.toDomainTrack(
                      server.id,
                      streamUrl,
                      server,
                      password,
                      _apiClient,
                    );
                    allTracks.add(track);
                  }
                }
              } catch (e) {
                AppLog.warn('Failed to get tracks for album ${album.id}: $e');
              }
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get most played from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allTracks.take(limit).toList());
    } catch (e) {
      AppLog.warn('Error getting most played: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get most played: $e'),
      );
    }
  }

  @override
  Future<Result<List<Album>>> getRecentlyAddedAlbums({int limit = 20}) async {
    try {
      // Get all active servers
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allAlbums = <Album>[];

      // Get recently added albums from each server
      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final albumsResponse = await _apiClient.getAlbums(
            server,
            password,
            type: 'newest',
            size: limit,
          );

          if (albumsResponse.isSuccess && albumsResponse.data?.album != null) {
            for (final album in albumsResponse.data!.album) {
              allAlbums.add(
                album.toDomainAlbum(server.id, server, password, _apiClient),
              );
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get recently added albums from server ${server.name}: $e',
          );
        }
      }

      // Sort by last modified and limit
      allAlbums.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return ResultHelper.success(allAlbums.take(limit).toList());
    } catch (e) {
      AppLog.warn('Error getting recently added albums: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get recently added albums: $e'),
      );
    }
  }

  @override
  Future<Result<List<Album>>> getRecentlyPlayedAlbums({int limit = 20}) async {
    try {
      // Get all active servers
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allAlbums = <Album>[];

      // Get recently played albums from each server
      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final albumsResponse = await _apiClient.getAlbums(
            server,
            password,
            type: 'recent',
            size: limit,
          );

          if (albumsResponse.isSuccess && albumsResponse.data?.album != null) {
            for (final album in albumsResponse.data!.album) {
              allAlbums.add(
                album.toDomainAlbum(server.id, server, password, _apiClient),
              );
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get recently played albums from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allAlbums.take(limit).toList());
    } catch (e) {
      AppLog.warn('Error getting recently played albums: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get recently played albums: $e'),
      );
    }
  }

  @override
  Future<Result<List<Album>>> getMostPlayedAlbums({int limit = 20}) async {
    try {
      // Get all active servers
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allAlbums = <Album>[];

      // Get most played albums from each server
      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final albumsResponse = await _apiClient.getAlbums(
            server,
            password,
            type: 'frequent',
            size: limit,
          );

          if (albumsResponse.isSuccess && albumsResponse.data?.album != null) {
            for (final album in albumsResponse.data!.album) {
              allAlbums.add(
                album.toDomainAlbum(server.id, server, password, _apiClient),
              );
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get most played albums from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allAlbums.take(limit).toList());
    } catch (e) {
      AppLog.warn('Error getting most played albums: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get most played albums: $e'),
      );
    }
  }

  @override
  Future<Result<List<Album>>> getStarredAlbums() async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allStarredAlbums = <Album>[];

      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final starredResponse = await _apiClient.getStarred2(
            server,
            password,
          );

          if (starredResponse.isSuccess &&
              starredResponse.data?.album != null) {
            for (final album in starredResponse.data!.album!) {
              allStarredAlbums.add(
                album.toDomainAlbum(server.id, server, password, _apiClient),
              );
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get starred albums from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allStarredAlbums);
    } catch (e) {
      AppLog.warn('Error getting starred albums: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get starred albums: $e'),
      );
    }
  }

  @override
  Future<Result<List<Artist>>> getStarredArtists() async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allStarredArtists = <Artist>[];

      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final starredResponse = await _apiClient.getStarred2(
            server,
            password,
          );

          if (starredResponse.isSuccess &&
              starredResponse.data?.artist != null) {
            for (final artist in starredResponse.data!.artist!) {
              allStarredArtists.add(
                artist.toDomainArtist(server.id, server, password, _apiClient),
              );
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get starred artists from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allStarredArtists);
    } catch (e) {
      AppLog.warn('Error getting starred artists: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get starred artists: $e'),
      );
    }
  }

  @override
  Future<Result<List<Track>>> getStarredTracks() async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allStarredTracks = <Track>[];

      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final starredResponse = await _apiClient.getStarred2(
            server,
            password,
          );

          if (starredResponse.isSuccess && starredResponse.data?.song != null) {
            for (final song in starredResponse.data!.song!) {
              final streamUrl = _apiClient.getStreamUrl(
                server,
                password,
                song.id,
              );
              allStarredTracks.add(
                song.toDomainTrack(
                  server.id,
                  streamUrl,
                  server,
                  password,
                  _apiClient,
                ),
              );
            }
          }
        } catch (e) {
          AppLog.warn(
            'Failed to get starred tracks from server ${server.name}: $e',
          );
        }
      }

      return ResultHelper.success(allStarredTracks);
    } catch (e) {
      AppLog.warn('Error getting starred tracks: $e');
      return ResultHelper.failure(
        UnknownFailure('Failed to get starred tracks: $e'),
      );
    }
  }

  @override
  Future<Result<List<Genre>>> getGenres() async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success([]);
      }

      final allGenres = <Genre>[];
      final genreNames = <String>{};

      for (final server in servers) {
        try {
          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          final genresResponse = await _apiClient.getGenres(server, password);

          if (genresResponse.isSuccess && genresResponse.data?.genre != null) {
            for (final genre in genresResponse.data!.genre) {
              // Deduplicate genres by name across servers
              if (!genreNames.contains(genre.name)) {
                genreNames.add(genre.name);
                allGenres.add(genre.toDomain());
              }
            }
          }
        } catch (e) {
          AppLog.warn('Failed to get genres from server ${server.name}: $e');
        }
      }

      // Sort genres alphabetically
      allGenres.sort((a, b) => a.name.compareTo(b.name));

      return ResultHelper.success(allGenres);
    } catch (e) {
      AppLog.warn('Error getting genres: $e');
      return ResultHelper.failure(UnknownFailure('Failed to get genres: $e'));
    }
  }

  @override
  Future<Result<void>> starAlbum(String albumId) async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success(null);
      }

      for (final server in servers) {
        try {
          // Extract the original album ID from the unique ID if needed
          final originalAlbumId = albumId.contains('|')
              ? albumId.split('|')[1]
              : albumId;

          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          await _apiClient.star(server, password, albumId: originalAlbumId);

          AppLog.info('⭐ Starred album $albumId on server ${server.name}');
        } catch (e) {
          AppLog.warn('Failed to star album on server ${server.name}: $e');
        }
      }

      return ResultHelper.success(null);
    } catch (e) {
      AppLog.warn('Error starring album: $e');
      return ResultHelper.failure(UnknownFailure('Failed to star album: $e'));
    }
  }

  @override
  Future<Result<void>> unstarAlbum(String albumId) async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      if (serversResult.isFailure) {
        return ResultHelper.failure(serversResult.failureOrNull!);
      }

      final servers = serversResult.valueOrNull!
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        return ResultHelper.success(null);
      }

      for (final server in servers) {
        try {
          // Extract the original album ID from the unique ID if needed
          final originalAlbumId = albumId.contains('|')
              ? albumId.split('|')[1]
              : albumId;

          final passwordResult = await _connectionService.getServerPassword(
            server.id,
          );
          if (passwordResult.isFailure) continue;

          final password = passwordResult.valueOrNull!;
          await _apiClient.unstar(server, password, albumId: originalAlbumId);

          AppLog.info('⭐ Unstarred album $albumId on server ${server.name}');
        } catch (e) {
          AppLog.warn('Failed to unstar album on server ${server.name}: $e');
        }
      }

      return ResultHelper.success(null);
    } catch (e) {
      AppLog.warn('Error unstarring album: $e');
      return ResultHelper.failure(UnknownFailure('Failed to unstar album: $e'));
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

        final track = allTracksResult.valueOrNull!.firstWhere(
          (t) => t.id == trackId,
          orElse: () => throw StateError('Track not found'),
        );

        trackGroup = [track];
      }

      // Use source selection service to get the best source
      return await _sourceSelectionService.selectBestSource(trackGroup);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get best source: $e'),
      );
    }
  }

  /// Gets fallback source when primary source fails
  @override
  Future<Result<Track>> getFallbackSource(
    String trackId,
    String failedTrackId,
  ) async {
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
        return ResultHelper.failure(
          ValidationFailure('Track not found in any duplicate group'),
        );
      }

      return await _sourceSelectionService.selectFallbackSource(
        trackGroup,
        failedTrackId,
      );
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get fallback source: $e'),
      );
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
        tracks = tracks
            .where((t) => t.genre?.toLowerCase() == genre.toLowerCase())
            .toList();
      }

      if (year != null) {
        tracks = tracks.where((t) => t.year == year).toList();
      }

      if (serverId != null) {
        tracks = tracks.where((t) => t.serverId == serverId).toList();
      }

      if (minQuality != null) {
        tracks = tracks
            .where((t) => _compareAudioQuality(t.quality, minQuality) >= 0)
            .toList();
      }

      return ResultHelper.success(tracks);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to filter tracks: $e'),
      );
    }
  }

  @override
  Future<Result<Map<String, List<Track>>>> getDuplicateGroups() async {
    try {
      // Check if we need to update deduplication cache
      final shouldUpdate =
          _lastDeduplicationUpdate == null ||
          DateTime.now().difference(_lastDeduplicationUpdate!) >
              const Duration(hours: 1);

      if (shouldUpdate || _duplicateGroupsCache.isEmpty) {
        await _updateDuplicateGroups();
      }

      return ResultHelper.success(Map.from(_duplicateGroupsCache));
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to get duplicate groups: $e'),
      );
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
        return ResultHelper.failure(
          ServerFailure('Failed to fetch artists from ${server.name}'),
        );
      }

      final artistsResponse = response.data;
      if (artistsResponse == null) {
        return ResultHelper.success([]);
      }

      // Convert Subsonic artists to domain artists
      final artists = <Artist>[];
      for (final index in artistsResponse.index) {
        for (final subsonicArtist in index.artist) {
          final domainArtist = subsonicArtist.toDomainArtist(
            server.id,
            server,
            password,
            _apiClient,
          );
          artists.add(domainArtist);
        }
      }

      AppLog.info('Fetched ${artists.length} artists from server');
      return ResultHelper.success(artists);
    } catch (e) {
      AppLog.warn('Error fetching artists: $e');
      return ResultHelper.failure(
        NetworkFailure('Failed to fetch artists: $e'),
      );
    }
  }

  /// Fetches albums from a specific server
  Future<Result<List<Album>>> _fetchAlbumsFromServer(
    MusicServer server,
    String password,
  ) async {
    try {
      // getAlbumList2 caps a single response at `_albumPageSize`, so page
      // through it until a short page comes back — otherwise libraries larger
      // than one page are silently truncated.
      final albums = <Album>[];

      for (var offset = 0; ; offset += _albumPageSize) {
        // Subsonic getAlbumList2 requires a 'type' parameter
        final response = await _apiClient.getAlbums(
          server,
          password,
          type: 'alphabeticalByName', // Get albums sorted alphabetically
          size: _albumPageSize,
          offset: offset,
        );

        if (!response.isSuccess) {
          return ResultHelper.failure(
            ServerFailure('Failed to fetch albums from ${server.name}'),
          );
        }

        final page = response.data?.album ?? const [];
        if (page.isEmpty) break;

        // Convert Subsonic albums to domain albums
        for (final subsonicAlbum in page) {
          final domainAlbum = subsonicAlbum.toDomainAlbum(
            server.id,
            server,
            password,
            _apiClient,
          );
          albums.add(domainAlbum);
        }

        if (page.length < _albumPageSize) break;
      }

      AppLog.info('Fetched ${albums.length} albums from server');
      return ResultHelper.success(albums);
    } catch (e) {
      AppLog.warn('Error fetching albums: $e');
      return ResultHelper.failure(NetworkFailure('Failed to fetch albums: $e'));
    }
  }

  /// Fetches the tracks of [albums] from [server].
  ///
  /// Albums come from the caller because the sync already fetched them; asking
  /// the server for the same list again just doubles the round-trips.
  Future<Result<List<Track>>> _fetchTracksFromServer(
    MusicServer server,
    String password,
    List<Album> albums,
  ) async {
    try {
      final tracks = <Track>[];

      // Fetch tracks for every album, a few requests at a time.
      for (var start = 0; start < albums.length; start += _albumFetchConcurrency) {
        final batch = albums.skip(start).take(_albumFetchConcurrency);

        final batchTracks = await Future.wait(
          batch.map((album) => _fetchAlbumTracks(server, password, album)),
        );

        for (final albumTracks in batchTracks) {
          tracks.addAll(albumTracks);
        }
      }

      AppLog.info('Fetched ${tracks.length} tracks from server');
      return ResultHelper.success(tracks);
    } catch (e) {
      AppLog.warn('Error fetching tracks: $e');
      return ResultHelper.failure(NetworkFailure('Failed to fetch tracks: $e'));
    }
  }

  /// Fetches the tracks of a single album, returning an empty list on failure
  /// so one bad album cannot abort the whole sync.
  Future<List<Track>> _fetchAlbumTracks(
    MusicServer server,
    String password,
    Album album,
  ) async {
    try {
      // Extract original Subsonic ID from unique ID
      final originalAlbumId = IdGenerator.extractSubsonicId(album.id);

      final albumResponse = await _apiClient.getAlbum(
        server,
        password,
        originalAlbumId,
      );

      if (!albumResponse.isSuccess || albumResponse.data == null) {
        return const [];
      }

      // Convert Subsonic songs to domain tracks
      return albumResponse.data!.song.map((subsonicSong) {
        final streamUrl = _apiClient.getStreamUrl(
          server,
          password,
          subsonicSong.id,
        );
        return subsonicSong.toDomainTrack(
          server.id,
          streamUrl,
          server,
          password,
          _apiClient,
        );
      }).toList();
    } catch (e) {
      AppLog.warn('Failed to fetch tracks for album ${album.id}: $e');
      return const [];
    }
  }

  /// Updates the unified collection and notifies observers
  Future<void> _updateUnifiedCollection() async {
    try {
      AppLog.debug('Updating unified collection');
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

        AppLog.info(
          'Collection updated: ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists',
        );

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
        AppLog.debug('Unified collection updated and broadcasted');
      } else {
        AppLog.warn(
          'Failed to update unified collection - some data sources failed',
        );
      }
    } catch (e) {
      // Log error but don't throw - this is for reactive updates
      AppLog.warn('Error updating unified collection: $e');
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

  /// Compares audio quality levels
  int _compareAudioQuality(AudioQuality quality1, AudioQuality quality2) {
    return quality1.qualityScore.compareTo(quality2.qualityScore);
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
      final passwordResult = await _connectionService.getServerPassword(
        serverId,
      );
      if (passwordResult.isFailure) {
        return ResultHelper.failure(passwordResult.failureOrNull!);
      }

      final password = passwordResult.valueOrNull!;

      // Generate stream URL using original Subsonic ID
      final streamUrl = _apiClient.getStreamUrl(
        server,
        password,
        subsonicTrackId,
      );

      return ResultHelper.success(streamUrl);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to generate stream URL: $e'),
      );
    }
  }

  /// DEBUG: Clear all data and resync (for testing unique IDs)
  @override
  Future<Result<void>> debugClearAndResync() async {
    if (!kDebugMode) {
      return ResultHelper.failure(
        ValidationFailure('Debug operation not available in release builds'),
      );
    }

    try {
      AppLog.debug('Debug clear and resync started');

      // Clear all data from database
      await _localDataSource.clearAllData();

      AppLog.debug('Database cleared, starting fresh sync');

      // Resync all servers
      final result = await syncFromServers();

      if (result.isSuccess) {
        AppLog.info('Debug fresh sync completed successfully');
      } else {
        AppLog.warn('Debug fresh sync failed: ${result.failureOrNull}');
      }

      return result;
    } catch (e) {
      AppLog.warn('Debug clear and resync failed: $e');
      return ResultHelper.failure(
        UnknownFailure('Debug clear and resync failed: $e'),
      );
    }
  }

  /// Disposes resources
  void dispose() {
    _collectionController.close();
  }
}
