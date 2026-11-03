import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/search_focus.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';

/// Desktop content-column header: a glass search field, the last-sync
/// timestamp and a "Sync now" action. Settings are reached through the
/// sidebar's account button — there used to be a second, identical-looking
/// avatar here that did something different.
///
/// The sidebar deliberately carries no search entry of its own — search is a
/// content-area concern in the redesign, reachable from anywhere with ⌘K.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSearch = GoRouterState.of(context).uri.path == AppRouter.search;

    final gutter = PageGutter.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, OmnisonicSpacing.sm),
      child: Row(
        children: [
          // Not on /search, which has its own field: two search boxes on
          // one screen, only one of which works, is a puzzle.
          if (!onSearch)
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _SearchField(),
              ),
            ),
          const Spacer(),
          Consumer2<MusicLibraryViewModel, ServerManagementViewModel>(
            builder: (context, viewModel, servers, child) {
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: OmnisonicSpacing.ms),
                  child: Text(
                    // Without a server there is no sync to report: it said
                    // "last sync just now" on a fresh install.
                    !servers.hasServers
                        ? 'no servers yet'
                        : viewModel.isSyncing
                        ? 'syncing…'
                        : 'last sync ${_relativeTime(viewModel.lastUpdated)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmnisonicTypography.technical.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
          // Syncs through the library view model, the same path the library
          // page uses, so the "syncing…" label to the left of this button and
          // the in-memory collection both reflect what the button started.
          if (context.select<ServerManagementViewModel, bool>(
            (vm) => vm.hasServers,
          ))
            _GlassButton(
              label: 'Sync now',
              onTap: () => context.read<MusicLibraryViewModel>().syncCollection(
                forceRefresh: true,
              ),
            ),
        ],
      ),
    );
  }

  /// "4 min ago" / "2 h ago" — deliberately coarse, since the exact second a
  /// sync finished is never actionable.
  static String _relativeTime(DateTime? at) {
    if (at == null) return 'never';
    final elapsed = DateTime.now().difference(at);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} h ago';
    return '${elapsed.inDays} d ago';
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassInkButton(
      onTap: () {
        SearchFocusRequest.request();
        context.go(AppRouter.search);
      },
      borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.md,
        vertical: OmnisonicSpacing.ms,
      ),
      semanticLabel: 'Search',
      child: Row(
        children: [
          Icon(
            OmnisonicIcons.search,
            size: OmnisonicIconSizes.smd,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: OmnisonicSpacing.sm),
          Expanded(
            child: Text(
              'Search albums, artists, tracks — all servers',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmnisonicTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.sm),
          // A key cap, so the shortcut reads as a shortcut and not as part
          // of the placeholder.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
              vertical: OmnisonicSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: OmnisonicSurfaces.of(context).well,
              borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
              border: Border.all(color: OmnisonicSurfaces.of(context).hairline),
            ),
            child: Text(
              '⌘K',
              style: OmnisonicTypography.technicalSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small glass-chip button — the redesign's secondary action treatment.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassInkButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OmnisonicRadius.full),
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.md,
        vertical: OmnisonicSpacing.ms,
      ),
      child: Text(
        label,
        style: OmnisonicTypography.glassButton.copyWith(
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
