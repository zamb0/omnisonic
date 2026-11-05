import '../../../../core/entities/entities.dart';

/// The state of all servers at a glance: what the account avatar's ring
/// shows. Per-server detail lives on the Servers page; this is only "is
/// everything fine?".
enum ServerHealth {
  /// No servers configured: no ring.
  none,

  /// Every server is reachable (online or syncing).
  healthy,

  /// Some server is unreachable or still connecting.
  degraded,

  /// No server is reachable.
  down;

  static ServerHealth of(Iterable<ServerStatus> statuses) {
    final all = statuses.toList();
    if (all.isEmpty) return none;
    bool unreachable(ServerStatus s) =>
        s == ServerStatus.offline || s == ServerStatus.error;
    final down = all.where(unreachable).length;
    if (down == all.length) return ServerHealth.down;
    final pending = all.where((s) => s.isConnecting).length;
    if (down > 0 || pending > 0) return degraded;
    return healthy;
  }

  /// The [ServerStatus] whose colour this health borrows.
  ServerStatus? get status => switch (this) {
    none => null,
    healthy => ServerStatus.online,
    degraded => ServerStatus.connecting,
    down => ServerStatus.offline,
  };

  /// For screen readers: colour alone must not carry it.
  String get description => switch (this) {
    none => 'no servers configured',
    healthy => 'all servers online',
    degraded => 'some servers unavailable',
    down => 'no server reachable',
  };
}
