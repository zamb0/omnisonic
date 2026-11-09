import 'dart:async';

import 'package:omnisonic/features/playback/data/datasources/handoff_service.dart';

/// A [HandoffService] that records what the view model tells it and emits
/// what a test asks it to.
class FakeHandoffService implements HandoffService {
  FakeHandoffService({DateTime? now}) : _now = now ?? DateTime(2026, 11, 9);

  final DateTime _now;
  final calls = <String>[];
  final _events = StreamController<HandoffEvent>.broadcast();
  final _remote = StreamController<RemoteSession?>.broadcast();
  RemoteSession? _remoteSession;
  PlaybackSnapshot Function()? snapshot;

  void emit(HandoffEvent event) => _events.add(event);

  void emitRemote(RemoteSession? session) {
    _remoteSession = session;
    _remote.add(session);
  }

  @override
  DateTime now() => _now;

  @override
  Stream<HandoffEvent> get events => _events.stream;

  @override
  Stream<RemoteSession?> get remoteSessions => _remote.stream;

  @override
  RemoteSession? get remoteSession => _remoteSession;

  @override
  bool get isActive =>
      calls.lastWhere(
        (c) => c == 'started' || c == 'paused',
        orElse: () => '',
      ) ==
      'started';

  @override
  void attach(PlaybackSnapshot Function() snapshot) => this.snapshot = snapshot;

  @override
  Future<void> localPlaybackStarted() async => calls.add('started');

  @override
  Future<void> localPlaybackPaused() async => calls.add('paused');

  @override
  void localStateChanged() => calls.add('changed');

  @override
  Future<void> saveIfActive() async => calls.add('saveIfActive');

  @override
  Future<void> refresh() async => calls.add('refresh');

  @override
  Future<void> dispose() async {
    await _events.close();
    await _remote.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
