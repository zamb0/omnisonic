import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/formatters.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../ui/presentation/widgets/widgets.dart';
import '../viewmodels/server_management_view_model.dart';
import '../widgets/server_form_dialog.dart';
import '../widgets/server_list_tile.dart';
import '../widgets/server_status_card.dart';

/// Adding, editing and monitoring Subsonic servers.
///
/// Only a failure to *load* the server list replaces the page. Failed adds
/// and edits show in their dialog; failed removals, tests and syncs in a
/// snackbar — the list stays where it is.
class ServerManagementPage extends StatefulWidget {
  const ServerManagementPage({super.key});

  @override
  State<ServerManagementPage> createState() => _ServerManagementPageState();
}

class _ServerManagementPageState extends State<ServerManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  /// Round-trip time from the most recent "Test connection" this session,
  /// keyed by server ID. Not persisted or polled — only ever set by an
  /// explicit user-triggered test.
  final Map<String, Duration> _latencyByServerId = {};

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncing = context.select<ServerManagementViewModel, bool>(
      (vm) => vm.isSyncingAll,
    );

    return Scaffold(
      appBar: PageHeaderAppBar(
        title: 'Servers',
        actions: [
          IconButton(
            icon: syncing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(OmnisonicIcons.sync),
            tooltip: syncing ? 'Syncing all servers…' : 'Sync all servers',
            onPressed: syncing ? null : _syncAll,
          ),
          IconButton(
            icon: const Icon(OmnisonicIcons.add),
            onPressed: () => showServerFormDialog(context),
            tooltip: 'Add server',
          ),
        ],
        bottom: PageHeaderAppBar.tabBar(
          context,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Servers'),
            Tab(text: 'Status'),
          ],
        ),
      ),
      body: Consumer<ServerManagementViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && !viewModel.hasServers) {
            return const LoadingStateView(
              kind: SkeletonKind.list,
              itemCount: 4,
            );
          }

          final error = viewModel.errorMessage;
          if (error != null && !viewModel.hasServers) {
            return ErrorStateView(
              message: error,
              onRetry: () {
                viewModel.clearError();
                viewModel.refreshServers();
              },
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [_buildServersTab(viewModel), _buildStatusTab(viewModel)],
          );
        },
      ),
    );
  }

  Widget _buildServersTab(ServerManagementViewModel viewModel) {
    final servers = viewModel.servers;

    if (servers.isEmpty) {
      return EmptyState(
        icon: OmnisonicIcons.dns,
        title: 'No servers yet',
        subtitle:
            'Add a Subsonic-compatible server — Navidrome, Airsonic, '
            'Gonic — to start listening.',
        action: FilledButton.icon(
          onPressed: () => showServerFormDialog(context),
          icon: const Icon(OmnisonicIcons.add),
          label: const Text('Add server'),
        ),
      );
    }

    final albumCounts = context.select<MusicLibraryViewModel, Map<String, int>>(
      (library) {
        final counts = <String, int>{};
        for (final album in library.albums) {
          counts[album.serverId] = (counts[album.serverId] ?? 0) + 1;
        }
        return counts;
      },
    );

    return RefreshIndicator(
      onRefresh: viewModel.refreshServers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          OmnisonicSpacing.md,
          0,
          OmnisonicSpacing.md,
          OmnisonicSpacing.lg,
        ),
        children: [
          _buildServerSummary(viewModel),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: OmnisonicSpacing.sm),
              child: InlineBanner(
                kind: BannerKind.warning,
                message: viewModel.errorMessage!,
              ),
            ),
          for (final server in servers)
            ServerListTile(
              key: ValueKey(server.id),
              server: server,
              isLoading: viewModel.isServerLoading(server.id),
              albumCount: albumCounts[server.id],
              latency: _latencyByServerId[server.id],
              onTap: () => _showServerDetails(server),
              onEdit: () => showServerFormDialog(context, server: server),
              onTest: () => _testServerConnection(server, viewModel),
              onDelete: () => _confirmRemove(server, viewModel),
            ),
        ],
      ),
    );
  }

  /// Counts as chips in a [Wrap]: the old Row overflowed at ~1.3x text or
  /// 320dp, and carried an Add button that duplicated the app bar's.
  Widget _buildServerSummary(ServerManagementViewModel viewModel) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.sm),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            pluralize(viewModel.serverCount, 'server'),
            style: OmnisonicTypography.titleSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (viewModel.onlineServerCount > 0)
            _CountChip(
              status: ServerStatus.online,
              label: '${viewModel.onlineServerCount} online',
            ),
          if (viewModel.offlineServerCount > 0)
            _CountChip(
              status: ServerStatus.offline,
              label: '${viewModel.offlineServerCount} offline',
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(ServerManagementViewModel viewModel) {
    final stats = viewModel.getServerStatistics();
    final scheme = Theme.of(context).colorScheme;

    Widget tile(ServerStatus? status, String title, int count) {
      final visuals = status == null
          ? null
          : ServerStatusVisuals.of(context, status);
      return ServerStatusCard(
        title: title,
        count: count,
        icon: visuals?.icon ?? OmnisonicIcons.dns,
        color: visuals?.color ?? scheme.primary,
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshServers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        children: [
          const SectionHeader(title: 'Overview', padding: EdgeInsets.zero),
          const SizedBox(height: OmnisonicSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 4 : 2;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final t in [
                    tile(null, 'Total', stats['total']!),
                    tile(ServerStatus.online, 'Online', stats['online']!),
                    tile(ServerStatus.offline, 'Offline', stats['offline']!),
                    tile(
                      ServerStatus.connecting,
                      'Connecting',
                      stats['connecting']!,
                    ),
                  ])
                    SizedBox(width: width, child: t),
                ],
              );
            },
          ),
          const SizedBox(height: OmnisonicSpacing.lg),
          const SectionHeader(title: 'Details', padding: EdgeInsets.zero),
          const SizedBox(height: OmnisonicSpacing.sm),
          if (viewModel.servers.isEmpty)
            const EmptyState(
              icon: OmnisonicIcons.dns,
              title: 'No servers',
              subtitle: 'Add a server to see its status here.',
            )
          else
            for (final server in viewModel.servers)
              _buildServerStatusDetail(server),
        ],
      ),
    );
  }

  Widget _buildServerStatusDetail(MusicServer server) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    server.name,
                    style: OmnisonicTypography.titleSmall.copyWith(
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                StatusChip(status: server.status),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.xs),
            Text(
              server.url,
              style: OmnisonicTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetadataChip(
                  icon: OmnisonicIcons.info,
                  label: 'API ${server.apiVersion ?? 'unknown'}',
                ),
                MetadataChip(
                  icon: OmnisonicIcons.dns,
                  label: 'Server ${server.serverVersion ?? 'unknown'}',
                ),
                MetadataChip(
                  icon: OmnisonicIcons.syncOutline,
                  label: server.lastSync != null
                      ? 'Synced ${formatRelativeTime(server.lastSync!)}'
                      : 'Never synced',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showServerDetails(MusicServer server) {
    final rows = <(String, String)>[
      ('URL', server.url),
      ('Username', server.username),
      ('Status', ServerStatusVisuals.of(context, server.status).label),
      if (server.apiVersion != null) ('API version', server.apiVersion!),
      if (server.serverVersion != null)
        ('Server version', server.serverVersion!),
      ('Added', formatRelativeTime(server.createdAt)),
      if (server.lastSync != null)
        ('Last sync', formatRelativeTime(server.lastSync!)),
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(server.name),
          scrollable: true,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kDialogMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(
                            label,
                            style: OmnisonicTypography.labelMedium.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(child: SelectableText(value)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showServerFormDialog(context, server: server);
              },
              child: const Text('Edit'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testServerConnection(
    MusicServer server,
    ServerManagementViewModel viewModel,
  ) async {
    final result = await viewModel.testConnection(server);
    if (!mounted) return;

    if (result?.responseTime != null) {
      setState(() => _latencyByServerId[server.id] = result!.responseTime!);
    }
    if (result != null && result.isSuccessful) {
      showFeedback(
        context,
        '${server.name} is reachable',
        kind: FeedbackKind.success,
      );
    } else {
      showFeedback(
        context,
        "Couldn't reach ${server.name}",
        kind: FeedbackKind.error,
        actionLabel: 'Retry',
        onAction: () => _testServerConnection(server, viewModel),
      );
    }
  }

  Future<void> _confirmRemove(
    MusicServer server,
    ServerManagementViewModel viewModel,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove "${server.name}"?',
      message:
          'Its tracks and albums leave your library and its saved password '
          'is deleted. Nothing on the server itself changes.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await viewModel.removeServer(server.id);
    if (ok && mounted) {
      showFeedback(
        context,
        'Removed "${server.name}"',
        kind: FeedbackKind.success,
      );
    }
  }

  /// Syncing is harmless, so it starts straight away — the button shows the
  /// progress and a snackbar reports the result, with Retry on failure.
  Future<void> _syncAll() async {
    final viewModel = context.read<ServerManagementViewModel>();
    final ok = await viewModel.syncAllServers();
    if (!mounted) return;
    if (ok) {
      showFeedback(
        context,
        'Library synced from all servers',
        kind: FeedbackKind.success,
      );
    }
    // A failure is reported by the app-wide ActionErrorListener; offer the
    // retry here.
    else {
      viewModel.clearActionError();
      showFeedback(
        context,
        "Couldn't sync your servers",
        kind: FeedbackKind.error,
        actionLabel: 'Retry',
        onAction: _syncAll,
      );
    }
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.status, required this.label});

  final ServerStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final visuals = ServerStatusVisuals.of(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: visuals.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
      ),
      child: Text(
        label,
        style: OmnisonicTypography.labelMedium.copyWith(color: visuals.color),
      ),
    );
  }
}
