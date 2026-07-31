/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Omnisonic';
  static const String appVersion = '1.0.0';

  // Subsonic API
  static const String subsonicApiVersion = '1.16.1';
  static const String subsonicClientName = 'Omnisonic';

  // Database
  static const String databaseName = 'omnisonic.db';
  static const int databaseVersion = 1;

  // Cache
  static const int maxCacheSize = 1024 * 1024 * 1024; // 1GB
  static const int maxImageCacheSize = 100 * 1024 * 1024; // 100MB

  // Network
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Audio
  static const int maxQueueSize = 1000;
  static const int preloadBufferSize = 3; // Number of tracks to preload

  // UI
  static const int uiResponseTimeout = 100; // milliseconds
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // Sync
  static const int syncIntervalMinutes = 5;
  static const int maxServerConnections = 10;

  // Performance
  static const int maxMemoryUsageMB = 100;
  static const int startupTimeoutSeconds = 3;
  static const int maxCollectionSize = 100000;
}
