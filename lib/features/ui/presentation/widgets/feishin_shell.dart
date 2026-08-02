import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../models/library_tab.dart';
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
            child: _buildSidebar(context),
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
                child: AnimatedNowPlayingBar(
                  onTap: () => context.push(AppRouter.nowPlaying),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
      padding: EdgeInsets.symmetric(
        horizontal: extended ? 14 : 8,
        vertical: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrand(context),
          const SizedBox(height: 18),
          // Scrolls instead of overflowing on short windows — the SERVERS
          // section and health card below are pinned outside this so they
          // stay visible regardless of nav-item count.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildNavItems(context),
              ),
            ),
          ),
          _buildServersSection(context),
          const SizedBox(height: 12),
          _buildLibraryHealthCard(context),
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
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(Icons.graphic_eq_rounded, size: 14, color: scheme.surface),
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
              style: OmnisonicTypography.sectionTitleSmall.copyWith(
                fontSize: 17,
                letterSpacing: -0.17,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    final location = GoRouterState.of(context).uri;
    final path = location.path;
    final isLibrary =
        path == AppRouter.library ||
        path == AppRouter.albumDetail ||
        path == AppRouter.artistDetail;
    final activeLibraryTab =
        LibraryTab.fromName(location.queryParameters['tab']) ??
        LibraryTab.albums;

    final library = context.watch<MusicLibraryViewModel>();

    return [
      _NavItem(
        extended: extended,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        selected: path == AppRouter.home,
        onTap: () => context.go(AppRouter.home),
      ),
      _NavItem(
        extended: extended,
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: 'Search',
        selected: path == AppRouter.search,
        onTap: () => context.go(AppRouter.search),
      ),
      _NavItem(
        extended: extended,
        icon: Icons.album_outlined,
        activeIcon: Icons.album,
        label: 'Albums',
        count: library.albumCount,
        selected: isLibrary && activeLibraryTab == LibraryTab.albums,
        onTap: () => _goToLibraryTab(context, LibraryTab.albums),
      ),
      _NavItem(
        extended: extended,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Artists',
        count: library.artistCount,
        selected: isLibrary && activeLibraryTab == LibraryTab.artists,
        onTap: () => _goToLibraryTab(context, LibraryTab.artists),
      ),
      _NavItem(
        extended: extended,
        icon: Icons.playlist_play_outlined,
        activeIcon: Icons.playlist_play,
        label: 'Playlists',
        selected: isLibrary && activeLibraryTab == LibraryTab.playlists,
        onTap: () => _goToLibraryTab(context, LibraryTab.playlists),
      ),
      _NavItem(
        extended: extended,
        icon: Icons.star_outline,
        activeIcon: Icons.star,
        label: 'Starred',
        selected: path == AppRouter.favorites,
        onTap: () => context.go(AppRouter.favorites),
      ),
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
        icon: Icons.dns_outlined,
        activeIcon: Icons.dns,
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
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(OmnisonicRadius.full),
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
        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.4),
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
                  style: OmnisonicTypography.technical.copyWith(
                    fontSize: 9.5,
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
      return Center(
        child: Icon(
          isSyncing ? Icons.sync : Icons.health_and_safety_outlined,
          size: 18,
          color: scheme.onSurfaceVariant,
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
              fontSize: 12,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (losslessShare * 1000).round(),
                    child: ColoredBox(color: scheme.onSurface),
                  ),
                  Expanded(
                    flex: (highShare * 1000).round(),
                    child: ColoredBox(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - losslessShare - highShare) * 1000)
                        .round()
                        .clamp(0, 1000),
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
            style: OmnisonicTypography.technical.copyWith(
              fontSize: 9.5,
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
                  size: 22,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmnisonicTypography.labelSmall.copyWith(
                    fontSize: 10,
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
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
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
                      style: OmnisonicTypography.technical.copyWith(
                        fontSize: 10,
                        color: foreground.withValues(alpha: 0.6),
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
