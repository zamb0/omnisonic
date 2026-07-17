enum ServerStatus {
  online,
  offline,
  connecting,
  error,
  authenticating,
  syncing;

  bool get isAvailable => this == ServerStatus.online;
  bool get isConnecting =>
      this == ServerStatus.connecting || this == ServerStatus.authenticating;
  bool get hasError => this == ServerStatus.error;

  @override
  String toString() {
    switch (this) {
      case ServerStatus.online:
        return 'Online';
      case ServerStatus.offline:
        return 'Offline';
      case ServerStatus.connecting:
        return 'Connecting';
      case ServerStatus.error:
        return 'Error';
      case ServerStatus.authenticating:
        return 'Authenticating';
      case ServerStatus.syncing:
        return 'Syncing';
    }
  }
}
