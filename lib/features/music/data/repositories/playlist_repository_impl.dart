import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/playlist_repository.dart';
import '../../../../core/database/data_sources/local_playlist_data_source.dart';
import '../../../../core/database/data_sources/local_music_data_source.dart';

/// Implementation of PlaylistRepository using local data sources
@LazySingleton(as: PlaylistRepository)
class PlaylistRepositoryImpl implements PlaylistRepository {
  const PlaylistRepositoryImpl({
    required LocalPlaylistDataSource localPlaylistDataSource,
    required LocalMusicDataSource localMusicDataSource,
  })  : _localPlaylistDataSource = localPlaylistDataSource,
        _localMusicDataSource = localMusicDataSource;

  final LocalPlaylistDataSource _localPlaylistDataSource;
  final LocalMusicDataSource _localMusicDataSource;

  @override
  Future<Result<Playlist>> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    return await _localPlaylistDataSource.createPlaylistWithTracks(
      name,
      [], // Start with empty track list
      description: description,
      isPublic: isPublic,
    );
  }

  @override
  Future<Result<Playlist>> updatePlaylist(Playlist playlist) async {
    final updateResult = await _localPlaylistDataSource.updatePlaylist(playlist);
    if (updateResult.isFailure) {
      return Left(updateResult.failureOrNull!);
    }

    // Return the updated playlist
    final getResult = await _localPlaylistDataSource.getPlaylistById(playlist.id);
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
    return await _localPlaylistDataSource.deletePlaylist(playlistId);
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
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(playlistId);
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    // Get all tracks and filter by playlist track IDs
    final allTracksResult = await _localMusicDataSource.getAllTracks();
    if (allTracksResult.isFailure) {
      return Left(allTracksResult.failureOrNull!);
    }

    final allTracks = allTracksResult.valueOrNull!;
    final playlistTracks = <Track>[];

    // Maintain the order of tracks as specified in the playlist
    for (final trackId in playlist.trackIds) {
      final track = allTracks.firstWhere(
        (t) => t.id == trackId,
        orElse: () => throw StateError('Track not found'),
      );
      try {
        playlistTracks.add(track);
      } catch (e) {
        // Track not found, skip it (could be deleted)
        continue;
      }
    }

    return Right(playlistTracks);
  }

  @override
  Future<Result<Playlist>> addTrackToPlaylist(String playlistId, String trackId) async {
    // Verify track exists
    final allTracksResult = await _localMusicDataSource.getAllTracks();
    if (allTracksResult.isFailure) {
      return Left(allTracksResult.failureOrNull!);
    }

    final trackExists = allTracksResult.valueOrNull!.any((track) => track.id == trackId);
    if (!trackExists) {
      return Left(DataFailure('Track not found: $trackId'));
    }

    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(playlistId);
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    // Add track to playlist
    final updatedPlaylist = playlist.addTrack(trackId);
    final updateResult = await _localPlaylistDataSource.updatePlaylist(updatedPlaylist);
    if (updateResult.isFailure) {
      return Left(updateResult.failureOrNull!);
    }

    return Right(updatedPlaylist);
  }

  @override
  Future<Result<Playlist>> removeTrackFromPlaylist(String playlistId, String trackId) async {
    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(playlistId);
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    // Remove track from playlist
    final updatedPlaylist = playlist.removeTrack(trackId);
    final updateResult = await _localPlaylistDataSource.updatePlaylist(updatedPlaylist);
    if (updateResult.isFailure) {
      return Left(updateResult.failureOrNull!);
    }

    return Right(updatedPlaylist);
  }

  @override
  Future<Result<Playlist>> reorderPlaylistTracks(String playlistId, List<String> trackIds) async {
    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(playlistId);
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    try {
      // Reorder tracks in playlist
      final updatedPlaylist = playlist.reorderTracks(trackIds);
      final updateResult = await _localPlaylistDataSource.updatePlaylist(updatedPlaylist);
      if (updateResult.isFailure) {
        return Left(updateResult.failureOrNull!);
      }

      return Right(updatedPlaylist);
    } catch (e) {
      return Left(ValidationFailure('Invalid track IDs for reordering: $e'));
    }
  }

  @override
  Future<Result<Playlist>> moveTrackInPlaylist(String playlistId, int fromIndex, int toIndex) async {
    // Get current playlist
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(playlistId);
    if (playlistResult.isFailure) {
      return Left(playlistResult.failureOrNull!);
    }

    final playlist = playlistResult.valueOrNull;
    if (playlist == null) {
      return Left(DataFailure('Playlist not found'));
    }

    try {
      // Move track in playlist
      final updatedPlaylist = playlist.moveTrack(fromIndex, toIndex);
      final updateResult = await _localPlaylistDataSource.updatePlaylist(updatedPlaylist);
      if (updateResult.isFailure) {
        return Left(updateResult.failureOrNull!);
      }

      return Right(updatedPlaylist);
    } catch (e) {
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
      final nameMatch = playlist.name.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = playlist.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
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
  Future<Result<Playlist>> duplicatePlaylist(String playlistId, String newName) async {
    return await _localPlaylistDataSource.duplicatePlaylist(playlistId, newName);
  }

  @override
  Future<Result<String>> exportPlaylist(String playlistId, {String format = 'm3u'}) async {
    // Get playlist tracks
    final tracksResult = await getPlaylistTracks(playlistId);
    if (tracksResult.isFailure) {
      return Left(tracksResult.failureOrNull!);
    }

    final tracks = tracksResult.valueOrNull!;
    
    // Get playlist info
    final playlistResult = await _localPlaylistDataSource.getPlaylistById(playlistId);
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
  Future<Result<Playlist>> importPlaylist(String content, String format, String name) async {
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
      return await _localPlaylistDataSource.createPlaylistWithTracks(name, trackIds);
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
      buffer.writeln('#EXTINF:${track.duration.inSeconds},${track.artist} - ${track.title}');
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