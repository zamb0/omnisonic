import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../models/library_tab.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';

class FeishinShell extends StatelessWidget {
  const FeishinShell({
    super.key,
    required this.child,
    required this.extended,
  });

  final Widget child;
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
    final textTheme = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).uri;
    final path = location.path;
    final isLibrary =
        path == AppRouter.library || path == AppRouter.albumDetail || path == AppRouter.artistDetail;
    final activeLibraryTab =
        LibraryTab.fromName(location.queryParameters['tab']) ?? LibraryTab.albums;

    return Container(
      width: extended ? 264 : 76,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 20 : 12,
              vertical: 20,
            ),
            child: Row(
              mainAxisAlignment:
                  extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: scheme.primary,
                ),
                if (extended) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Omnisonic',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSectionHeader(context, 'Main'),
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            selected: path == AppRouter.home,
            onTap: () => context.go(AppRouter.home),
          ),
          _buildNavItem(
            context,
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            label: 'Search',
            selected: path == AppRouter.search,
            onTap: () => context.go(AppRouter.search),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(context, 'Library'),
          _buildNavItem(
            context,
            icon: Icons.album_outlined,
            activeIcon: Icons.album,
            label: 'Albums',
            selected: isLibrary && activeLibraryTab == LibraryTab.albums,
            onTap: () => _goToLibraryTab(context, LibraryTab.albums),
            compact: true,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Artists',
            selected: isLibrary && activeLibraryTab == LibraryTab.artists,
            onTap: () => _goToLibraryTab(context, LibraryTab.artists),
            compact: true,
          ),
          _buildNavItem(
            context,
            icon: Icons.playlist_play_outlined,
            activeIcon: Icons.playlist_play,
            label: 'Playlists',
            selected: isLibrary && activeLibraryTab == LibraryTab.playlists,
            onTap: () => _goToLibraryTab(context, LibraryTab.playlists),
            compact: true,
          ),
          const Spacer(),
          _buildSectionHeader(context, 'Manage'),
          _buildNavItem(
            context,
            icon: Icons.dns_outlined,
            activeIcon: Icons.dns,
            label: 'Servers',
            selected: path == AppRouter.servers,
            onTap: () => context.go(AppRouter.servers),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    if (!extended) {
      return const SizedBox(height: 8);
    }

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = compact
        ? Theme.of(context).textTheme.labelMedium
        : Theme.of(context).textTheme.titleSmall;
    final color = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final background = selected ? scheme.primaryContainer : Colors.transparent;

    if (!extended) {
      return Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Icon(
              selected ? activeIcon : icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: compact ? 20 : 24,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 12, vertical: 4),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 8 : 10,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: compact ? 20 : 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: labelStyle?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToLibraryTab(BuildContext context, LibraryTab tab) {
    final tabName = tab.name;
    context.go('${AppRouter.library}?tab=$tabName');
  }
}

