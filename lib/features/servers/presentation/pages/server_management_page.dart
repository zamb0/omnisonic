import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../viewmodels/server_management_view_model.dart';
import '../widgets/server_add_dialog.dart';
import '../widgets/server_edit_dialog.dart';
import '../widgets/server_list_tile.dart';
import '../widgets/server_status_card.dart';
import '../../../ui/presentation/widgets/loading_indicator.dart';
import '../../../ui/presentation/widgets/empty_state.dart';

/// Enhanced server management page for adding, configuring, and monitoring Subsonic servers
class ServerManagementPage extends StatefulWidget {
  const ServerManagementPage({super.key});

  @override
  State<ServerManagementPage> createState() => _ServerManagementPageState();
}

class _ServerManagementPageState extends State<ServerManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServerDialog(context),
            tooltip: 'Add Server',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
                    Icon(Icons.sync),
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
            Tab(text: 'Servers', icon: Icon(Icons.dns)),
            Tab(text: 'Status', icon: Icon(Icons.monitor_heart)),
          ],
        ),
      ),
      body: Consumer<ServerManagementViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
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
        icon: Icons.dns,
        title: 'No Servers Connected',
        subtitle:
            'Add your first Subsonic server to get started with music streaming',
        action: ElevatedButton.icon(
          onPressed: () => _showAddServerDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Server'),
        ),
      );
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
            Text(
              'Server Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ServerStatusCard(
                    title: 'Total Servers',
                    count: stats['total']!,
                    icon: Icons.dns,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ServerStatusCard(
                    title: 'Online',
                    count: stats['online']!,
                    icon: Icons.check_circle,
                    color: Colors.green,
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
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ServerStatusCard(
                    title: 'Connecting',
                    count: stats['connecting']!,
                    icon: Icons.sync,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Server Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (viewModel.servers.isEmpty)
              const EmptyState(
                icon: Icons.dns,
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.dns, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '${viewModel.serverCount} server${viewModel.serverCount != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${viewModel.onlineServerCount} online',
              style: const TextStyle(
                color: Colors.green,
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${viewModel.offlineServerCount} offline',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddServerDialog(context),
            icon: const Icon(Icons.add, size: 16),
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
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ServerStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case ServerStatus.online:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Online';
        break;
      case ServerStatus.offline:
        color = Colors.red;
        icon = Icons.error;
        text = 'Offline';
        break;
      case ServerStatus.connecting:
        color = Colors.orange;
        icon = Icons.sync;
        text = 'Connecting';
        break;
      case ServerStatus.authenticating:
        color = Colors.blue;
        icon = Icons.lock;
        text = 'Authenticating';
        break;
      case ServerStatus.syncing:
        color = Colors.purple;
        icon = Icons.sync_alt;
        text = 'Syncing';
        break;
      case ServerStatus.error:
        color = Colors.red;
        icon = Icons.warning;
        text = 'Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color ?? Colors.grey[700],
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

    if (context.mounted) {
      if (result != null && result.isSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection to ${server.name} successful'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection to ${server.name} failed: ${result?.errorMessage ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _refreshServers(BuildContext context) {
    context.read<ServerManagementViewModel>().refreshServers();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refreshing servers...')));
  }

  void _syncAllServers(BuildContext context) {
    final viewModel = context.read<ServerManagementViewModel>();

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
