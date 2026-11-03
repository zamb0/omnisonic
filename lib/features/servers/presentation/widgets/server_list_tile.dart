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
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _buildLeading(context),
      title: Text(
        server.name,
        style: OmnisonicTypography.titleSmall.copyWith(color: scheme.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            server.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OmnisonicTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: server.status),
              Text(
                server.username,
                style: OmnisonicTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : MenuAnchor(
              reservedPadding: OmnisonicInsets.menuScreen,
              builder: (context, controller, child) => IconButton(
                icon: const Icon(OmnisonicIcons.moreVert),
                tooltip: 'Actions for ${server.name}',
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(OmnisonicIcons.wifiProtectedSetup),
                  onPressed: onTest,
                  child: const Text('Test connection'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(OmnisonicIcons.edit),
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                MenuItemButton(
                  leadingIcon: Icon(OmnisonicIcons.delete, color: scheme.error),
                  onPressed: onDelete,
                  child: Text('Remove', style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
      onTap: onTap,
    );
  }

  /// Albums synced / last measured latency / last sync time. Latency is
  /// only ever the result of an explicit "Test Connection" — it's not
  /// continuously polled, so it reads "not tested" until the user runs one.
  Widget _buildStatTrio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _buildStat(
            context,
            OmnisonicIcons.albumOutline,
            albumCount != null ? pluralize(albumCount!, 'album') : '— albums',
          ),
          _buildStat(
            context,
            OmnisonicIcons.speedOutline,
            latency != null ? '${latency!.inMilliseconds}ms' : 'not tested',
          ),
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
}
