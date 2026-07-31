import '../entities/track.dart';
import '../entities/audio_quality.dart';
import '../entities/server_status.dart';
import '../repositories/server_repository.dart';
import '../errors/result.dart';
import '../errors/failures.dart';

/// Service responsible for selecting the best available source for track playback
class SourceSelectionService {
  final ServerRepository _serverRepository;

  SourceSelectionService({required ServerRepository serverRepository})
    : _serverRepository = serverRepository;

  /// Selects the best available track from a list of duplicate tracks
  /// Based on audio quality, server availability, and other factors
  Future<Result<Track>> selectBestSource(List<Track> duplicateTracks) async {
    if (duplicateTracks.isEmpty) {
      return ResultHelper.failure(
        ValidationFailure('No tracks provided for source selection'),
      );
    }

    if (duplicateTracks.length == 1) {
      final track = duplicateTracks.first;
      final isAvailable = await _isTrackAvailable(track);

      if (isAvailable) {
        return ResultHelper.success(track);
      } else {
        return ResultHelper.failure(
          ServerFailure('Track source is unavailable'),
        );
      }
    }

    // Get server statuses for all tracks
    final trackAvailability = <Track, bool>{};
    for (final track in duplicateTracks) {
      trackAvailability[track] = await _isTrackAvailable(track);
    }

    // Filter to only available tracks
    final availableTracks = duplicateTracks
        .where((track) => trackAvailability[track] == true)
        .toList();

    if (availableTracks.isEmpty) {
      return ResultHelper.failure(
        ServerFailure('No available sources for track'),
      );
    }

    // Rank tracks by quality and other factors
    final rankedTracks = await _rankTracksByQuality(availableTracks);

    return ResultHelper.success(rankedTracks.first);
  }

  /// Ranks tracks by quality, with fallback logic for unavailable sources
  Future<List<Track>> _rankTracksByQuality(List<Track> tracks) async {
    final trackScores = <Track, double>{};

    for (final track in tracks) {
      double score = 0.0;

      // Audio quality score (0-50 points)
      score += _getQualityScore(track.quality);

      // Cached content bonus (0-20 points)
      if (track.isCached) {
        score += 20.0;
      }

      // File size bonus (0-15 points) - larger files generally better quality
      if (track.fileSize != null) {
        // Normalize file size to 0-15 range (assuming max ~100MB for a song)
        final sizeScore = (track.fileSize! / (100 * 1024 * 1024)) * 15;
        score += sizeScore.clamp(0.0, 15.0);
      }

      // Server reliability bonus (0-10 points)
      final serverScore = await _getServerReliabilityScore(track.serverId);
      score += serverScore;

      // Recency bonus (0-5 points) - prefer more recently synced content
      final recencyScore = _getRecencyScore(track.lastModified);
      score += recencyScore;

      trackScores[track] = score;
    }

    // Sort by score (highest first)
    final sortedTracks = tracks.toList();
    sortedTracks.sort((a, b) => trackScores[b]!.compareTo(trackScores[a]!));

    return sortedTracks;
  }

  /// Gets quality score based on audio quality enum
  double _getQualityScore(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.ultra:
        return 50.0;
      case AudioQuality.lossless:
        return 45.0;
      case AudioQuality.high:
        return 35.0;
      case AudioQuality.medium:
        return 25.0;
      case AudioQuality.low:
        return 15.0;
    }
  }

  /// Gets server reliability score based on server status and history
  Future<double> _getServerReliabilityScore(String serverId) async {
    try {
      final serverResult = await _serverRepository.getServerById(serverId);
      if (serverResult.isFailure) return 0.0;

      final server = serverResult.valueOrNull;
      if (server == null) return 0.0;

      switch (server.status) {
        case ServerStatus.online:
          return 10.0;
        case ServerStatus.offline:
          return 0.0;
        case ServerStatus.connecting:
          return 5.0;
        case ServerStatus.authenticating:
          return 3.0;
        case ServerStatus.syncing:
          return 7.0;
        case ServerStatus.error:
          return 2.0;
      }
    } catch (e) {
      return 0.0;
    }
  }

  /// Gets recency score based on when the track was last modified/synced
  double _getRecencyScore(DateTime lastModified) {
    final now = DateTime.now();
    final daysSinceModified = now.difference(lastModified).inDays;

    if (daysSinceModified <= 1) return 5.0;
    if (daysSinceModified <= 7) return 4.0;
    if (daysSinceModified <= 30) return 3.0;
    if (daysSinceModified <= 90) return 2.0;
    if (daysSinceModified <= 365) return 1.0;

    return 0.0;
  }

  /// Checks if a track is available for playback
  Future<bool> _isTrackAvailable(Track track) async {
    try {
      // Check if track is cached locally
      if (track.isCached && track.cachePath != null) {
        // In a real implementation, you'd check if the file exists
        return true;
      }

      // Check server availability
      final serverResult = await _serverRepository.getServerById(
        track.serverId,
      );
      if (serverResult.isFailure) return false;

      final server = serverResult.valueOrNull;
      if (server == null) return false;

      return server.status == ServerStatus.online;
    } catch (e) {
      return false;
    }
  }

  /// Provides fallback track selection when primary source fails
  Future<Result<Track>> selectFallbackSource(
    List<Track> duplicateTracks,
    String failedTrackId,
  ) async {
    // Remove the failed track from consideration
    final availableTracks = duplicateTracks
        .where((track) => track.id != failedTrackId)
        .toList();

    if (availableTracks.isEmpty) {
      return ResultHelper.failure(
        ServerFailure('No fallback sources available'),
      );
    }

    return selectBestSource(availableTracks);
  }

  /// Gets all available sources for a track, ranked by quality
  Future<Result<List<Track>>> getAvailableSources(
    List<Track> duplicateTracks,
  ) async {
    final availableTracks = <Track>[];

    for (final track in duplicateTracks) {
      final isAvailable = await _isTrackAvailable(track);
      if (isAvailable) {
        availableTracks.add(track);
      }
    }

    if (availableTracks.isEmpty) {
      return ResultHelper.failure(ServerFailure('No available sources'));
    }

    final rankedTracks = await _rankTracksByQuality(availableTracks);
    return ResultHelper.success(rankedTracks);
  }

  /// Checks server availability for a specific server
  Future<bool> checkServerAvailability(String serverId) async {
    try {
      final serverResult = await _serverRepository.getServerById(serverId);
      if (serverResult.isFailure) return false;

      final server = serverResult.valueOrNull;
      if (server == null) return false;

      return server.status == ServerStatus.online;
    } catch (e) {
      return false;
    }
  }

  /// Updates server availability status
  Future<void> updateServerAvailability(
    String serverId,
    bool isAvailable,
  ) async {
    try {
      final status = isAvailable ? ServerStatus.online : ServerStatus.offline;
      await _serverRepository.updateServerStatus(serverId, status);
    } catch (e) {
      // Log error but don't throw - this is for background updates
    }
  }

  /// Prefers lossless formats over lossy formats
  bool _isLosslessFormat(AudioQuality quality) {
    return quality == AudioQuality.lossless || quality == AudioQuality.ultra;
  }

  /// Calculates quality preference score
  double _calculateQualityPreference(
    AudioQuality quality,
    AudioQuality? preferredQuality,
  ) {
    if (preferredQuality == null) {
      return _getQualityScore(quality);
    }

    // Bonus for matching preferred quality
    if (quality == preferredQuality) {
      return _getQualityScore(quality) + 10.0;
    }

    // Penalty for being far from preferred quality
    final qualityDiff = (quality.qualityScore - preferredQuality.qualityScore)
        .abs();
    final penalty = qualityDiff * 2.0;

    return (_getQualityScore(quality) - penalty).clamp(0.0, 60.0);
  }
}

/// Exception thrown when no suitable source can be found
class NoSuitableSourceException implements Exception {
  final String message;

  const NoSuitableSourceException(this.message);

  @override
  String toString() => 'NoSuitableSourceException: $message';
}

/// Exception thrown when server availability check fails
class ServerAvailabilityException implements Exception {
  final String serverId;
  final String message;

  const ServerAvailabilityException(this.serverId, this.message);

  @override
  String toString() => 'ServerAvailabilityException for $serverId: $message';
}
