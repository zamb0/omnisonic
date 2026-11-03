import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/destinations.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../models/library_tab.dart';
import '../widgets/account_menu.dart';
import '../widgets/desktop_top_bar.dart';
import '../widgets/server_dot.dart';
import '../../../playback/presentation/widgets/animated_now_playing_bar.dart';

/// Desktop / tablet shell: a floating glass sidebar down the left, and a
/// content column carrying the top bar, the current page and the floating
/// player bar.
///
/// Nothing here is flush against the window edge — every pane is inset so the
/// art-tinted background stays visible around and behind it, which is what
/// makes the glass read as glass rather than as a grey panel.
class FeishinShell extends StatelessWidget {
  const FeishinShell({super.key, required this.child, required this.extended});

  final Widget child;
  final bool extended;

  /// Pane widths from the design's `246px 1fr` grid, minus the 12px inset.
  static const double _extendedWidth = 234;
  static const double _railWidth = 72;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
          child: SizedBox(
            width: extended ? _extendedWidth : _railWidth,
            // The rail is a fixed 72px and the sidebar a fixed 234; neither
            // can widen to fit larger labels, so the chrome stops growing
            // where the content does not.
            child: OmnisonicTextScale.clampChrome(
              context,
              _buildSidebar(context),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Column(
                    children: [
                      if (extended) const DesktopTopBar(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 14, 12),
                child: OmnisonicTextScale.clampChrome(
                  context,
                  AnimatedNowPlayingBar(
                    onTap: () => context.push(AppRouter.nowPlaying),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    // A landscape phone gives the rail ~360pt: the default insets left the
    // nav items half cut off.
    final short = MediaQuery.sizeOf(context).height < 500;
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
      padding: EdgeInsets.symmetric(
        horizontal: extended ? 14 : 8,
        vertical: short ? 10 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrand(context),
          SizedBox(height: short ? 8 : 18),
          // Everything below the brand scrolls. The nav items alone used to
          // scroll while the SERVERS list and the health card were pinned
          // outside it, which overflows a short window as soon as enough
          // servers are configured — that list has no upper bound.
          //
          // The thumb shows whenever the items do not fit, so a clipped
          // item reads as "scroll for more" rather than as a glitch.
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildNavItems(context),
                    _buildServersSection(context),
                    const SizedBox(height: 12),
                    _buildLibraryHealthCard(context),
                  ],
                ),
              ),
            ),
          ),
          // Pinned below the scroll area, and present in rail mode too. The
          // only way to Settings on desktop used to be the top bar, which is
          // hidden below 1024px — so at rail width there was no route to it
          // at all.
          const Divider(height: OmnisonicSpacing.lg),
          Align(
            alignment: extended ? Alignment.centerLeft : Alignment.center,
            child: AccountButton(showLabel: extended),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
      ),
      child: Icon(
        OmnisonicIcons.graphicEq,
        size: OmnisonicIconSizes.inline,
        color: scheme.surface,
      ),
    );

    if (!extended) return Center(child: mark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Omnisonic',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmnisonicTypography.wordmark.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The four primary destinations, with Library expanded into its own tabs.
  ///
  /// The sidebar has the vertical room to show Albums and Artists as their
  /// own rows where the bottom bar has to collapse them into one Library
  /// slot. The *set* of destinations still comes from [AppDestinations], so
  /// the two shells cannot drift apart on what exists — only on how deeply
  /// Library is unfolded.
  List<Widget> _buildNavItems(BuildContext context) {
    final location = GoRouterState.of(context).uri;
    final path = location.path;
    final library = context.watch<MusicLibraryViewModel>();

    final libraryDestination = AppDestinations.primary.firstWhere(
      (d) => d.route == AppRouter.library,
    );
    final isLibrary = libraryDestination.matches(path);
    // Derived from where the user actually is: an artist page used to light
    // "Albums", because the missing ?tab= defaulted to albums.
    final activeLibraryTab = switch (path) {
      AppRouter.artistDetail => LibraryTab.artists,
      AppRouter.albumDetail => LibraryTab.albums,
      _ =>
        LibraryTab.fromName(location.queryParameters['tab']) ??
            LibraryTab.albums,
    };

    Widget item(AppDestination destination) => _NavItem(
      extended: extended,
      icon: destination.icon,
      activeIcon: destination.activeIcon,
      label: destination.label,
      selected: destination.matches(path),
      onTap: () => context.go(destination.route),
    );

    return [
      item(AppDestinations.primary[0]), // Home
      item(AppDestinations.primary[1]), // Search
      _NavItem(
        extended: extended,
        icon: OmnisonicIcons.albumOutline,
        activeIcon: OmnisonicIcons.album,
        label: 'Albums',
        count: library.albumCount,
        selected: isLibrary && activeLibraryTab == LibraryTab.albums,
        onTap: () => _goToLibraryTab(context, LibraryTab.albums),
      ),
      _NavItem(
        extended: extended,
        icon: OmnisonicIcons.personOutline,
        activeIcon: OmnisonicIcons.person,
        label: 'Artists',
        count: library.artistCount,
        selected: isLibrary && activeLibraryTab == LibraryTab.artists,
        onTap: () => _goToLibraryTab(context, LibraryTab.artists),
      ),
      item(AppDestinations.primary[3]), // Playlists
    ];
  }

  /// SERVERS section: one glass row per connected server (dot + name + a
  /// short ID fragment) instead of a single generic "Servers" nav item, plus
  /// a trailing `+` to open full server management.
  Widget _buildServersSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final servers = context.watch<ServerManagementViewModel>().servers;
    final path = GoRouterState.of(context).uri.path;

    if (!extended) {
      return _NavItem(
        extended: false,
        icon: OmnisonicIcons.dnsOutline,
        activeIcon: OmnisonicIcons.dns,
        label: 'Servers',
        selected: path == AppRouter.servers,
        onTap: () => context.go(AppRouter.servers),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 22, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SERVERS',
                  style: OmnisonicTypography.eyebrow.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add a server',
                onPressed: () => context.go(AppRouter.servers),
                icon: const Icon(OmnisonicIcons.add),
                iconSize: OmnisonicIconSizes.sm,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (servers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Text(
              'No servers yet',
              style: OmnisonicTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final server in servers) _buildServerRow(context, server),
      ],
    );
  }

  Widget _buildServerRow(BuildContext context, MusicServer server) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: OmnisonicColors.glassFill(
          isDark ? Brightness.dark : Brightness.light,
          light: 0.4,
          dark: 0.05,
        ),
        borderRadius: BorderRadius.circular(OmnisonicRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(OmnisonicRadius.md),
          onTap: () => context.go(AppRouter.servers),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              children: [
                ServerDot(serverId: server.id, size: 8),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    server.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmnisonicTypography.bodySmall.copyWith(
                      fontWeight: OmnisonicTypography.semiBold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  _shortId(server.id),
                  style: OmnisonicTypography.technicalSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length <= 6 ? id : id.substring(id.length - 6);

  Widget _buildLibraryHealthCard(BuildContext context) {
    if (!extended) {
      final scheme = Theme.of(context).colorScheme;
      final isSyncing = context.select<MusicLibraryViewModel, bool>(
        (viewModel) => viewModel.isSyncing,
      );
      // Only a sync indicator: at rest the unlabelled shield looked like a
      // nav item that did nothing.
      if (!isSyncing) return const SizedBox.shrink();
      return Center(
        child: Tooltip(
          message: 'Syncing library',
          child: Icon(
            OmnisonicIcons.sync,
            size: OmnisonicIconSizes.smd,
            color: scheme.onSurfaceVariant,
            semanticLabel: 'Syncing library',
          ),
        ),
      );
    }

    return const _LibraryHealthCard();
  }

  void _goToLibraryTab(BuildContext context, LibraryTab tab) {
    context.go('${AppRouter.library}?tab=${tab.name}');
  }
}

/// Real aggregate stats from [MusicLibraryViewModel]: what share of the
/// collection is lossless / high-bitrate, and how many duplicate groups the
/// dedup engine has merged.
///
/// Stateful purely to cache the quality tally — the sidebar rebuilds on every
/// view-model notification, and a full sweep of a large collection per frame
/// is not something a decorative bar should cost.
class _LibraryHealthCard extends StatefulWidget {
  const _LibraryHealthCard();

  @override
  State<_LibraryHealthCard> createState() => _LibraryHealthCardState();
}

class _LibraryHealthCardState extends State<_LibraryHealthCard> {
  List<Track>? _tallyFor;
  double _losslessShare = 0;
  double _highShare = 0;

  void _retally(List<Track> tracks) {
    if (identical(tracks, _tallyFor)) return;
    _tallyFor = tracks;

    var lossless = 0;
    var high = 0;
    for (final track in tracks) {
      final score = track.quality.qualityScore;
      if (score >= 4) {
        lossless++;
      } else if (score == 3) {
        high++;
      }
    }
    final total = tracks.length;
    _losslessShare = total == 0 ? 0 : lossless / total;
    _highShare = total == 0 ? 0 : high / total;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final library = context.watch<MusicLibraryViewModel>();
    _retally(library.tracks);

    final losslessShare = _losslessShare;
    final highShare = _highShare;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library health',
            style: OmnisonicTypography.glassButton.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
            child: SizedBox(
              height: 6,
              // Flex values are clamped to at least 1: an empty library makes
              // every share 0, and a Row whose children all have flex 0 has
              // nothing to distribute its width to.
              child: Row(
                children: [
                  Expanded(
                    flex: (losslessShare * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: scheme.onSurface),
                  ),
                  Expanded(
                    flex: (highShare * 1000).round().clamp(1, 1000),
                    child: ColoredBox(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - losslessShare - highShare) * 1000)
                        .round()
                        .clamp(1, 1000),
                    child: ColoredBox(
                      color: scheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${(losslessShare * 100).round()}% lossless · '
            '${library.duplicateGroupCount} dupes merged',
            style: OmnisonicTypography.technicalSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar row. Extended mode follows the design's marker-dot + Gabarito
/// label + optional mono count; the collapsed rail keeps icons, since a
/// column of identical dots would be unusable without labels.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.extended,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final bool extended;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!extended) {
      return Semantics(
        selected: selected,
        button: true,
        child: InkResponse(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: OmnisonicIconSizes.md,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmnisonicTypography.labelSmall.copyWith(
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Selected rows invert to a solid ink pill — the redesign's single
    // strongest accent, used sparingly so it always means "you are here".
    final foreground = selected ? scheme.surface : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? scheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(OmnisonicRadius.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(OmnisonicRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OmnisonicTypography.navLabel.copyWith(
                        color: selected ? scheme.surface : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (count != null && count! > 0)
                    Text(
                      '$count',
                      // Full-strength foreground: at 60% the count was
                      // under 3:1 on the selected pill.
                      style: OmnisonicTypography.technicalSmall.copyWith(
                        color: foreground,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
