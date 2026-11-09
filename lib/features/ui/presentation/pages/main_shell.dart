import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/destinations.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';
import '../widgets/account_menu.dart';
import '../widgets/feishin_shell.dart';
import '../widgets/shell_art_tint.dart';
import '../widgets/shell_page_transition.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/utils/haptics.dart';

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

/// Background for pinned headers inside the shell: transparent over the art
/// wash at rest, a near-opaque surface once content scrolls under it.
WidgetStateColor scrolledUnderSurface(BuildContext context) {
  final surface = Theme.of(context).colorScheme.surface;
  return WidgetStateColor.resolveWith(
    (states) => states.contains(WidgetState.scrolledUnder)
        ? surface.withValues(alpha: 0.94)
        : Colors.transparent,
  );
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
    //
    // The status bar follows the theme here, under every page: only AppBars
    // set it otherwise, so on a page with its own title (Home, Search) it
    // kept whatever the last route left — white over Pearl after closing
    // Now Playing, which is always dark.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ShellArtTint(
        child: ShellTransitionScope(
          child: Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              canvasColor: Colors.transparent,
              // The theme's AppBar is opaque, which paints a solid band over the
              // wash on every in-shell page that has one. Overriding it here fixes
              // all of them at once instead of page by page.
              //
              // Transparent only while nothing is under it: once content scrolls
              // beneath a pinned bar it gets a near-opaque surface, otherwise
              // titles and controls draw on top of the rows.
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                backgroundColor: scrolledUnderSurface(context),
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
                // A phone on its side is wide but very short: the bottom bar, the
                // mini player and the margins took ~140 of ~390px. The icon rail
                // costs width instead, which landscape has to spare.
                final landscapePhone =
                    width > constraints.maxHeight &&
                    width >= 560 &&
                    constraints.maxHeight < 500;
                if (width >= ResponsiveBreakpoints.tablet || landscapePhone) {
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
        ),
      ),
    );
  }

  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => PageGutter(
            value: PageGutter.forWidth(constraints.maxWidth),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          OmnisonicLayout.chromeInset,
          0,
          OmnisonicLayout.chromeInset,
          OmnisonicLayout.chromeInset,
        ),
        // The bar and the nav pills are fixed furniture with nowhere to
        // reflow: past ~1.3x they would take the screen away from the
        // content the user enlarged the text to read. The page itself is
        // outside this and scales without limit.
        child: OmnisonicTextScale.clampChrome(
          context,
          Column(
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

  Widget _buildBottomNavigation(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final destinations = AppDestinations.primary;
    // The Account slot sits after the primary destinations and shares the
    // one sliding indicator: any page behind it lights it.
    final accountIndex = destinations.length;
    final currentIndex =
        AppDestinations.selectedPrimaryIndex(path) ??
        (AppDestinations.isSecondary(path) ? accountIndex : null);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.xs,
        vertical: OmnisonicSpacing.sm,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _SlidingIndicator(
              index: currentIndex,
              slots: destinations.length + 1,
            ),
          ),
          // Expanded rather than fixed: five slots on a 375px phone at the
          // largest chrome text size do not fit side by side, and the labels
          // have to ellipsize rather than overflow. Expanded, not Flexible —
          // loose slots bunched up on the left with the right of the bar
          // empty.
          Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavPillItem(
                    destination: destinations[i],
                    selected: currentIndex == i,
                    onTap: () {
                      if (currentIndex == i) return;
                      Haptics.selection();
                      context.go(destinations[i].route);
                    },
                  ),
                ),
              const Expanded(
                child: AccountButton(axis: Axis.vertical, showLabel: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The `wellHover` pill behind the current bottom-bar item. One pill slides
/// between slots (`normal`, `spring`) instead of each item fading its own,
/// so the eye follows where it went. It fades out when no slot is current
/// (the queue, Now Playing) and does not move with reduce motion.
class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator({required this.index, required this.slots});

  /// The lit slot, or null.
  final int? index;
  final int slots;

  /// The pill around an icon: wide enough for the glyph with air.
  static const double pillWidth = 52;
  static const double pillHeight = 28;

  @override
  Widget build(BuildContext context) {
    final surfaces = OmnisonicSurfaces.of(context);
    final slot = index ?? 0;
    final duration = AnimationUtils.adjustedDuration(
      context,
      AnimationManager.normalDuration,
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The pill is centred on its slot: the slots are equal fifths
            // of the bar, like the Expanded items in front of it.
            final slotWidth = constraints.maxWidth / slots;
            return Stack(
              children: [
                AnimatedPositioned(
                  // The icon sits one `xs` below the top of its slot.
                  top: OmnisonicSpacing.xs,
                  left: slotWidth * (slot + 0.5) - pillWidth / 2,
                  duration: duration,
                  curve: AnimationManager.springCurve,
                  child: AnimatedOpacity(
                    opacity: index == null ? 0 : 1,
                    duration: AnimationUtils.adjustedDuration(
                      context,
                      AnimationManager.fastDuration,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surfaces.wellHover,
                        borderRadius: BorderRadius.circular(
                          OmnisonicRadius.full,
                        ),
                      ),
                      child: const SizedBox(
                        width: pillWidth,
                        height: pillHeight,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The pill itself is the sliding indicator behind the row;
              // this only holds the icon in its 52 x 28 footprint.
              SizedBox(
                width: _SlidingIndicator.pillWidth,
                height: _SlidingIndicator.pillHeight,
                child: Icon(
                  selected ? destination.activeIcon : destination.icon,
                  color: color,
                  size: OmnisonicIconSizes.smd,
                ),
              ),
              const SizedBox(height: OmnisonicSpacing.xxs),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmnisonicTypography.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
