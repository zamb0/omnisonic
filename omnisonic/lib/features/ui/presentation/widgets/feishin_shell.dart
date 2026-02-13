import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';

class FeishinShell extends StatelessWidget {
  const FeishinShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onSelect,
    required this.extended,
  });

  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLeftNav(context),
              Expanded(child: child),
            ],
          ),
        ),
        AnimatedNowPlayingBar(
          onTap: () => context.push(AppRouter.nowPlaying),
        ),
      ],
    );
  }

  Widget _buildLeftNav(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: extended,
      onDestinationSelected: onSelect,
      backgroundColor: scheme.surfaceVariant,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: scheme.onSurface),
      unselectedLabelTextStyle: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: scheme.onSurfaceVariant),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.dns_outlined),
          selectedIcon: Icon(Icons.dns),
          label: Text('Servers'),
        ),
      ],
    );
  }
}

