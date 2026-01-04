import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/app_database.dart';
import '../database/data_sources/local_music_data_source.dart';
import '../database/data_sources/local_server_data_source.dart';
import '../database/data_sources/local_playlist_data_source.dart';
import '../services/subsonic_api_client.dart';
import '../services/server_connection_service.dart';
import '../services/server_status_monitor.dart';
import '../services/deduplication_engine.dart';
import '../services/source_selection_service.dart';
import '../utils/server_validator.dart';
import '../repositories/music_repository.dart';
import '../repositories/server_repository.dart';
import '../repositories/playback_repository.dart';
import '../repositories/playlist_repository.dart';
import '../../features/music/data/repositories/music_repository_impl.dart';
import '../../features/servers/data/repositories/server_repository_impl.dart';
import '../../features/playback/data/repositories/playback_repository_impl.dart';
import '../../features/music/data/repositories/playlist_repository_impl.dart';
import '../../features/playback/data/datasources/audio_player_data_source.dart';
import '../../features/playback/data/datasources/audio_service_handler.dart';
import '../../features/playback/data/datasources/audio_focus_manager.dart';
import '../../features/playback/data/datasources/adaptive_streaming_service.dart';
import '../../features/playback/data/datasources/playback_service.dart';
import '../usecases/sync_music_collection_use_case.dart';
import '../usecases/search_music_use_case.dart';
import '../usecases/play_track_use_case.dart';
import '../usecases/manage_playlist_use_case.dart';

// ViewModels
import '../../features/music/presentation/viewmodels/music_library_view_model.dart';
import '../../features/playback/presentation/viewmodels/playback_view_model.dart';
import '../../features/servers/presentation/viewmodels/server_management_view_model.dart';
import '../../features/music/presentation/viewmodels/playlist_view_model.dart';

// BLoCs
import '../../features/sync/presentation/bloc/sync_bloc.dart';
import '../../features/music/presentation/bloc/search_bloc.dart';
import '../../features/playback/presentation/bloc/playback_bloc.dart';

@module
abstract class AppModule {
  // External dependencies
  @lazySingleton
  Dio get dio => Dio();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  // Database
  @lazySingleton
  AppDatabase get database => AppDatabase();

  // Data sources
  @lazySingleton
  LocalMusicDataSource localMusicDataSource(AppDatabase database) =>
      LocalMusicDataSource(database);

  @lazySingleton
  LocalServerDataSource localServerDataSource(AppDatabase database) =>
      LocalServerDataSource(database);

  @lazySingleton
  LocalPlaylistDataSource localPlaylistDataSource(AppDatabase database) =>
      LocalPlaylistDataSource(database);

  // Services
  @lazySingleton
  SubsonicApiClient subsonicApiClient(Dio dio) => SubsonicApiClient(dio: dio);

  @lazySingleton
  ServerConnectionService serverConnectionService(
    SubsonicApiClient apiClient,
    FlutterSecureStorage secureStorage,
    AppDatabase database,
  ) =>
      ServerConnectionService(
        apiClient: apiClient,
        secureStorage: secureStorage,
        database: database,
      );

  @lazySingleton
  ServerStatusMonitor serverStatusMonitor(
    ServerConnectionService connectionService,
  ) => ServerStatusMonitor(connectionService: connectionService);

  @lazySingleton
  ServerValidator serverValidator() => ServerValidator();

  @lazySingleton
  DeduplicationEngine deduplicationEngine() => DeduplicationEngine();

  @lazySingleton
  SourceSelectionService sourceSelectionService(
    ServerRepository serverRepository,
  ) => SourceSelectionService(serverRepository: serverRepository);

  // Playback components
  @lazySingleton
  AdaptiveStreamingService adaptiveStreamingService() => AdaptiveStreamingService();

  @lazySingleton
  AudioPlayerDataSource audioPlayerDataSource(
    AdaptiveStreamingService adaptiveStreamingService,
  ) => AudioPlayerDataSource(adaptiveStreamingService: adaptiveStreamingService);

  @lazySingleton
  AudioServiceHandler audioServiceHandler(
    AudioPlayerDataSource audioPlayerDataSource,
  ) => AudioServiceHandler(audioPlayerDataSource: audioPlayerDataSource);

  @lazySingleton
  AudioFocusManager audioFocusManager(
    AudioPlayerDataSource audioPlayerDataSource,
  ) => AudioFocusManager(audioPlayerDataSource: audioPlayerDataSource);

  @lazySingleton
  PlaybackService playbackService(
    AudioPlayerDataSource audioPlayerDataSource,
    AudioServiceHandler audioServiceHandler,
    AudioFocusManager audioFocusManager,
  ) => PlaybackService(
        audioPlayerDataSource: audioPlayerDataSource,
        audioServiceHandler: audioServiceHandler,
        audioFocusManager: audioFocusManager,
      );

  // Repository implementations
  @LazySingleton(as: ServerRepository)
  ServerRepositoryImpl serverRepository(
    LocalServerDataSource localDataSource,
    ServerConnectionService connectionService,
    ServerStatusMonitor statusMonitor,
    ServerValidator validator,
  ) =>
      ServerRepositoryImpl(
        localDataSource: localDataSource,
        connectionService: connectionService,
        statusMonitor: statusMonitor,
        validator: validator,
      );

  @LazySingleton(as: MusicRepository)
  MusicRepositoryImpl musicRepository(
    LocalMusicDataSource localDataSource,
    SubsonicApiClient apiClient,
    ServerRepository serverRepository,
    ServerConnectionService connectionService,
    DeduplicationEngine deduplicationEngine,
    SourceSelectionService sourceSelectionService,
  ) =>
      MusicRepositoryImpl(
        localDataSource: localDataSource,
        apiClient: apiClient,
        serverRepository: serverRepository,
        connectionService: connectionService,
        deduplicationEngine: deduplicationEngine,
        sourceSelectionService: sourceSelectionService,
      );

  @LazySingleton(as: PlaybackRepository)
  PlaybackRepositoryImpl playbackRepository(
    AudioPlayerDataSource audioPlayerDataSource,
  ) =>
      PlaybackRepositoryImpl(
        audioPlayerDataSource: audioPlayerDataSource,
      );
}