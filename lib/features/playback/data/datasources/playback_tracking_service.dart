import 'dart:async';
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/services/subsonic_api_client.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/id_generator.dart';

/// Reports playback back to the Subsonic servers: "now playing", scrobbles and
/// the saved play queue (`savePlayQueue` / `getPlayQueue`).
///
/// Every write goes to the server that owns the track being reported. A track
/// ID is only meaningful on its own server, so sending it anywhere else either
/// fails or, worse, touches an unrelated item that happens to share the ID.
@lazySingleton
class PlaybackTrackingService {
  PlaybackTrackingService(this._apiClient, this._serverRepository);

  final SubsonicApiClient _apiClient;
  final ServerRepository _serverRepository;

  /// Upper bound on the number of tracks sent to `savePlayQueue`.
  ///
  /// The IDs travel in the query string, and reverse proxies commonly put
  /// Navidrome behind an 8 KB request-line limit (nginx's default). A
  /// shuffled library of thousands of tracks would be rejected outright, so
  /// only a window around the current track is saved.
  static const int maxSavedQueueLength = 200;

  /// How many already-played tracks the saved window keeps before the
  /// current one, so "previous" still works after a restore.
  static const int _maxSavedTracksBeforeCurrent = 20;

  // Scrobble bookkeeping for the track currently being tracked.
  Track? _trackedTrack;
  Timer? _scrobbleTimer;
  DateTime? _trackStartTime;
  DateTime? _playRunStartedAt;
  Duration _playedBeforeCurrentRun = Duration.zero;
  bool _hasScrobbled = false;
  bool _hasSentNowPlaying = false;

  Timer? _saveQueueTimer;

  /// What was last written with `savePlayQueue`, so the periodic save does not
  /// rewrite an unchanged queue every 30 seconds while playback is paused.
  String? _lastSavedQueueSignature;

  final _scrobbledController = StreamController<Track>.broadcast();

  /// Fires with a track once it has actually been scrobbled (registered as
  /// played with the server), so the UI can show real scrobble state instead
  /// of guessing from elapsed time.
  Stream<Track> get onScrobbled => _scrobbledController.stream;

  /// How long [track] has to be *listened to* before it counts as played:
  /// half its duration, capped at 4 minutes (the Last.fm rule servers follow).
  static Duration scrobbleThreshold(Track track) {
    if (track.duration <= Duration.zero) return const Duration(seconds: 30);
    final half = track.duration * 0.5;
    const cap = Duration(minutes: 4);
    return half > cap ? cap : half;
  }

  /// Starts tracking [track] for scrobbling.
  ///
  /// Only time spent actually playing counts towards the scrobble, so a track
  /// loaded paused (a restored session, say) is not reported until the user
  /// presses play, and pausing halfway holds the scrobble back. Report
  /// play/pause transitions with [setPlaying].
  void startTrackingTrack(Track track, {bool isPlaying = true}) {
    _stopTracking();
    _trackedTrack = track;
    if (isPlaying) _onPlaybackStarted();
  }

  /// Tells the tracker whether the tracked track is currently playing.
  void setPlaying(bool isPlaying) {
    if (_trackedTrack == null || _hasScrobbled) return;

    if (isPlaying) {
      if (_playRunStartedAt == null) _onPlaybackStarted();
      return;
    }

    final runStartedAt = _playRunStartedAt;
    if (runStartedAt == null) return;
    _playedBeforeCurrentRun += DateTime.now().difference(runStartedAt);
    _playRunStartedAt = null;
    _scrobbleTimer?.cancel();
    _scrobbleTimer = null;
  }

  void _onPlaybackStarted() {
    final track = _trackedTrack!;
    final now = DateTime.now();
    _playRunStartedAt = now;
    _trackStartTime ??= now;

    if (!_hasSentNowPlaying) {
      _hasSentNowPlaying = true;
      _sendNowPlaying(track);
    }

    if (_hasScrobbled) return;
    var remaining = scrobbleThreshold(track) - _playedBeforeCurrentRun;
    if (remaining.isNegative) remaining = Duration.zero;

    AppLog.debug('Will scrobble ${track.title} in ${remaining.inSeconds}s');
    _scrobbleTimer?.cancel();
    _scrobbleTimer = Timer(remaining, () => _scrobbleTrack(track));
  }

  /// Stops tracking the current track
  void stopTracking() {
    _stopTracking();
  }

  void _stopTracking() {
    _scrobbleTimer?.cancel();
    _scrobbleTimer = null;
    _trackedTrack = null;
    _trackStartTime = null;
    _playRunStartedAt = null;
    _playedBeforeCurrentRun = Duration.zero;
    _hasScrobbled = false;
    _hasSentNowPlaying = false;
  }

  /// Sends "now playing" notification
  Future<void> _sendNowPlaying(Track track) async {
    try {
      final credentials = await _credentialsFor(_serverIdOf(track));
      if (credentials == null) {
        AppLog.warn(
          'No server credentials available for now playing notification',
        );
        return;
      }

      await _apiClient.scrobble(
        credentials.server,
        credentials.password,
        IdGenerator.extractSubsonicId(track.id),
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
    // Claimed up front so a pause/resume while the request is in flight
    // cannot schedule a second submission.
    _hasScrobbled = true;

    try {
      final credentials = await _credentialsFor(_serverIdOf(track));
      if (credentials == null) {
        AppLog.warn('No server credentials available for scrobbling');
        return;
      }

      await _apiClient.scrobble(
        credentials.server,
        credentials.password,
        IdGenerator.extractSubsonicId(track.id),
        time: _trackStartTime ?? DateTime.now(),
        submission: true,
      );

      if (!_scrobbledController.isClosed) _scrobbledController.add(track);
      AppLog.info('Scrobbled track: ${track.title}');
    } catch (e) {
      AppLog.warn('Failed to scrobble track: $e');
    }
  }

  /// Saves the current play queue state.
  ///
  /// A Subsonic play queue lives on one server and can only reference that
  /// server's tracks, so the queue is saved on the server of the current
  /// track, keeping only that server's tracks (see [queueToSave]).
  Future<void> savePlayQueue(
    List<Track> queue,
    int currentIndex,
    Duration position,
  ) async {
    try {
      AppLog.debug(
        'savePlayQueue called: queue=${queue.length}, index=$currentIndex, position=${position.inSeconds}s',
      );

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

      final toSave = queueToSave(queue, currentIndex);
      final currentTrack = queue[currentIndex];
      final serverId = _serverIdOf(currentTrack);
      final trackIds = [
        for (final track in toSave) IdGenerator.extractSubsonicId(track.id),
      ];
      final currentTrackId = IdGenerator.extractSubsonicId(currentTrack.id);

      // Whole seconds: the periodic save while paused should not count as a
      // change because the reported position wobbled by a few milliseconds.
      final signature =
          '$serverId|$currentTrackId|${position.inSeconds}|${trackIds.join(',')}';
      if (signature == _lastSavedQueueSignature) {
        AppLog.debug('Play queue unchanged since last save, skipping');
        return;
      }

      final credentials = await _credentialsFor(serverId);
      if (credentials == null) {
        AppLog.warn('No server credentials available for saving play queue');
        return;
      }

      AppLog.debug(
        'Saving to ${credentials.server.name}: ${trackIds.length} tracks, current=$currentTrackId',
      );

      await _apiClient.savePlayQueue(
        credentials.server,
        credentials.password,
        trackIds,
        current: currentTrackId,
        position: position.inMilliseconds,
      );

      _lastSavedQueueSignature = signature;
      AppLog.info(
        'Play queue saved on ${credentials.server.name}: ${trackIds.length} tracks at ${position.inSeconds}s',
      );
    } catch (e, stackTrace) {
      AppLog.warn('Failed to save play queue: $e\n$stackTrace');
    }
  }

  /// The part of [queue] that can be saved on the current track's server:
  /// that server's tracks only, in queue order, limited to a window of at
  /// most [maxSavedQueueLength] tracks that always contains the current one.
  static List<Track> queueToSave(List<Track> queue, int currentIndex) {
    final serverId = _serverIdOf(queue[currentIndex]);

    final sameServer = <Track>[];
    var currentPosition = 0;
    for (var i = 0; i < queue.length; i++) {
      if (_serverIdOf(queue[i]) != serverId) continue;
      if (i == currentIndex) currentPosition = sameServer.length;
      sameServer.add(queue[i]);
    }

    if (sameServer.length <= maxSavedQueueLength) return sameServer;

    var start = max(0, currentPosition - _maxSavedTracksBeforeCurrent);
    final end = min(sameServer.length, start + maxSavedQueueLength);
    start = max(0, end - maxSavedQueueLength);
    return sameServer.sublist(start, end);
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

  /// Retrieves the most recently saved play queue across all reachable
  /// servers.
  ///
  /// Each server keeps its own queue, and the queue is saved on whichever
  /// server the current track came from, so the newest one (by the server's
  /// `changed` timestamp) is the session to pick up.
  Future<PlayQueueState?> getPlayQueue() async {
    try {
      final serversResult = await _serverRepository.getAllServers();
      final servers = (serversResult.valueOrNull ?? const <MusicServer>[])
          .where((s) => s.isAvailable)
          .toList();
      if (servers.isEmpty) {
        AppLog.warn('No online servers to restore the play queue from');
        return null;
      }

      final candidates = (await Future.wait(
        servers.map(_fetchPlayQueue),
      )).whereType<PlayQueueState>().toList();
      if (candidates.isEmpty) {
        AppLog.debug('No saved play queue found');
        return null;
      }

      // Newest first; a server that does not report `changed` loses ties.
      candidates.sort((a, b) {
        final ac = a.changed, bc = b.changed;
        if (ac == null && bc == null) return 0;
        if (ac == null) return 1;
        if (bc == null) return -1;
        return bc.compareTo(ac);
      });

      final state = candidates.first;
      AppLog.info(
        'Loaded play queue from ${state.serverId}: ${state.tracks.length} tracks, position: ${state.position?.inSeconds ?? 0}s',
      );
      return state;
    } catch (e) {
      AppLog.warn('Failed to get play queue: $e');
      return null;
    }
  }

  Future<PlayQueueState?> _fetchPlayQueue(MusicServer server) async {
    try {
      final credentials = await _credentialsFor(server.id);
      if (credentials == null) return null;

      final response = await _apiClient.getPlayQueue(
        credentials.server,
        credentials.password,
      );

      final playQueue = response.data;
      final entries = playQueue?.entries;
      if (!response.isSuccess || playQueue == null || entries == null) {
        return null;
      }
      if (entries.isEmpty) return null;

      final tracks = [
        for (final song in entries)
          song.toDomainTrack(
            server.id,
            _apiClient.getStreamUrl(
              credentials.server,
              credentials.password,
              song.id,
            ),
            credentials.server,
            credentials.password,
            _apiClient,
          ),
      ];

      // `current` is the raw ID on that server. When it is missing or no
      // longer in the queue, start the queue from the top rather than
      // dropping the whole session.
      var currentIndex = playQueue.current == null
          ? -1
          : entries.indexWhere((song) => song.id == playQueue.current);
      Duration? position;
      if (currentIndex == -1) {
        currentIndex = 0;
      } else if (playQueue.position != null) {
        position = Duration(milliseconds: playQueue.position!);
      }

      return PlayQueueState(
        tracks: tracks,
        currentIndex: currentIndex,
        position: position,
        serverId: server.id,
        changed: playQueue.changed,
      );
    } catch (e) {
      // Navidrome answers "not found" when nothing has been saved yet.
      AppLog.debug('No play queue on ${server.name}: $e');
      return null;
    }
  }

  /// Credentials for the server with [serverId], or null when the server is
  /// unknown or has no stored password.
  Future<_ServerCredentials?> _credentialsFor(String serverId) async {
    try {
      final serverResult = await _serverRepository.getServerById(serverId);
      final server = serverResult.valueOrNull;
      if (server == null) {
        AppLog.warn('Server $serverId not found');
        return null;
      }

      final passwordResult = await _serverRepository.getCredentials(server.id);
      final password = passwordResult.valueOrNull;
      if (password == null) {
        AppLog.warn('No password stored for server ${server.name}');
        return null;
      }

      return _ServerCredentials(server: server, password: password);
    } catch (e) {
      AppLog.warn('Failed to get server credentials: $e');
      return null;
    }
  }

  /// The server a track lives on. [Track.serverId] is authoritative; the ID
  /// prefix is the fallback for tracks built without it.
  static String _serverIdOf(Track track) => track.serverId.isNotEmpty
      ? track.serverId
      : IdGenerator.extractServerId(track.id);

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

  /// The server the queue was read from.
  final String? serverId;

  /// When the server says the queue was last saved.
  final DateTime? changed;

  const PlayQueueState({
    required this.tracks,
    this.currentIndex,
    this.position,
    this.serverId,
    this.changed,
  });
}

/// Internal server credentials class
class _ServerCredentials {
  final MusicServer server;
  final String password;

  const _ServerCredentials({required this.server, required this.password});
}
