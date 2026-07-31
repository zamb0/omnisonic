import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/design_system/responsive_layout.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';
import '../widgets/feishin_shell.dart';

/// Main shell widget that provides the bottom navigation structure
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // The sidebar shell needs room for a 76-264px rail plus content, so it only
    // takes over from the tablet breakpoint up. Below that the phone shell with
    // the bottom bar is used, including on landscape phones.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= ResponsiveBreakpoints.desktop) {
          return _buildSidebarShell(context, extended: true);
        }
        if (width >= ResponsiveBreakpoints.tablet) {
          return _buildSidebarShell(context, extended: false);
        }
        return _buildMobileShell(context);
      },
    );
  }

  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: child),
            AnimatedNowPlayingBar(
              onTap: () => context.push(AppRouter.nowPlaying),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildSidebarShell(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: SafeArea(
        child: FeishinShell(child: child, extended: extended),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      height: 64,
      onDestinationSelected: (index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.star_outline),
          selectedIcon: Icon(Icons.star),
          label: 'Starred',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    switch (location) {
      case AppRouter.home:
      // Server management is a secondary destination reached from Home, so it
      // keeps the Home tab lit rather than leaving the bar without a selection.
      case AppRouter.servers:
        return 0;
      case AppRouter.library:
      case AppRouter.albumDetail:
      case AppRouter.artistDetail:
      case AppRouter.playlistDetail:
      case AppRouter.playlistManagement:
        return 1;
      case AppRouter.search:
        return 2;
      case AppRouter.favorites:
        return 3;
      default:
        return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.library);
        break;
      case 2:
        context.go(AppRouter.search);
        break;
      case 3:
        context.go(AppRouter.favorites);
        break;
    }
  }
}
