import 'dart:async';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/services/subsonic_api_client.dart';
import '../../../../core/utils/app_log.dart';

/// Service for tracking playback and saving play queue state
@lazySingleton
class PlaybackTrackingService {
  PlaybackTrackingService(this._apiClient, this._serverRepository);

  final SubsonicApiClient _apiClient;
  final ServerRepository _serverRepository;

  Timer? _scrobbleTimer;
  Timer? _saveQueueTimer;
  DateTime? _trackStartTime;
  bool _hasScrobbled = false;

  final _scrobbledController = StreamController<Track>.broadcast();

  /// Fires with a track once it has actually been scrobbled (registered as
  /// played with the server), so the UI can show real scrobble state instead
  /// of guessing from elapsed time.
  Stream<Track> get onScrobbled => _scrobbledController.stream;

  /// Starts tracking a track for scrobbling
  /// Scrobbles after 50% of duration or 4 minutes, whichever comes first
  void startTrackingTrack(Track track) {
    _stopTracking();

    _trackStartTime = DateTime.now();
    _hasScrobbled = false;

    // Calculate when to scrobble (50% of duration or 4 minutes)
    final scrobbleDelay = track.duration * 0.5;
    final maxScrobbleDelay = const Duration(minutes: 4);
    final actualDelay = scrobbleDelay > maxScrobbleDelay
        ? maxScrobbleDelay
        : scrobbleDelay;

    AppLog.debug(
      'Will scrobble track ${track.title} in ${actualDelay.inSeconds}s',
    );

    _scrobbleTimer = Timer(actualDelay, () {
      _scrobbleTrack(track);
    });

    // Also send "now playing" notification immediately
    _sendNowPlaying(track);
  }

  /// Stops tracking the current track
  void stopTracking() {
    _stopTracking();
  }

  void _stopTracking() {
    _scrobbleTimer?.cancel();
    _scrobbleTimer = null;
    _trackStartTime = null;
    _hasScrobbled = false;
  }

  /// Sends "now playing" notification
  Future<void> _sendNowPlaying(Track track) async {
    try {
      final credentials = await _getServerCredentials();
      if (credentials == null) {
        AppLog.warn(
          'No server credentials available for now playing notification',
        );
        return;
      }

      await _apiClient.scrobble(
        credentials.server,
        credentials.password,
        _extractSubsonicId(track.id),
        submission: false, // not a submission, just "now playing"
      );

      AppLog.info('Now playing notification sent for: ${track.title}');
    } catch (e) {
      AppLog.warn('Failed to send now playing notification: $e');
    }
  }

  /// Scrobbles the track (registers the play)
  Future<void> _scrobbleTrack(Track track) async {
    if (_hasScrobbled) return;

    try {
      final credentials = await _getServerCredentials();
      if (credentials == null) {
        AppLog.warn('No server credentials available for scrobbling');
        return;
      }

      await _apiClient.scrobble(
        credentials.server,
        credentials.password,
        _extractSubsonicId(track.id),
        time: _trackStartTime ?? DateTime.now(),
        submission: true,
      );

      _hasScrobbled = true;
      _scrobbledController.add(track);
      AppLog.info('Scrobbled track: ${track.title}');
    } catch (e) {
      AppLog.warn('Failed to scrobble track: $e');
    }
  }

  /// Saves the current play queue state
  Future<void> savePlayQueue(
    List<Track> queue,
    int currentIndex,
    Duration position,
  ) async {
    try {
      AppLog.debug(
        'savePlayQueue called: queue=${queue.length}, index=$currentIndex, position=${position.inSeconds}s',
      );

      final credentials = await _getServerCredentials();
      if (credentials == null) {
        AppLog.warn('No server credentials available for saving play queue');
        return;
      }

      if (queue.isEmpty) {
        AppLog.debug('Queue is empty, not saving');
        return;
      }

      if (currentIndex < 0 || currentIndex >= queue.length) {
        AppLog.warn(
          'Invalid current index: $currentIndex (queue size: ${queue.length})',
        );
        return;
      }

      final trackIds = queue.map((t) => _extractSubsonicId(t.id)).toList();
      final currentTrackId = _extractSubsonicId(queue[currentIndex].id);

      AppLog.debug(
        'Saving to server: ${trackIds.length} tracks, current=$currentTrackId',
      );

      await _apiClient.savePlayQueue(
        credentials.server,
        credentials.password,
        trackIds,
        current: currentTrackId,
        position: position.inMilliseconds,
      );

      AppLog.info(
        '✓ Play queue saved successfully: ${queue.length} tracks at ${position.inSeconds}s',
      );
    } catch (e, stackTrace) {
      AppLog.warn('Failed to save play queue: $e\n$stackTrace');
    }
  }

  /// Starts periodic saving of play queue (every 30 seconds)
  void startPeriodicQueueSave(
    Future<List<Track>> Function() getQueue,
    Future<int> Function() getCurrentIndex,
    Future<Duration> Function() getPosition,
  ) {
    _saveQueueTimer?.cancel();
    _saveQueueTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final queue = await getQueue();
      final index = await getCurrentIndex();
      final position = await getPosition();
      await savePlayQueue(queue, index, position);
    });
  }

  /// Stops periodic queue saving
  void stopPeriodicQueueSave() {
    _saveQueueTimer?.cancel();
    _saveQueueTimer = null;
  }

  /// Retrieves the saved play queue
  Future<PlayQueueState?> getPlayQueue() async {
    try {
      final credentials = await _getServerCredentials();
      if (credentials == null) {
        AppLog.warn('No server credentials available for getting play queue');
        return null;
      }

      final response = await _apiClient.getPlayQueue(
        credentials.server,
        credentials.password,
      );

      if (!response.isSuccess || response.data == null) {
        AppLog.debug('No saved play queue found');
        return null;
      }

      final playQueue = response.data!;
      if (playQueue.entries == null || playQueue.entries!.isEmpty) {
        AppLog.debug('Play queue is empty');
        return null;
      }

      // Convert SubsonicSong to Track
      final tracks = playQueue.entries!.map((song) {
        final streamUrl = _apiClient.getStreamUrl(
          credentials.server,
          credentials.password,
          song.id,
        );
        return song.toDomainTrack(
          credentials.server.id,
          streamUrl,
          credentials.server,
          credentials.password,
          _apiClient,
        );
      }).toList();

      // Find current track index
      int? currentIndex;
      if (playQueue.current != null) {
        currentIndex = tracks.indexWhere(
          (t) => _extractSubsonicId(t.id) == playQueue.current,
        );
        if (currentIndex == -1) currentIndex = null;
      }

      final position = playQueue.position != null
          ? Duration(milliseconds: playQueue.position!)
          : null;

      AppLog.info(
        'Loaded play queue: ${tracks.length} tracks, position: ${position?.inSeconds ?? 0}s',
      );

      return PlayQueueState(
        tracks: tracks,
        currentIndex: currentIndex,
        position: position,
      );
    } catch (e) {
      AppLog.warn('Failed to get play queue: $e');
      return null;
    }
  }

  /// Gets server credentials for API calls
  /// Returns the first online server with stored credentials
  Future<_ServerCredentials?> _getServerCredentials() async {
    try {
      final serversResult = await _serverRepository.getOnlineServers();
      if (serversResult.isFailure || serversResult.valueOrNull == null) {
        AppLog.warn('No online servers available');
        return null;
      }

      final servers = serversResult.valueOrNull!;
      if (servers.isEmpty) {
        AppLog.warn('No online servers found');
        return null;
      }

      // Try first online server
      final server = servers.first;
      final passwordResult = await _serverRepository.getCredentials(server.id);

      if (passwordResult.isFailure || passwordResult.valueOrNull == null) {
        AppLog.warn('No password stored for server ${server.name}');
        return null;
      }

      return _ServerCredentials(
        server: server,
        password: passwordResult.valueOrNull!,
      );
    } catch (e) {
      AppLog.warn('Failed to get server credentials: $e');
      return null;
    }
  }

  /// Extracts the original Subsonic ID from our composite ID
  String _extractSubsonicId(String compositeId) {
    // Our IDs are in format "serverId_subsonicId"
    final parts = compositeId.split('_');
    return parts.length > 1 ? parts.sublist(1).join('_') : compositeId;
  }

  void dispose() {
    _stopTracking();
    stopPeriodicQueueSave();
    _scrobbledController.close();
  }
}

/// Represents the saved play queue state
class PlayQueueState {
  final List<Track> tracks;
  final int? currentIndex;
  final Duration? position;

  const PlayQueueState({
    required this.tracks,
    this.currentIndex,
    this.position,
  });
}

/// Internal server credentials class
class _ServerCredentials {
  final MusicServer server;
  final String password;

  const _ServerCredentials({required this.server, required this.password});
}
