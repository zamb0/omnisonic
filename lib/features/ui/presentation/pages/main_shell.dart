import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';
import '../widgets/feishin_shell.dart';
import '../widgets/shell_art_tint.dart';

/// Which chrome the shell decided to render.
enum ShellMode {
  /// Phone layout: bottom navigation bar, no sidebar.
  bottomBar,

  /// Icon-only 72px rail.
  collapsedSidebar,

  /// Full 234px sidebar with labels.
  extendedSidebar,
}

/// Publishes the shell's chosen layout to the page inside it.
///
/// Pages used to re-derive this from `MediaQuery`, but the shell decides from
/// its own constraints and the content column is narrower by the width of the
/// sidebar. On a 1000px window that disagreement hid the library's TabBar
/// while the sidebar was in icon-only mode, leaving no way to reach Artists or
/// Playlists.
class ShellLayout extends InheritedWidget {
  const ShellLayout({
    super.key,
    required this.mode,
    super.child = const SizedBox.shrink(),
  });

  final ShellMode mode;

  /// Returns a copy of this marker wrapping [child].
  Widget wrap(Widget child) => ShellLayout(mode: mode, child: child);

  /// The shell mode for [context], or null outside the shell.
  static ShellMode? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellLayout>()?.mode;

  /// Whether the shell is showing a sidebar rather than the bottom bar.
  ///
  /// Falls back to the screen width for widgets rendered outside the shell.
  static bool hasSidebar(BuildContext context) {
    final mode = maybeOf(context);
    if (mode != null) return mode != ShellMode.bottomBar;
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }

  @override
  bool updateShouldNotify(ShellLayout oldWidget) => oldWidget.mode != mode;
}

/// Main shell widget that provides the bottom navigation structure
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // The art-tinted wash is the bottom layer of the glass stack and has to
    // sit behind every pane in the window, including the page's own
    // Scaffold — hence the transparent scaffold/canvas override for the
    // whole shell subtree.
    return ShellArtTint(
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
          // The theme's AppBar is opaque, which paints a solid band over the
          // wash on every in-shell page that has one. Overriding it here fixes
          // all of them at once instead of page by page.
          appBarTheme: Theme.of(context).appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        // The sidebar shell needs room for a 72-234px rail plus content, so it
        // only takes over from the tablet breakpoint up. Below that the phone
        // shell with the bottom bar is used, including on landscape phones.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= ResponsiveBreakpoints.desktop) {
              return const ShellLayout(
                mode: ShellMode.extendedSidebar,
              ).wrap(_buildSidebarShell(context, extended: true));
            }
            if (width >= ResponsiveBreakpoints.tablet) {
              return const ShellLayout(
                mode: ShellMode.collapsedSidebar,
              ).wrap(_buildSidebarShell(context, extended: false));
            }
            return const ShellLayout(
              mode: ShellMode.bottomBar,
            ).wrap(_buildMobileShell(context));
          },
        ),
      ),
    );
  }

  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedNowPlayingBar(
              onTap: () => context.push(AppRouter.nowPlaying),
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarShell(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: SafeArea(
        child: FeishinShell(extended: extended, child: child),
      ),
    );
  }

  static const List<_NavTab> _tabs = [
    _NavTab(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      route: AppRouter.home,
    ),
    _NavTab(
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      label: 'Library',
      route: AppRouter.library,
    ),
    _NavTab(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Search',
      route: AppRouter.search,
    ),
    _NavTab(
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      label: 'Lists',
      route: AppRouter.playlistManagement,
    ),
  ];

  Widget _buildBottomNavigation(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.sm,
        vertical: OmnisonicSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _NavPillItem(
              tab: _tabs[i],
              selected: currentIndex == i,
              onTap: () => _onItemTapped(i, context),
            ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    switch (location) {
      case AppRouter.home:
      // Starred, servers, downloads and settings are secondary destinations
      // reached from Home's More sheet, so they keep the Home tab lit rather
      // than leaving the bar without a selection.
      case AppRouter.servers:
      case AppRouter.favorites:
      case AppRouter.downloads:
      case AppRouter.settings:
        return 0;
      case AppRouter.library:
      case AppRouter.albumDetail:
      case AppRouter.artistDetail:
      case AppRouter.playlistDetail:
        return 1;
      case AppRouter.search:
        return 2;
      case AppRouter.playlistManagement:
        return 3;
      default:
        return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(_tabs[index].route);
  }
}

class _NavTab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

class _NavPillItem extends StatelessWidget {
  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.sm,
          vertical: OmnisonicSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? tab.selectedIcon : tab.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: OmnisonicTypography.labelSmall.copyWith(
                color: color,
                fontWeight: selected
                    ? OmnisonicTypography.semiBold
                    : OmnisonicTypography.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
