// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:omnisonic/core/database/app_database.dart' as _i350;
import 'package:omnisonic/core/database/daos/cache_dao.dart' as _i803;
import 'package:omnisonic/core/database/data_sources/local_music_data_source.dart'
    as _i963;
import 'package:omnisonic/core/database/data_sources/local_playlist_data_source.dart'
    as _i2;
import 'package:omnisonic/core/database/data_sources/local_server_data_source.dart'
    as _i618;
import 'package:omnisonic/core/database/data_sources/offline_local_data_source.dart'
    as _i959;
import 'package:omnisonic/core/di/app_module.dart' as _i821;
import 'package:omnisonic/core/repositories/lyrics_repository.dart' as _i607;
import 'package:omnisonic/core/repositories/music_repository.dart' as _i102;
import 'package:omnisonic/core/repositories/offline_repository.dart' as _i763;
import 'package:omnisonic/core/repositories/playback_repository.dart' as _i995;
import 'package:omnisonic/core/repositories/playlist_repository.dart' as _i293;
import 'package:omnisonic/core/repositories/repositories.dart' as _i331;
import 'package:omnisonic/core/repositories/server_repository.dart' as _i296;
import 'package:omnisonic/core/services/cache_manager.dart' as _i868;
import 'package:omnisonic/core/services/deduplication_engine.dart' as _i566;
import 'package:omnisonic/core/services/download_manager.dart' as _i218;
import 'package:omnisonic/core/services/offline_mode_service.dart' as _i120;
import 'package:omnisonic/core/services/server_connection_service.dart'
    as _i632;
import 'package:omnisonic/core/services/server_status_monitor.dart' as _i253;
import 'package:omnisonic/core/services/source_selection_service.dart' as _i759;
import 'package:omnisonic/core/services/subsonic_api_client.dart' as _i79;
import 'package:omnisonic/core/usecases/manage_playlist_use_case.dart' as _i631;
import 'package:omnisonic/core/usecases/play_track_use_case.dart' as _i896;
import 'package:omnisonic/core/usecases/search_music_use_case.dart' as _i1063;
import 'package:omnisonic/core/usecases/sync_music_collection_use_case.dart'
    as _i882;
import 'package:omnisonic/core/usecases/usecases.dart' as _i503;
import 'package:omnisonic/core/utils/network_info.dart' as _i1048;
import 'package:omnisonic/core/utils/server_validator.dart' as _i569;
import 'package:omnisonic/features/lyrics/data/datasources/lyrics_cache_data_source.dart'
    as _i927;
import 'package:omnisonic/features/lyrics/data/datasources/lyrics_remote_data_source.dart'
    as _i91;
import 'package:omnisonic/features/lyrics/presentation/viewmodels/lyrics_view_model.dart'
    as _i359;
import 'package:omnisonic/features/music/data/datasources/server_playlist_data_source.dart'
    as _i835;
import 'package:omnisonic/features/music/data/repositories/playlist_repository_impl.dart'
    as _i238;
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart'
    as _i106;
import 'package:omnisonic/features/music/presentation/viewmodels/music_library_view_model.dart'
    as _i780;
import 'package:omnisonic/features/music/presentation/viewmodels/playlist_view_model.dart'
    as _i693;
import 'package:omnisonic/features/offline/domain/services/offline_content_filter.dart'
    as _i902;
import 'package:omnisonic/features/offline/domain/usecases/manage_offline_mode_use_case.dart'
    as _i840;
import 'package:omnisonic/features/offline/presentation/viewmodels/offline_mode_view_model.dart'
    as _i942;
import 'package:omnisonic/features/playback/data/datasources/adaptive_streaming_service.dart'
    as _i1002;
import 'package:omnisonic/features/playback/data/datasources/audio_focus_manager.dart'
    as _i463;
import 'package:omnisonic/features/playback/data/datasources/audio_player_data_source.dart'
    as _i516;
import 'package:omnisonic/features/playback/data/datasources/audio_service_handler.dart'
    as _i648;
import 'package:omnisonic/features/playback/data/datasources/media_library_browser.dart'
    as _i417;
import 'package:omnisonic/features/playback/data/datasources/mpris_handler.dart'
    as _i670;
import 'package:omnisonic/features/playback/data/datasources/playback_service.dart'
    as _i48;
import 'package:omnisonic/features/playback/data/datasources/playback_tracking_service.dart'
    as _i989;
import 'package:omnisonic/features/playback/presentation/viewmodels/playback_view_model.dart'
    as _i984;
import 'package:omnisonic/features/servers/presentation/viewmodels/server_management_view_model.dart'
    as _i502;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    final connectivityModule = _$ConnectivityModule();
    gh.lazySingleton<_i361.Dio>(() => appModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(() => appModule.secureStorage);
    gh.lazySingleton<_i350.AppDatabase>(() => appModule.database);
    gh.lazySingleton<_i927.LyricsCacheDataSource>(
      () => appModule.lyricsCacheDataSource(),
    );
    gh.lazySingleton<_i569.ServerValidator>(() => appModule.serverValidator());
    gh.lazySingleton<_i566.DeduplicationEngine>(
      () => appModule.deduplicationEngine(),
    );
    gh.lazySingleton<_i1002.AdaptiveStreamingService>(
      () => appModule.adaptiveStreamingService(),
    );
    gh.lazySingleton<_i868.CacheManager>(() => appModule.cacheManager());
    gh.lazySingleton<_i120.OfflineModeService>(
      () => appModule.offlineModeService(),
    );
    gh.lazySingleton<_i895.Connectivity>(() => connectivityModule.connectivity);
    gh.lazySingleton<_i516.AudioPlayerDataSource>(
      () => appModule.audioPlayerDataSource(
        gh<_i1002.AdaptiveStreamingService>(),
      ),
    );
    gh.lazySingleton<_i91.LyricsRemoteDataSource>(
      () => appModule.lyricsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i79.SubsonicApiClient>(
      () => appModule.subsonicApiClient(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i218.DownloadManager>(
      () => appModule.downloadManager(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i963.LocalMusicDataSource>(
      () => appModule.localMusicDataSource(gh<_i350.AppDatabase>()),
    );
    gh.lazySingleton<_i618.LocalServerDataSource>(
      () => appModule.localServerDataSource(gh<_i350.AppDatabase>()),
    );
    gh.lazySingleton<_i2.LocalPlaylistDataSource>(
      () => appModule.localPlaylistDataSource(gh<_i350.AppDatabase>()),
    );
    gh.lazySingleton<_i803.CacheDao>(
      () => appModule.cacheDao(gh<_i350.AppDatabase>()),
    );
    gh.lazySingleton<_i959.OfflineLocalDataSource>(
      () => appModule.offlineLocalDataSource(gh<_i803.CacheDao>()),
    );
    gh.lazySingleton<_i1048.NetworkInfo>(
      () => _i1048.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i763.OfflineRepository>(
      () => appModule.offlineRepository(
        gh<_i218.DownloadManager>(),
        gh<_i868.CacheManager>(),
        gh<_i959.OfflineLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i463.AudioFocusManager>(
      () => appModule.audioFocusManager(gh<_i516.AudioPlayerDataSource>()),
    );
    gh.lazySingleton<_i670.MprisHandler>(
      () => appModule.mprisHandler(gh<_i516.AudioPlayerDataSource>()),
    );
    gh.lazySingleton<_i607.LyricsRepository>(
      () => appModule.lyricsRepository(
        gh<_i91.LyricsRemoteDataSource>(),
        gh<_i927.LyricsCacheDataSource>(),
      ),
    );
    gh.lazySingleton<_i995.PlaybackRepository>(
      () => appModule.playbackRepository(gh<_i516.AudioPlayerDataSource>()),
    );
    gh.lazySingleton<_i632.ServerConnectionService>(
      () => appModule.serverConnectionService(
        gh<_i79.SubsonicApiClient>(),
        gh<_i558.FlutterSecureStorage>(),
        gh<_i350.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i902.OfflineContentFilter>(
      () => appModule.offlineContentFilter(gh<_i763.OfflineRepository>()),
    );
    gh.lazySingleton<_i359.LyricsViewModel>(
      () => _i359.LyricsViewModel(gh<_i607.LyricsRepository>()),
    );
    gh.lazySingleton<_i253.ServerStatusMonitor>(
      () => appModule.serverStatusMonitor(gh<_i632.ServerConnectionService>()),
    );
    gh.lazySingleton<_i296.ServerRepository>(
      () => appModule.serverRepository(
        gh<_i618.LocalServerDataSource>(),
        gh<_i632.ServerConnectionService>(),
        gh<_i253.ServerStatusMonitor>(),
      ),
    );
    gh.lazySingleton<_i989.PlaybackTrackingService>(
      () => _i989.PlaybackTrackingService(
        gh<_i79.SubsonicApiClient>(),
        gh<_i296.ServerRepository>(),
      ),
    );
    gh.lazySingleton<_i835.ServerPlaylistDataSource>(
      () => _i835.ServerPlaylistDataSource(
        gh<_i79.SubsonicApiClient>(),
        gh<_i296.ServerRepository>(),
      ),
    );
    gh.lazySingleton<_i759.SourceSelectionService>(
      () => appModule.sourceSelectionService(gh<_i296.ServerRepository>()),
    );
    gh.lazySingleton<_i102.MusicRepository>(
      () => appModule.musicRepository(
        gh<_i963.LocalMusicDataSource>(),
        gh<_i79.SubsonicApiClient>(),
        gh<_i296.ServerRepository>(),
        gh<_i632.ServerConnectionService>(),
        gh<_i566.DeduplicationEngine>(),
        gh<_i759.SourceSelectionService>(),
      ),
    );
    gh.factory<_i896.PlayTrackUseCase>(
      () => _i896.PlayTrackUseCase(
        gh<_i331.PlaybackRepository>(),
        gh<_i331.MusicRepository>(),
        gh<_i331.ServerRepository>(),
      ),
    );
    gh.factory<_i1063.SearchMusicUseCase>(
      () => _i1063.SearchMusicUseCase(gh<_i331.MusicRepository>()),
    );
    gh.lazySingleton<_i293.PlaylistRepository>(
      () => _i238.PlaylistRepositoryImpl(
        localPlaylistDataSource: gh<_i2.LocalPlaylistDataSource>(),
        localMusicDataSource: gh<_i963.LocalMusicDataSource>(),
        serverPlaylistDataSource: gh<_i835.ServerPlaylistDataSource>(),
        serverRepository: gh<_i296.ServerRepository>(),
        musicRepository: gh<_i102.MusicRepository>(),
      ),
    );
    gh.lazySingleton<_i984.PlaybackViewModel>(
      () => _i984.PlaybackViewModel(
        gh<_i331.PlaybackRepository>(),
        gh<_i503.PlayTrackUseCase>(),
        gh<_i989.PlaybackTrackingService>(),
        gh<_i79.SubsonicApiClient>(),
        gh<_i331.ServerRepository>(),
        gh<_i1002.AdaptiveStreamingService>(),
        gh<_i350.AppDatabase>(),
      ),
    );
    gh.factory<_i106.SearchBloc>(
      () => _i106.SearchBloc(gh<_i503.SearchMusicUseCase>()),
    );
    gh.factory<_i882.SyncMusicCollectionUseCase>(
      () => _i882.SyncMusicCollectionUseCase(
        gh<_i331.MusicRepository>(),
        gh<_i331.ServerRepository>(),
        gh<_i331.PlaylistRepository>(),
      ),
    );
    gh.lazySingleton<_i840.ManageOfflineModeUseCase>(
      () => appModule.manageOfflineModeUseCase(
        gh<_i120.OfflineModeService>(),
        gh<_i102.MusicRepository>(),
        gh<_i293.PlaylistRepository>(),
        gh<_i763.OfflineRepository>(),
        gh<_i902.OfflineContentFilter>(),
      ),
    );
    gh.lazySingleton<_i417.MediaLibraryBrowser>(
      () => appModule.mediaLibraryBrowser(
        gh<_i102.MusicRepository>(),
        gh<_i293.PlaylistRepository>(),
        gh<_i896.PlayTrackUseCase>(),
      ),
    );
    gh.lazySingleton<_i648.AudioServiceHandler>(
      () => appModule.audioServiceHandler(
        gh<_i516.AudioPlayerDataSource>(),
        gh<_i417.MediaLibraryBrowser>(),
      ),
    );
    gh.lazySingleton<_i942.OfflineModeViewModel>(
      () => _i942.OfflineModeViewModel(
        offlineModeService: gh<_i120.OfflineModeService>(),
        manageOfflineModeUseCase: gh<_i840.ManageOfflineModeUseCase>(),
        offlineRepository: gh<_i763.OfflineRepository>(),
      ),
    );
    gh.lazySingleton<_i48.PlaybackService>(
      () => appModule.playbackService(
        gh<_i516.AudioPlayerDataSource>(),
        gh<_i648.AudioServiceHandler>(),
        gh<_i463.AudioFocusManager>(),
        gh<_i670.MprisHandler>(),
      ),
    );
    gh.factory<_i631.ManagePlaylistUseCase>(
      () => _i631.ManagePlaylistUseCase(gh<_i331.PlaylistRepository>()),
    );
    gh.lazySingleton<_i502.ServerManagementViewModel>(
      () => _i502.ServerManagementViewModel(
        gh<_i331.ServerRepository>(),
        gh<_i503.SyncMusicCollectionUseCase>(),
      ),
    );
    gh.lazySingleton<_i693.PlaylistViewModel>(
      () => _i693.PlaylistViewModel(
        gh<_i331.PlaylistRepository>(),
        gh<_i503.ManagePlaylistUseCase>(),
      ),
    );
    gh.lazySingleton<_i780.MusicLibraryViewModel>(
      () => _i780.MusicLibraryViewModel(
        gh<_i331.MusicRepository>(),
        gh<_i503.SyncMusicCollectionUseCase>(),
        gh<_i503.SearchMusicUseCase>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i821.AppModule {}

class _$ConnectivityModule extends _i1048.ConnectivityModule {}
