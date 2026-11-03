import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../../core/utils/formatters.dart';

/// Desktop side rail: what the aggregated collection actually contains, what
/// gets played most, and where the last sync got to.
///
/// Every figure here is derived from the loaded collection — there is no
/// listening-history store behind the app, so "top artists" is ranked by the
/// most-played tracks the servers report rather than by local play counts.
class LibraryStatsRail extends StatelessWidget {
  const LibraryStatsRail({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
        padding: const EdgeInsets.all(16),
        child: Consumer<MusicLibraryViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _eyebrow(context, 'COLLECTION'),
                  const SizedBox(height: 12),
                  _StatGrid(
                    stats: [
                      _Stat(_compact(viewModel.albumCount), 'albums'),
                      _Stat(_compact(viewModel.artistCount), 'artists'),
                      _Stat(_compact(viewModel.trackCount), 'tracks'),
                      _Stat(_compact(viewModel.duplicateGroupCount), 'merged'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _eyebrow(context, 'TOP ARTISTS'),
                  const SizedBox(height: 10),
                  _TopArtists(viewModel: viewModel),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // "Up to date" only when that is true: it used to
                          // say so with no sync ever run, or right after a
                          // failed one.
                          viewModel.isSyncing
                              ? 'Syncing servers'
                              : viewModel.errorMessage != null
                              ? 'Last sync failed'
                              : viewModel.lastUpdated == null
                              ? 'Not synced yet'
                              : 'Synced ${formatRelativeTime(viewModel.lastUpdated!)}',
                          style: OmnisonicTypography.glassButton.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          viewModel.duplicateGroupCount > 0
                              ? '${viewModel.duplicateGroupCount} duplicate '
                                    'groups merged'
                              : 'no duplicates found',
                          style: OmnisonicTypography.technicalSmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _eyebrow(BuildContext context, String label) {
    return Text(
      label,
      style: OmnisonicTypography.eyebrow.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 1,204 -> "1.2k". Stat tiles are 130px wide; full counts wrap.
  static String _compact(int value) {
    if (value < 1000) return '$value';
    if (value < 100000) {
      final thousands = value / 1000;
      return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}k';
    }
    return '${(value / 1000).round()}k';
  }
}

class _Stat {
  const _Stat(this.value, this.label);

  final String value;
  final String label;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The tile is two lines of text in a fixed-aspect cell, so its height
    // has to follow the text size — at 2x the label fell out of the bottom.
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.85 / textScale,
      children: [
        for (final stat in stats)
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: OmnisonicColors.glassFill(
                isDark ? Brightness.dark : Brightness.light,
              ),
              borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmnisonicTypography.statValue.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmnisonicTypography.technicalSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopArtists extends StatelessWidget {
  const _TopArtists({required this.viewModel});

  final MusicLibraryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ranked = _rank(viewModel);

    if (ranked.isEmpty) {
      return Text(
        'Play something to see this fill in.',
        style: OmnisonicTypography.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    final top = ranked.first.value;

    return Column(
      children: [
        for (final entry in ranked)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OmnisonicTypography.bodySmall.copyWith(
                          fontWeight: OmnisonicTypography.semiBold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: OmnisonicTypography.technicalSmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
                  child: LinearProgressIndicator(
                    value: top == 0 ? 0 : entry.value / top,
                    minHeight: 5,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.09),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Artists ranked by how many of their tracks appear in the server-reported
  /// most-played list, falling back to recently-played when nothing has
  /// accumulated yet.
  static List<MapEntry<String, int>> _rank(MusicLibraryViewModel viewModel) {
    final source = viewModel.mostPlayed.isNotEmpty
        ? viewModel.mostPlayed
        : viewModel.recentlyPlayed;

    final counts = <String, int>{};
    for (final track in source) {
      if (track.artist.isEmpty) continue;
      counts[track.artist] = (counts[track.artist] ?? 0) + 1;
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.take(4).toList();
  }
}
