import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/services/device_identity.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/id_generator.dart';
import 'playback_tracking_service.dart';

/// What the local player is doing, as the handoff needs it.
typedef PlaybackSnapshot = ({List<Track> queue, int index, Duration position});

/// Playback going on on another of the user's devices, as last saved there.
class RemoteSession {
  const RemoteSession({
    required this.deviceName,
    required this.isOmnisonic,
    required this.tracks,
    required this.currentIndex,
    required this.position,
    required this.changed,
    required this.serverId,
  });

  /// "MacBook", or another app's name ("Feishin").
  final String deviceName;

  /// Saved by an Omnisonic device, which only saves while it plays.
  final bool isOmnisonic;
  final List<Track> tracks;
  final int currentIndex;
  final Duration position;
  final DateTime changed;
  final String serverId;

  /// How recent a save has to be for the device to count as still playing.
  /// An active device saves at least every [HandoffService.activeSaveEvery].
  static const Duration freshFor = Duration(seconds: 25);

  Track get currentTrack => tracks[currentIndex];

  /// Whether the other device is most likely playing right now. Only an
  /// Omnisonic device's saves say so: other apps save while paused too.
  bool isLikelyPlaying(DateTime now) =>
      isOmnisonic && now.difference(changed) < freshFor;

  /// Where the other device most likely is in the current track.
  Duration estimatedPosition(DateTime now) {
    if (!isLikelyPlaying(now)) return position;
    final estimate = position + now.difference(changed);
    final length = currentTrack.duration;
    return length > Duration.zero && estimate > length ? length : estimate;
  }
}

/// What another device is playing, as this one shows it: followed live over
/// Bluetooth ([live]) or estimated from the queue it saved on the server.
class RemoteNowPlaying {
  const RemoteNowPlaying({
    required this.deviceName,
    required this.track,
    required this.queue,
    required this.index,
    required this.playing,
    required this.position,
    required this.duration,
    required this.anchor,
    required this.live,
  });

  final String deviceName;
  final Track track;

  /// The queue to continue with here, [track] at [index].
  final List<Track> queue;
  final int index;
  final bool playing;

  /// Where the other device was at [anchor] (this device's clock).
  final Duration position;
  final Duration duration;
  final DateTime anchor;

  /// Reported by the device itself over Bluetooth, rather than estimated:
  /// exact, pauses included.
  final bool live;

  /// How often a view showing [positionAt] while it plays redraws.
  static const Duration refreshEvery = Duration(milliseconds: 500);

  /// Where the other device is at [now].
  Duration positionAt(DateTime now) {
    if (!playing) return position;
    final at = position + now.difference(anchor);
    return duration > Duration.zero && at > duration ? duration : at;
  }

  @override
  bool operator ==(Object other) =>
      other is RemoteNowPlaying &&
      other.deviceName == deviceName &&
      other.track.id == track.id &&
      other.index == index &&
      other.queue.length == queue.length &&
      other.playing == playing &&
      other.position == position &&
      other.duration == duration &&
      other.anchor == anchor &&
      other.live == live;

  @override
  int get hashCode => Object.hash(
    deviceName,
    track.id,
    index,
    queue.length,
    playing,
    position,
    duration,
    anchor,
    live,
  );
}

/// Something that happened to playback on another device.
sealed class HandoffEvent {
  const HandoffEvent();
}

/// Another device started playing: this one should stop.
class PlaybackTakenOver extends HandoffEvent {
  const PlaybackTakenOver(this.deviceName);

  final String deviceName;
}

/// A way of telling nearby devices about a takeover faster than the server
/// can (Bluetooth). The server stays the source of truth: a transport only
/// shortens how long the other device keeps playing.
abstract interface class HandoffTransport {
  /// Takeovers announced by other devices.
  Stream<String> get takeovers;

  /// Tells nearby devices this one has started playing.
  Future<void> announceTakeover();

  /// Whether this device is playing, so it can be found by the next one.
  Future<void> setPlaying(bool playing);

  /// What this device is playing, for nearby devices to follow; null when
  /// it is not the device that plays.
  Future<void> publishState(PublishedPlayback? state);

  /// Whether to follow a nearby playing device ([nearbyPlayback]): on while
  /// this one is idle and on screen.
  Future<void> setFollowing(bool following);

  /// What the followed nearby device is doing; null when it is lost.
  Stream<NearbyPlayback?> get nearbyPlayback;

  Future<void> dispose();
}

/// What the playing device tells nearby ones.
typedef PublishedPlayback = ({
  String serverId,
  String trackId,
  bool playing,
  Duration position,
  Duration duration,
});

/// Playback on a nearby device, as it last reported it.
class NearbyPlayback {
  const NearbyPlayback({
    required this.deviceName,
    required this.serverId,
    required this.trackId,
    required this.playing,
    required this.position,
    required this.duration,
    required this.receivedAt,
  });

  final String deviceName;
  final String serverId;

  /// The track's app-wide ID (`{serverId}_{subsonicId}`).
  final String trackId;
  final bool playing;
  final Duration position;
  final Duration duration;

  /// When this device received it: the position is counted from here, so
  /// the two clocks never have to agree.
  final DateTime receivedAt;

  /// How long a playing report stays believable without the next one; the
  /// playing device reports at least every [HandoffService.publishEvery].
  static const Duration freshFor = Duration(seconds: 25);

  bool isFresh(DateTime now) =>
      !playing || now.difference(receivedAt) < freshFor;

  /// Where the nearby device is at [now].
  Duration positionAt(DateTime now) {
    if (!playing) return position;
    final at = position + now.difference(receivedAt);
    return duration > Duration.zero && at > duration ? duration : at;
  }
}

/// Moves playback between the user's devices through the server's saved
/// play queue.
///
/// The device that starts playing becomes the active one and saves the
/// queue straight away, under its own client name (see [DeviceIdentity]).
/// While active it keeps checking the queue on the server; a newer save by
/// another Omnisonic device means that device took over, and this one is
/// told to pause ([PlaybackTakenOver]). A device that is not playing shows
/// what the others are doing ([remoteSession]).
///
/// Only the active device saves. A device that merely restored the queue at
/// launch saving it back would look like a takeover and stop the one that
/// is actually playing.
@lazySingleton
class HandoffService {
  HandoffService(
    this._tracking,
    this._servers,
    this._identity, {
    @ignoreParam DateTime Function()? clock,
    @ignoreParam Duration? pauseSettle,
  }) : _clock = clock ?? DateTime.now,
       _pauseSettle = pauseSettle ?? const Duration(milliseconds: 1500);

  final PlaybackTrackingService _tracking;
  final ServerRepository _servers;
  final DeviceIdentity _identity;
  final DateTime Function() _clock;

  /// How long a pause has to last to count. Moving to the next track stops
  /// the player for a moment; that is not the user pausing, and starting
  /// again afterwards is not a new takeover.
  final Duration _pauseSettle;
  Timer? _pendingPause;

  /// How often the queue is checked while this device plays.
  static const Duration checkEvery = Duration(seconds: 5);

  /// How often the queue is saved while this device plays: often enough
  /// that the others can tell it is still playing, and where.
  static const Duration activeSaveEvery = Duration(seconds: 15);

  /// How often the others' playback is looked at while this one is idle.
  static const Duration idleCheckEvery = Duration(seconds: 30);

  /// While playing, the other servers are checked every this many checks.
  static const int _otherServersEvery = 6;

  /// How often a playing device tells followers where it is, besides every
  /// play, pause, seek and track change.
  static const Duration publishEvery = Duration(seconds: 10);

  final _events = StreamController<HandoffEvent>.broadcast();
  final _remote = BehaviorSubject<RemoteSession?>.seeded(null);
  final _nearby = BehaviorSubject<NearbyPlayback?>.seeded(null);
  final List<HandoffTransport> _transports = [];
  final List<StreamSubscription<Object?>> _transportSubscriptions = [];
  bool _foreground = true;

  PlaybackSnapshot Function()? _snapshot;
  Timer? _timer;
  int _ticks = 0;
  bool _active = false;
  bool _playing = false;
  bool _checking = false;
  Timer? _saveDebounce;

  /// The `changed` time of the newest save seen on each server: a save
  /// newer than this by another device is a takeover.
  final Map<String, DateTime> _seen = {};

  Stream<HandoffEvent> get events => _events.stream;

  /// What another device is playing (or last played), or null.
  Stream<RemoteSession?> get remoteSessions => _remote.stream;
  RemoteSession? get remoteSession => _remote.value;

  /// A nearby device's playback, followed over Bluetooth while this one is
  /// idle and on screen; null when there is none.
  Stream<NearbyPlayback?> get nearbyPlayback => _nearby.stream;
  NearbyPlayback? get nearby => _nearby.value;

  /// Whether this device owns playback: it was the last to start playing.
  bool get isActive => _active;

  DateTime now() => _clock();

  /// Wires in what the local player is doing. Called once by the view model.
  void attach(PlaybackSnapshot Function() snapshot) {
    _snapshot = snapshot;
    _schedule();
  }

  /// Adds a faster channel for takeovers (Bluetooth).
  void addTransport(HandoffTransport transport) {
    _transports.add(transport);
    _transportSubscriptions
      ..add(
        transport.takeovers.listen((device) {
          AppLog.info('Takeover by $device announced nearby');
          _takenOver(device);
        }),
      )
      ..add(
        transport.nearbyPlayback.listen((state) {
          // Our own playback beats anything followed from elsewhere.
          _nearby.add(_playing ? null : state);
        }),
      );
    unawaited(transport.setPlaying(_playing && _active));
    unawaited(transport.publishState(_published()));
    unawaited(transport.setFollowing(_shouldFollow));
  }

  Future<void> removeTransport(HandoffTransport transport) async {
    final index = _transports.indexOf(transport);
    if (index == -1) return;
    _transports.removeAt(index);
    // Two subscriptions per transport, in order.
    for (final subscription in _transportSubscriptions.sublist(
      index * 2,
      index * 2 + 2,
    )) {
      await subscription.cancel();
    }
    _transportSubscriptions.removeRange(index * 2, index * 2 + 2);
    await transport.dispose();
    if (_transports.isEmpty) _nearby.add(null);
  }

  /// The app came to the front or went to the back: a device in the
  /// background does not follow nearby playback (nobody is looking, and
  /// Bluetooth costs battery).
  void setForeground(bool foreground) {
    if (foreground == _foreground) return;
    _foreground = foreground;
    _updateFollowing();
  }

  bool get _shouldFollow => _foreground && !_playing;

  void _updateFollowing() {
    final follow = _shouldFollow;
    if (!follow && _playing) _nearby.add(null);
    for (final transport in _transports) {
      unawaited(transport.setFollowing(follow));
    }
  }

  /// What this device tells nearby ones, or null when it is not the one
  /// playing.
  PublishedPlayback? _published() {
    if (!_active) return null;
    final snapshot = _snapshot?.call();
    if (snapshot == null ||
        snapshot.index < 0 ||
        snapshot.index >= snapshot.queue.length) {
      return null;
    }
    final track = snapshot.queue[snapshot.index];
    return (
      serverId: track.serverId,
      trackId: IdGenerator.extractSubsonicId(track.id),
      playing: _playing,
      position: snapshot.position,
      duration: track.duration,
    );
  }

  void _publish() {
    if (_transports.isEmpty) return;
    final state = _published();
    for (final transport in _transports) {
      unawaited(transport.publishState(state));
    }
  }

  /// The local player started (or resumed) playing: this device takes over.
  Future<void> localPlaybackStarted() async {
    final resumedQuickly = _pendingPause != null && _active;
    _pendingPause?.cancel();
    _pendingPause = null;
    _playing = true;
    if (resumedQuickly) {
      // A track change, not a new start: just save where it is now.
      localStateChanged();
      return;
    }
    _active = true;
    _seen.clear();
    _remote.add(null);
    _schedule();
    _updateFollowing();
    _publish();
    for (final transport in _transports) {
      unawaited(transport.setPlaying(true));
      unawaited(transport.announceTakeover());
    }
    // Claiming, so no check first: whatever is on the server is what this
    // device is taking over from.
    await _save(force: true);
  }

  /// The local player paused or stopped.
  Future<void> localPlaybackPaused() async {
    _playing = false;
    _pendingPause?.cancel();
    _pendingPause = Timer(_pauseSettle, () => unawaited(_settlePause()));
  }

  Future<void> _settlePause() async {
    _pendingPause = null;
    if (_playing) return;
    // Followers keep their connection after advertising stops, so they
    // still see that it paused, and where.
    _publish();
    for (final transport in _transports) {
      unawaited(transport.setPlaying(false));
    }
    _schedule();
    _updateFollowing();
    if (_active) await _saveChecked(force: true);
  }

  /// The track or position changed (skip, seek): saved shortly, so a burst
  /// of changes is one request.
  void localStateChanged() {
    if (!_active) return;
    _publish();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 1), () {
      unawaited(_saveChecked(force: true));
    });
  }

  /// Saves the queue if this device owns playback (app going to the
  /// background, about to close).
  Future<void> saveIfActive() async {
    if (_active) await _saveChecked(force: true);
  }

  /// Looks at the server now rather than at the next tick (app resumed).
  Future<void> refresh() => _tick(force: true);

  void _schedule() {
    _timer?.cancel();
    if (_snapshot == null) return;
    final every = _playing && _active ? checkEvery : idleCheckEvery;
    _timer = Timer.periodic(every, (_) => unawaited(_tick()));
  }

  Future<void> _tick({bool force = false}) async {
    if (_checking) return;
    _checking = true;
    try {
      _ticks++;
      if (_active) {
        final everyServer = force || _ticks % _otherServersEvery == 0;
        final takenOver = await _checkForTakeover(everyServer: everyServer);
        if (takenOver || !_playing) {
          if (!_active) await _refreshRemote();
          return;
        }
        final publishesPerCheck =
            publishEvery.inSeconds ~/ checkEvery.inSeconds;
        if (_ticks % publishesPerCheck == 0) _publish();
        final savesPerCheck = activeSaveEvery.inSeconds ~/ checkEvery.inSeconds;
        if (_ticks % savesPerCheck == 0) await _save(force: false);
      } else {
        await _refreshRemote();
      }
    } catch (e) {
      AppLog.warn('Handoff check failed: $e');
    } finally {
      _checking = false;
    }
  }

  /// Checks the active server (and, with [everyServer], the others) for a
  /// newer save by another Omnisonic device. True when one was found.
  Future<bool> _checkForTakeover({bool everyServer = false}) async {
    final serverIds = <String>{?_currentServerId()};
    if (everyServer || serverIds.isEmpty) {
      final servers = (await _servers.getAllServers()).valueOrNull;
      for (final server in servers ?? const <MusicServer>[]) {
        if (server.isAvailable) serverIds.add(server.id);
      }
    }

    for (final serverId in serverIds) {
      final state = await _tracking.getPlayQueueFrom(serverId);
      final changed = state?.changed;
      if (state == null || changed == null) continue;

      final previous = _seen[serverId];
      _seen[serverId] = changed;
      if (_identity.isThisDevice(state.changedBy)) continue;
      // The first look at a server sets where "newer" starts.
      if (previous == null || !changed.isAfter(previous)) continue;

      final client = DeviceIdentity.parseClient(state.changedBy);
      // Other apps save the queue while paused too, so a save of theirs
      // does not mean they are playing.
      if (client.tag == null) continue;

      _takenOver(client.name, state: state);
      return true;
    }
    return false;
  }

  void _takenOver(String deviceName, {PlayQueueState? state}) {
    if (!_active && !_playing) return;
    AppLog.info('Playback moved to $deviceName');
    _active = false;
    _saveDebounce?.cancel();
    _publish();
    if (state != null) _remote.add(_toRemote(state));
    _events.add(PlaybackTakenOver(deviceName));
    _schedule();
  }

  /// Saves after making sure nobody took over since the last check, so a
  /// routine save cannot bury another device's fresh takeover.
  Future<void> _saveChecked({required bool force}) async {
    if (!_active) return;
    if (await _checkForTakeover()) return;
    await _save(force: force);
  }

  Future<void> _save({required bool force}) async {
    final snapshot = _snapshot?.call();
    if (snapshot == null || snapshot.queue.isEmpty) return;
    if (snapshot.index < 0 || snapshot.index >= snapshot.queue.length) return;
    await _tracking.savePlayQueue(
      snapshot.queue,
      snapshot.index,
      snapshot.position,
      force: force,
    );
  }

  String? _currentServerId() {
    final snapshot = _snapshot?.call();
    if (snapshot == null ||
        snapshot.index < 0 ||
        snapshot.index >= snapshot.queue.length) {
      return null;
    }
    return snapshot.queue[snapshot.index].serverId;
  }

  /// What another device is doing: the newest queue on any server, unless
  /// this device saved it.
  Future<void> _refreshRemote() async {
    final state = await _tracking.getPlayQueue();
    if (state == null || _identity.isThisDevice(state.changedBy)) {
      _remote.add(null);
      return;
    }
    _remote.add(_toRemote(state));
  }

  RemoteSession? _toRemote(PlayQueueState state) {
    final changed = state.changed;
    final index = state.currentIndex ?? 0;
    if (changed == null ||
        state.tracks.isEmpty ||
        index < 0 ||
        index >= state.tracks.length) {
      return null;
    }
    final client = DeviceIdentity.parseClient(state.changedBy);
    return RemoteSession(
      deviceName: client.name,
      isOmnisonic: client.tag != null,
      tracks: state.tracks,
      currentIndex: index,
      position: state.position ?? Duration.zero,
      changed: changed,
      serverId: state.serverId ?? state.tracks[index].serverId,
    );
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _saveDebounce?.cancel();
    _pendingPause?.cancel();
    for (final subscription in _transportSubscriptions) {
      await subscription.cancel();
    }
    for (final transport in _transports) {
      await transport.dispose();
    }
    await _events.close();
    await _remote.close();
    await _nearby.close();
  }
}
