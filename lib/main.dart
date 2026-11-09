import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/design_system/theme.dart';
import 'core/design_system/theme_mode_controller.dart';
import 'features/playback/data/datasources/playback_service.dart';
import 'core/services/device_identity.dart';
import 'core/services/subsonic_api_client.dart';
import 'features/playback/data/datasources/handoff_service.dart';

// ViewModels
import 'features/music/presentation/viewmodels/music_library_view_model.dart';
import 'features/playback/presentation/viewmodels/playback_view_model.dart';
import 'features/playback/presentation/widgets/playback_error_listener.dart';
import 'features/ui/presentation/widgets/feedback.dart';
import 'features/servers/presentation/viewmodels/server_management_view_model.dart';
import 'features/music/presentation/viewmodels/playlist_view_model.dart';
import 'features/lyrics/presentation/viewmodels/lyrics_view_model.dart';
import 'features/offline/presentation/viewmodels/offline_mode_view_model.dart';

// BLoCs
import 'features/music/presentation/bloc/search_bloc.dart';
import 'core/routing/app_shortcuts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSizeBytes = AppConstants.maxImageCacheSize;
  imageCache.maximumSize = 1000;

  try {
    // Initialize dependency injection
    await configureDependencies();

    // Each device has its own client name on the servers, so the play queue
    // it saves can be told apart from the other devices' (playback handoff).
    // Loaded before anything talks to a server.
    final identity = getIt<DeviceIdentity>();
    await identity.load();
    final apiClient = getIt<SubsonicApiClient>();
    apiClient.clientName = identity.clientName;
    identity.addListener(() => apiClient.clientName = identity.clientName);

    // Initialize audio service for background playback
    // Use a timeout to prevent hanging on iOS if AudioService.init() blocks
    try {
      final playbackService = getIt<PlaybackService>();
      await playbackService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('PlaybackService initialization timed out after 5s');
        },
      );
    } catch (e) {
      debugPrint('PlaybackService initialization failed: $e');
    }
  } catch (e) {
    debugPrint('App initialization failed: $e');
  }

  runApp(const OmnisonicApp());
}

class OmnisonicApp extends StatefulWidget {
  const OmnisonicApp({super.key});

  @override
  State<OmnisonicApp> createState() => _OmnisonicAppState();
}

class _OmnisonicAppState extends State<OmnisonicApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('App lifecycle changed to: $state');

    // Save queue when app goes to background or is about to close. Only
    // the device that is playing saves: a device that merely shows the
    // restored queue saving it would stop the one actually playing.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _handoff()?.saveIfActive();
    }
    // Back in front: show what the other devices are doing now.
    if (state == AppLifecycleState.resumed) {
      _handoff()?.refresh();
    }
  }

  HandoffService? _handoff() {
    try {
      // Constructing the view model wires the handoff to the player.
      getIt<PlaybackViewModel>();
      return getIt<HandoffService>();
    } catch (e) {
      debugPrint('Handoff unavailable: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ViewModels are lazy singletons in getIt, which owns their lifetime —
        // hence .value rather than create, so the provider never disposes an
        // instance getIt will keep handing out.
        ChangeNotifierProvider<MusicLibraryViewModel>.value(
          value: getIt<MusicLibraryViewModel>(),
        ),
        ChangeNotifierProvider<PlaybackViewModel>.value(
          value: getIt<PlaybackViewModel>(),
        ),
        ChangeNotifierProvider<ServerManagementViewModel>.value(
          value: getIt<ServerManagementViewModel>(),
        ),
        ChangeNotifierProvider<PlaylistViewModel>.value(
          value: getIt<PlaylistViewModel>(),
        ),
        ChangeNotifierProvider<LyricsViewModel>.value(
          value: getIt<LyricsViewModel>(),
        ),
        ChangeNotifierProvider<OfflineModeViewModel>.value(
          value: getIt<OfflineModeViewModel>(),
        ),
        ChangeNotifierProvider<ThemeModeController>.value(
          value: ThemeModeController.instance,
        ),

        // BLoCs
        BlocProvider<SearchBloc>(create: (_) => getIt<SearchBloc>()),
      ],
      child: Consumer<ThemeModeController>(
        builder: (context, themeModeController, child) {
          return MaterialApp.router(
            title: 'Omnisonic',
            theme: OmnisonicTheme.lightTheme,
            darkTheme: OmnisonicTheme.darkTheme,
            themeMode: themeModeController.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) => AppShortcuts(
              playback: () => getIt<PlaybackViewModel>(),
              child: PlaybackErrorListener(
                playback: () => getIt<PlaybackViewModel>(),
                child: ActionErrorListener(
                  source: () => getIt<PlaylistViewModel>(),
                  message: () => getIt<PlaylistViewModel>().actionError,
                  clear: () => getIt<PlaylistViewModel>().clearActionError(),
                  child: ActionErrorListener(
                    source: () => getIt<ServerManagementViewModel>(),
                    message: () =>
                        getIt<ServerManagementViewModel>().actionError,
                    clear: () =>
                        getIt<ServerManagementViewModel>().clearActionError(),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
