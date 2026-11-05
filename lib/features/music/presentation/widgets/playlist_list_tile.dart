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
      padding: EdgeInsets.symmetric(
        horizontal: PageGutter.of(context),
        vertical: OmnisonicSpacing.xs,
      ),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: _buildPlaylistArt(scheme),
          title: Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${playlist.trackCount} track${playlist.trackCount != 1 ? 's' : ''}',
                style: OmnisonicTypography.technicalSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (playlist.description?.isNotEmpty == true) ...[
                const SizedBox(height: OmnisonicSpacing.xxs),
                Text(
                  playlist.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: OmnisonicSpacing.xs),
              Wrap(
                spacing: OmnisonicSpacing.xs,
                runSpacing: OmnisonicSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    playlist.isPublic
                        ? OmnisonicIcons.public
                        : OmnisonicIcons.lock,
                    size: OmnisonicIconSizes.xs,
                    color: scheme.onSurfaceVariant,
                  ),
                  Text(
                    playlist.isPublic ? 'Public' : 'Private',
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '· ${formatRelativeTime(playlist.updatedAt)}',
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // A MenuAnchor, like every other row's actions menu.
          trailing: MenuAnchor(
            builder: (context, controller, child) => IconButton(
              icon: const Icon(OmnisonicIcons.moreVert),
              tooltip: 'Actions for ${playlist.name}',
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(OmnisonicIcons.edit),
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(OmnisonicIcons.copy),
                onPressed: onDuplicate,
                child: const Text('Duplicate'),
              ),
              const Divider(height: 1),
              MenuItemButton(
                leadingIcon: Icon(OmnisonicIcons.delete, color: scheme.error),
                onPressed: onDelete,
                child: Text('Delete', style: TextStyle(color: scheme.error)),
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
    url: playlist.coverArtUrl, seed: playlist.id,
    size: 56,
    fallbackIcon: OmnisonicIcons.playlistPlay,
  );
}
