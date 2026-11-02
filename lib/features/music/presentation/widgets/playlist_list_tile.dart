import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/formatters.dart';
import '../../../ui/presentation/widgets/cover_art.dart';

/// A list tile widget for displaying playlist information in management views
class PlaylistListTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const PlaylistListTile({
    super.key,
    required this.playlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: _buildPlaylistArt(scheme),
          title: Text(
            playlist.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${playlist.trackCount} track${playlist.trackCount != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (playlist.description?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  playlist.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    playlist.isPublic
                        ? OmnisonicIcons.public
                        : OmnisonicIcons.lock,
                    size: OmnisonicIconSizes.xs,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    playlist.isPublic ? 'Public' : 'Private',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatRelativeTime(playlist.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(OmnisonicIcons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(OmnisonicIcons.copy),
                  title: Text('Duplicate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(OmnisonicIcons.delete, color: scheme.error),
                  title: Text('Delete', style: TextStyle(color: scheme.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          onTap: onTap,
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildPlaylistArt(ColorScheme scheme) => CoverArt(
    url: playlist.coverArtUrl,
    size: 56,
    fallbackIcon: OmnisonicIcons.playlistPlay,
  );

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'duplicate':
        onDuplicate?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
