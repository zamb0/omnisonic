import 'package:flutter/material.dart';

import '../../../../core/entities/entities.dart';

/// A list tile widget for displaying server information
class ServerListTile extends StatelessWidget {
  final MusicServer server;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTest;
  final VoidCallback? onDelete;

  const ServerListTile({
    super.key,
    required this.server,
    this.isLoading = false,
    this.onTap,
    this.onEdit,
    this.onTest,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _buildLeading(),
        title: Text(
          server.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.url, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(server.status),
                const SizedBox(width: 8),
                Text(
                  'User: ${server.username}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (server.lastSync != null) ...[
              const SizedBox(height: 2),
              Text(
                'Last sync: ${_formatDateTime(server.lastSync!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'test',
                    child: ListTile(
                      leading: Icon(Icons.wifi_protected_setup),
                      title: Text('Test Connection'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildLeading() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _getStatusColor(server.status).withOpacity(0.1),
      ),
      child: Icon(Icons.dns, color: _getStatusColor(server.status), size: 24),
    );
  }

  Widget _buildStatusChip(ServerStatus status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
      case ServerStatus.connecting:
        return Colors.orange;
      case ServerStatus.authenticating:
        return Colors.blue;
      case ServerStatus.syncing:
        return Colors.purple;
      case ServerStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ServerStatus status) {
    switch (status) {
      case ServerStatus.online:
        return Icons.check_circle;
      case ServerStatus.offline:
        return Icons.error;
      case ServerStatus.connecting:
        return Icons.sync;
      case ServerStatus.authenticating:
        return Icons.lock;
      case ServerStatus.syncing:
        return Icons.sync_alt;
      case ServerStatus.error:
        return Icons.warning;
    }
  }

  String _getStatusText(ServerStatus status) {
    switch (status) {
      case ServerStatus.online:
        return 'Online';
      case ServerStatus.offline:
        return 'Offline';
      case ServerStatus.connecting:
        return 'Connecting';
      case ServerStatus.authenticating:
        return 'Authenticating';
      case ServerStatus.syncing:
        return 'Syncing';
      case ServerStatus.error:
        return 'Error';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'test':
        onTest?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
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
