import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/design_system/responsive_layout.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';
import '../widgets/feishin_shell.dart';

/// Main shell widget that provides the bottom navigation structure
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileShell(context),
      tablet: _buildDesktopShell(context, extended: false),
      desktop: _buildDesktopShell(context, extended: true),
    );
  }

  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          AnimatedNowPlayingBar(
            onTap: () => context.push(AppRouter.nowPlaying),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildDesktopShell(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: FeishinShell(
        child: child,
        selectedIndex: _calculateSelectedIndex(context),
        onSelect: (index) => _onItemTapped(index, context),
        extended: extended,
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
          icon: Icon(Icons.dns_outlined),
          selectedIcon: Icon(Icons.dns),
          label: 'Servers',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    switch (location) {
      case AppRouter.home:
        return 0;
      case AppRouter.library:
        return 1;
      case AppRouter.search:
        return 2;
      case AppRouter.servers:
        return 3;
      case AppRouter.albumDetail:
      case AppRouter.artistDetail:
        return 1; // Detail pages belong to Library
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
        context.go(AppRouter.servers);
        break;
    }
  }
}