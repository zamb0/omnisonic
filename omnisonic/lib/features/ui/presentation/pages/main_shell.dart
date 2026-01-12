import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';

/// Main shell widget that provides the bottom navigation structure
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          AnimatedNowPlayingBar(
            onTap: () => context.go(AppRouter.nowPlaying),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(index, context),
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music_outlined),
          activeIcon: Icon(Icons.library_music),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
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