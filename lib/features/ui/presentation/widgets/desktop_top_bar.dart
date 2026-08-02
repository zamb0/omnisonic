import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_router.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../sync/presentation/bloc/sync_bloc.dart';

/// Desktop content-column header: a glass search field, the last-sync
/// timestamp, a "Sync now" action and an avatar-style shortcut into
/// settings.
///
/// The sidebar deliberately carries no search entry of its own — search is a
/// content-area concern in the redesign, reachable from anywhere with ⌘K.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Row(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _SearchField(),
            ),
          ),
          const Spacer(),
          Consumer<MusicLibraryViewModel>(
            builder: (context, viewModel, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  viewModel.isSyncing
                      ? 'syncing…'
                      : 'last sync ${_relativeTime(viewModel.lastUpdated)}',
                  style: OmnisonicTypography.technical.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          _GlassButton(
            label: 'Sync now',
            onTap: () => context.read<SyncBloc>().add(
              const SyncStarted(forceRefresh: true),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Settings',
            child: InkWell(
              onTap: () => context.go(AppRouter.settings),
              borderRadius: BorderRadius.circular(OmnisonicRadius.full),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.onSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: scheme.surface,
                ),
              ),
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

    return InkWell(
      onTap: () => context.go(AppRouter.search),
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.search, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
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
            Text(
              '⌘K',
              style: OmnisonicTypography.technical.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OmnisonicRadius.md),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.md),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Text(
          label,
          style: OmnisonicTypography.glassButton.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
