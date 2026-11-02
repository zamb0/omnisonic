import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../viewmodels/server_management_view_model.dart';
import '../widgets/server_add_dialog.dart';
import '../widgets/server_edit_dialog.dart';
import '../widgets/server_list_tile.dart';
import '../widgets/server_status_card.dart';
import '../../../ui/presentation/widgets/widgets.dart';

/// Enhanced server management page for adding, configuring, and monitoring Subsonic servers
class ServerManagementPage extends StatefulWidget {
  const ServerManagementPage({super.key});

  @override
  State<ServerManagementPage> createState() => _ServerManagementPageState();
}

class _ServerManagementPageState extends State<ServerManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Round-trip time from the most recent "Test Connection" this session,
  /// keyed by server ID. Not persisted or polled — only ever set by an
  /// explicit user-triggered test.
  final Map<String, Duration> _latencyByServerId = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Management'),
        actions: [
          IconButton(
            icon: const Icon(OmnisonicIcons.add),
            onPressed: () => _showAddServerDialog(context),
            tooltip: 'Add Server',
          ),
          IconButton(
            icon: const Icon(OmnisonicIcons.refresh),
            onPressed: () => _refreshServers(context),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sync':
                  _syncAllServers(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(OmnisonicIcons.sync),
                    SizedBox(width: 8),
                    Text('Sync All Servers'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Servers', icon: Icon(OmnisonicIcons.dns)),
            Tab(text: 'Status', icon: Icon(OmnisonicIcons.monitorHeart)),
          ],
        ),
      ),
      body: Consumer<ServerManagementViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const LoadingStateView(
              kind: SkeletonKind.list,
              itemCount: 4,
            );
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    OmnisonicIcons.errorOutline,
                    size: OmnisonicIconSizes.xxxl,
                    color: scheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: OmnisonicTypography.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.refreshServers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
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
        title: 'No Servers Connected',
        subtitle:
            'Add your first Subsonic server to get started with music streaming',
        action: ElevatedButton.icon(
          onPressed: () => _showAddServerDialog(context),
          icon: const Icon(OmnisonicIcons.add),
          label: const Text('Add Server'),
        ),
      );
    }

    return Consumer<MusicLibraryViewModel>(
      builder: (context, libraryViewModel, child) {
        final albumCounts = <String, int>{};
        for (final album in libraryViewModel.albums) {
          albumCounts[album.serverId] = (albumCounts[album.serverId] ?? 0) + 1;
        }

        return RefreshIndicator(
          onRefresh: viewModel.refreshServers,
          child: Column(
            children: [
              _buildServerSummary(viewModel),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    return ServerListTile(
                      server: server,
                      isLoading: viewModel.isServerLoading(server.id),
                      albumCount: albumCounts[server.id],
                      latency: _latencyByServerId[server.id],
                      onTap: () => _showServerDetails(context, server),
                      onEdit: () => _showEditServerDialog(context, server),
                      onTest: () =>
                          _testServerConnection(context, server, viewModel),
                      onDelete: () =>
                          _showDeleteConfirmation(context, server, viewModel),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTab(ServerManagementViewModel viewModel) {
    final stats = viewModel.getServerStatistics();

    return RefreshIndicator(
      onRefresh: viewModel.refreshServers,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server Statistics', style: OmnisonicTypography.sectionTitle),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ServerStatusCard(
                    title: 'Total Servers',
                    count: stats['total']!,
                    icon: OmnisonicIcons.dns,
                    color: OmnisonicColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ServerStatusCard(
                    title: 'Online',
                    count: stats['online']!,
                    icon: OmnisonicIcons.checkCircle,
                    color: OmnisonicColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ServerStatusCard(
                    title: 'Offline',
                    count: stats['offline']!,
                    icon: OmnisonicIcons.error,
                    color: OmnisonicColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ServerStatusCard(
                    title: 'Connecting',
                    count: stats['connecting']!,
                    icon: OmnisonicIcons.sync,
                    color: OmnisonicColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Server Details', style: OmnisonicTypography.sectionTitle),
            const SizedBox(height: 16),
            if (viewModel.servers.isEmpty)
              const EmptyState(
                icon: OmnisonicIcons.dns,
                title: 'No Servers',
                subtitle: 'Add servers to see detailed status information',
              )
            else
              ...viewModel.servers.map(
                (server) => _buildServerStatusDetail(server),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSummary(ServerManagementViewModel viewModel) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(OmnisonicIcons.dns, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '${viewModel.serverCount} server${viewModel.serverCount != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: OmnisonicColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(OmnisonicRadius.md),
            ),
            child: Text(
              '${viewModel.onlineServerCount} online',
              style: const TextStyle(
                color: OmnisonicColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (viewModel.offlineServerCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: OmnisonicColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(OmnisonicRadius.md),
              ),
              child: Text(
                '${viewModel.offlineServerCount} offline',
                style: const TextStyle(
                  color: OmnisonicColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddServerDialog(context),
            icon: const Icon(OmnisonicIcons.add, size: 16),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusDetail(MusicServer server) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    server.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(server.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              server.url,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('API', server.apiVersion ?? 'Unknown'),
                const SizedBox(width: 8),
                _buildInfoChip('Version', server.serverVersion ?? 'Unknown'),
              ],
            ),
            if (server.lastSync != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last sync: ${_formatDateTime(server.lastSync!)}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ServerStatus status) {
    // Colour comes from the palette; only the icon and label are per-status.
    final color = OmnisonicColors.statusColorFor(status);
    late final IconData icon;
    late final String text;

    switch (status) {
      case ServerStatus.online:
        icon = OmnisonicIcons.checkCircle;
        text = 'Online';
        break;
      case ServerStatus.offline:
        icon = OmnisonicIcons.error;
        text = 'Offline';
        break;
      case ServerStatus.connecting:
        icon = OmnisonicIcons.sync;
        text = 'Connecting';
        break;
      case ServerStatus.authenticating:
        icon = OmnisonicIcons.lock;
        text = 'Authenticating';
        break;
      case ServerStatus.syncing:
        icon = OmnisonicIcons.syncAlt;
        text = 'Syncing';
        break;
      case ServerStatus.error:
        icon = OmnisonicIcons.warning;
        text = 'Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OmnisonicRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: OmnisonicIconSizes.xs, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? scheme.onSurfaceVariant).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color ?? scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddServerDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const ServerAddDialog());
  }

  void _showEditServerDialog(BuildContext context, MusicServer server) {
    showDialog(
      context: context,
      builder: (context) => ServerEditDialog(server: server),
    );
  }

  void _showServerDetails(BuildContext context, MusicServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(server.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('URL', server.url),
            _buildDetailRow('Username', server.username),
            _buildDetailRow('Status', server.status.toString().split('.').last),
            if (server.apiVersion != null)
              _buildDetailRow('API Version', server.apiVersion!),
            if (server.serverVersion != null)
              _buildDetailRow('Server Version', server.serverVersion!),
            _buildDetailRow('Created', _formatDateTime(server.createdAt)),
            if (server.lastSync != null)
              _buildDetailRow('Last Sync', _formatDateTime(server.lastSync!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _testServerConnection(
    BuildContext context,
    MusicServer server,
    ServerManagementViewModel viewModel,
  ) async {
    final result = await viewModel.testConnection(server);

    if (result != null && result.responseTime != null) {
      setState(() => _latencyByServerId[server.id] = result.responseTime!);
    }

    if (context.mounted) {
      if (result != null && result.isSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection to ${server.name} successful'),
            backgroundColor: OmnisonicColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection to ${server.name} failed: ${result?.errorMessage ?? 'Unknown error'}',
            ),
            backgroundColor: OmnisonicColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    MusicServer server,
    ServerManagementViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server'),
        content: Text(
          'Are you sure you want to delete "${server.name}"? This will remove all cached data from this server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await viewModel.removeServer(server.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${server.name}"')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshServers(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Refreshing servers...')),
    );

    final success = await context
        .read<ServerManagementViewModel>()
        .refreshServers();
    if (!context.mounted) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Servers refreshed' : 'Refresh failed'),
        action: success
            ? null
            : SnackBarAction(
                label: 'Retry',
                onPressed: () => _refreshServers(context),
              ),
      ),
    );
  }

  void _syncAllServers(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Music Collection'),
        content: const Text(
          'This will sync music metadata from all connected servers. This may take a few minutes depending on your library size.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSync(context);
            },
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  void _performSync(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Syncing music collection...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Trigger sync for all servers
    final viewModel = context.read<ServerManagementViewModel>();
    viewModel.syncAllServers();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
