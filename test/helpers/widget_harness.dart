import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/design_system/theme_mode_controller.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/music_library_view_model.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/playlist_view_model.dart';
import 'package:omnisonic/features/playback/presentation/viewmodels/playback_view_model.dart';
import 'package:omnisonic/features/servers/presentation/viewmodels/server_management_view_model.dart';
import 'package:omnisonic/features/ui/presentation/pages/main_shell.dart';
import 'package:provider/provider.dart';

import 'view_model_fakes.dart';

/// Common device widths. The shell switches chrome at 768 and 1024
/// ([ResponsiveBreakpoints]), so these are the sizes worth testing at.
class TestSizes {
  /// Small phone — bottom bar.
  static const phone = Size(400, 900);

  /// Smallest width the app claims to support.
  static const smallPhone = Size(375, 812);

  /// Tablet — icon-only 72px rail.
  static const tablet = Size(800, 1200);

  /// Desktop — full 234px sidebar.
  static const desktop = Size(1440, 900);
}

/// The four view models every shell page reads, pre-wired as fakes.
///
/// Held together so a test can reach in and drive one (`fakes.library
/// .emitError(...)`) without rebuilding the provider list.
class TestViewModels {
  TestViewModels({
    FakeMusicLibraryViewModel? library,
    FakePlaybackViewModel? playback,
    FakeServerManagementViewModel? servers,
    FakePlaylistViewModel? playlists,
  }) : library = library ?? FakeMusicLibraryViewModel(),
       playback = playback ?? FakePlaybackViewModel(),
       servers = servers ?? FakeServerManagementViewModel(),
       playlists = playlists ?? FakePlaylistViewModel();

  final FakeMusicLibraryViewModel library;
  final FakePlaybackViewModel playback;
  final FakeServerManagementViewModel servers;
  final FakePlaylistViewModel playlists;

  List<ChangeNotifierProvider> get providers => [
    ChangeNotifierProvider<MusicLibraryViewModel>.value(value: library),
    ChangeNotifierProvider<PlaybackViewModel>.value(value: playback),
    ChangeNotifierProvider<ServerManagementViewModel>.value(value: servers),
    ChangeNotifierProvider<PlaylistViewModel>.value(value: playlists),
    // A plain singleton in the app rather than a DI registration, so the
    // real one is fine here — it only reads SharedPreferences, which is
    // absent in tests and leaves it on its default.
    ChangeNotifierProvider<ThemeModeController>.value(
      value: ThemeModeController.instance,
    ),
  ];
}

/// Pumps [page] on its own, with the app theme and the fake view models.
///
/// Use this for a single screen. For anything that depends on the shell's
/// chrome — nav selection, the mini-player, [ShellLayout] — use [pumpShell]
/// instead, because a page pumped bare falls back to a MediaQuery width
/// check and can disagree with what the real shell would have chosen.
Future<TestViewModels> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = TestSizes.phone,
  double textScale = 1.0,
  bool disableAnimations = false,
  TestViewModels? viewModels,
  ThemeMode themeMode = ThemeMode.dark,
  bool settle = true,
}) async {
  final models = viewModels ?? TestViewModels();
  _sizeSurface(tester, size);

  await tester.pumpWidget(
    MultiProvider(
      providers: models.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: OmnisonicTheme.lightTheme,
        darkTheme: OmnisonicTheme.darkTheme,
        themeMode: themeMode,
        home: _TestMediaQuery(
          textScale: textScale,
          disableAnimations: disableAnimations,
          child: page,
        ),
      ),
    ),
  );

  await _stabilise(tester, settle: settle);
  return models;
}

/// Pumps the real [MainShell] at [location], with a router covering the
/// shell's own destinations.
///
/// Deliberately not [AppRouter.router]: that is a static singleton, so tests
/// would share navigation history with each other.
Future<TestViewModels> pumpShell(
  WidgetTester tester, {
  String location = AppRouter.home,
  Size size = TestSizes.phone,
  double textScale = 1.0,
  bool disableAnimations = false,
  TestViewModels? viewModels,
  ThemeMode themeMode = ThemeMode.dark,
  List<RouteBase>? routes,
  bool settle = true,
}) async {
  final models = viewModels ?? TestViewModels();
  _sizeSurface(tester, size);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: routes ?? testShellRoutes(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: models.providers,
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: OmnisonicTheme.lightTheme,
        darkTheme: OmnisonicTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) => _TestMediaQuery(
          textScale: textScale,
          disableAnimations: disableAnimations,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );

  await _stabilise(tester, settle: settle);
  return models;
}

/// Placeholder routes for every path the shell's chrome can select.
///
/// Bodies are stubs by default so a nav test doesn't drag in the real pages'
/// dependencies; pass `builders` to render the genuine page for the one path
/// under test.
List<RouteBase> testShellRoutes({
  Map<String, GoRouterWidgetBuilder> builders = const {},
}) {
  const paths = [
    AppRouter.home,
    AppRouter.library,
    AppRouter.search,
    AppRouter.favorites,
    AppRouter.servers,
    AppRouter.downloads,
    AppRouter.settings,
    AppRouter.albumDetail,
    AppRouter.artistDetail,
    AppRouter.playlistManagement,
    AppRouter.playlistDetail,
    AppRouter.queue,
  ];

  return [
    for (final path in paths)
      GoRoute(
        path: path,
        builder:
            builders[path] ??
            (context, state) => Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: Text('stub:$path')),
            ),
      ),
  ];
}

void _sizeSurface(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// `pumpAndSettle` throws on anything that animates forever — the shimmer
/// skeletons and the glass sheen both do. Fall back to a couple of frames so
/// a caller can still assert on a loading state.
Future<void> _stabilise(WidgetTester tester, {required bool settle}) async {
  if (!settle) {
    await tester.pump();
    return;
  }
  try {
    await tester.pumpAndSettle();
  } on FlutterError {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

class _TestMediaQuery extends StatelessWidget {
  const _TestMediaQuery({
    required this.textScale,
    required this.disableAnimations,
    required this.child,
  });

  final double textScale;
  final bool disableAnimations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child,
    );
  }
}
