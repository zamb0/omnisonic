import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_router.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../models/library_tab.dart';
import '../widgets/server_dot.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';

class FeishinShell extends StatelessWidget {
  const FeishinShell({super.key, required this.child, required this.extended});

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
        AnimatedNowPlayingBar(onTap: () => context.push(AppRouter.nowPlaying)),
      ],
    );
  }

  Widget _buildLeftNav(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).uri;
    final path = location.path;
    final isLibrary =
        path == AppRouter.library ||
        path == AppRouter.albumDetail ||
        path == AppRouter.artistDetail;
    final activeLibraryTab =
        LibraryTab.fromName(location.queryParameters['tab']) ??
        LibraryTab.albums;

    return GlassSurface(
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: extended ? 264 : 76,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 20 : 12,
                vertical: 20,
              ),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq_rounded, color: scheme.primary),
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
            const SizedBox(height: 12),
            _buildSectionHeader(context, 'Favorites'),
            _buildNavItem(
              context,
              icon: Icons.star_outline,
              activeIcon: Icons.star,
              label: 'Starred',
              selected: path == AppRouter.favorites,
              onTap: () => context.go(AppRouter.favorites),
            ),
            const Spacer(),
            _buildServersSection(context, path),
            const SizedBox(height: 8),
            _buildLibraryHealthCard(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// SERVERS section: one row per connected server (dot + name + a short ID
  /// fragment) instead of a single generic "Servers" nav item, plus a
  /// trailing icon to open full server management.
  Widget _buildServersSection(BuildContext context, String path) {
    final scheme = Theme.of(context).colorScheme;
    final servers = context.watch<ServerManagementViewModel>().servers;

    if (!extended) {
      return _buildNavItem(
        context,
        icon: Icons.dns_outlined,
        activeIcon: Icons.dns,
        label: 'Servers',
        selected: path == AppRouter.servers,
        onTap: () => context.go(AppRouter.servers),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SERVERS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.go(AppRouter.servers),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (servers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No servers yet',
              style: OmnisonicTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final server in servers)
            InkWell(
              onTap: () => context.go(AppRouter.servers),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    ServerDot(serverId: server.id, size: 8),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        server.name,
                        style: OmnisonicTypography.bodySmall.copyWith(
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _shortId(server.id),
                      style: OmnisonicTypography.metadata.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _shortId(String id) =>
      id.length <= 6 ? id : id.substring(id.length - 6);

  /// Real aggregate stats from [MusicLibraryViewModel] — track/album/artist
  /// counts and how many duplicate groups the dedup engine has merged.
  Widget _buildLibraryHealthCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final libraryViewModel = context.watch<MusicLibraryViewModel>();

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(
          libraryViewModel.isSyncing
              ? Icons.sync
              : Icons.health_and_safety_outlined,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.md),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library health',
              style: OmnisonicTypography.overline.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${libraryViewModel.trackCount} tracks · '
              '${libraryViewModel.albumCount} albums · '
              '${libraryViewModel.artistCount} artists',
              style: OmnisonicTypography.bodySmall.copyWith(
                color: scheme.onSurface,
              ),
            ),
            if (libraryViewModel.duplicateGroupCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${libraryViewModel.duplicateGroupCount} duplicate groups merged',
                style: OmnisonicTypography.metadata.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
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
    final color = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final background = selected ? scheme.primaryContainer : Colors.transparent;

    if (!extended) {
      // Labels are shown under the icon (NavigationRail labelType: all
      // style) instead of a Tooltip, which relies on hover and is
      // unreachable on tablet touchscreens.
      return InkResponse(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                size: compact ? 20 : 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
                  child: Text(label, style: labelStyle?.copyWith(color: color)),
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
