import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/routing/app_router.dart';
import 'core/design_system/theme.dart';
import 'features/playback/data/datasources/playback_service.dart';

// ViewModels
import 'features/music/presentation/viewmodels/music_library_view_model.dart';
import 'features/playback/presentation/viewmodels/playback_view_model.dart';
import 'features/servers/presentation/viewmodels/server_management_view_model.dart';
import 'features/music/presentation/viewmodels/playlist_view_model.dart';

// BLoCs
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/music/presentation/bloc/search_bloc.dart';
import 'features/playback/presentation/bloc/playback_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize audio service for background playback
  // This ensures media notifications work on Android
  final playbackService = getIt<PlaybackService>();
  await playbackService.initialize();
  
  runApp(const OmnisonicApp());
}

class OmnisonicApp extends StatelessWidget {
  const OmnisonicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ViewModels
        ChangeNotifierProvider<MusicLibraryViewModel>(
          create: (_) => getIt<MusicLibraryViewModel>(),
        ),
        ChangeNotifierProvider<PlaybackViewModel>(
          create: (_) => getIt<PlaybackViewModel>(),
        ),
        ChangeNotifierProvider<ServerManagementViewModel>(
          create: (_) => getIt<ServerManagementViewModel>(),
        ),
        ChangeNotifierProvider<PlaylistViewModel>(
          create: (_) => getIt<PlaylistViewModel>(),
        ),
        
        // BLoCs
        BlocProvider<SyncBloc>(
          create: (_) => getIt<SyncBloc>(),
        ),
        BlocProvider<SearchBloc>(
          create: (_) => getIt<SearchBloc>(),
        ),
        BlocProvider<PlaybackBloc>(
          create: (_) => getIt<PlaybackBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Omnisonic',
        theme: OmnisonicTheme.lightTheme,
        darkTheme: OmnisonicTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}