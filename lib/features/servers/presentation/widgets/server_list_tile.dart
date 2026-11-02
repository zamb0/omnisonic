import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/formatters.dart';
import '../../../ui/presentation/widgets/chips.dart';

/// A list tile widget for displaying server information
class ServerListTile extends StatelessWidget {
  final MusicServer server;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTest;
  final VoidCallback? onDelete;

  /// Albums synced from this server, or null if not computed yet.
  final int? albumCount;

  /// Round-trip time from the most recent connection test this session, or
  /// null if the server hasn't been tested since the app launched.
  final Duration? latency;

  const ServerListTile({
    super.key,
    required this.server,
    this.isLoading = false,
    this.onTap,
    this.onEdit,
    this.onTest,
    this.onDelete,
    this.albumCount,
    this.latency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildTile(context), _buildStatTrio(context)],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    return ListTile(
      leading: _buildLeading(context),
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
              StatusChip(status: server.status),
              const SizedBox(width: 8),
              Text(
                'User: ${server.username}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: OmnisonicColors.neutralGray600,
                ),
              ),
            ],
          ),
          if (server.lastSync != null) ...[
            const SizedBox(height: 2),
            Text(
              'Last sync: ${formatRelativeTime(server.lastSync!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: OmnisonicColors.neutralGray600,
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
                    leading: Icon(OmnisonicIcons.wifiProtectedSetup),
                    title: Text('Test Connection'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(OmnisonicIcons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      OmnisonicIcons.delete,
                      color: OmnisonicColors.error,
                    ),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: OmnisonicColors.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
      onTap: onTap,
      isThreeLine: true,
    );
  }

  /// Albums synced / last measured latency / last sync time. Latency is
  /// only ever the result of an explicit "Test Connection" — it's not
  /// continuously polled, so it reads "not tested" until the user runs one.
  Widget _buildStatTrio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _buildStat(
            context,
            OmnisonicIcons.albumOutline,
            albumCount != null ? '$albumCount albums' : '— albums',
          ),
          const SizedBox(width: 16),
          _buildStat(
            context,
            OmnisonicIcons.speedOutline,
            latency != null ? '${latency!.inMilliseconds}ms' : 'not tested',
          ),
          const SizedBox(width: 16),
          _buildStat(
            context,
            OmnisonicIcons.syncOutline,
            server.lastSync != null
                ? formatRelativeTime(server.lastSync!)
                : 'never synced',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: OmnisonicIconSizes.inline,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: OmnisonicTypography.metadata.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLeading(BuildContext context) {
    final color = ServerStatusVisuals.of(context, server.status).color;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(OmnisonicIcons.dns, color: color, size: 24),
    );
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
}
