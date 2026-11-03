import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';

/// How a [ServerStatus] looks: one colour, icon and label for the whole app.
///
/// This switch was written out three times — server tile, Status tab,
/// palette helper — with colours that disagreed. The colour is the
/// accessible variant in light mode, where the vivid status hues are under
/// 3:1 as text.
class ServerStatusVisuals {
  const ServerStatusVisuals._(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;

  static ServerStatusVisuals of(BuildContext context, ServerStatus status) {
    final light = Theme.of(context).brightness == Brightness.light;
    Color pick(Color vivid, Color accessible) => light ? accessible : vivid;
    return switch (status) {
      ServerStatus.online => ServerStatusVisuals._(
        pick(OmnisonicColors.success, OmnisonicColors.successAccessible),
        OmnisonicIcons.checkCircle,
        'Online',
      ),
      ServerStatus.offline => ServerStatusVisuals._(
        pick(OmnisonicColors.error, OmnisonicColors.errorAccessible),
        OmnisonicIcons.cloudOff,
        'Offline',
      ),
      ServerStatus.connecting => ServerStatusVisuals._(
        pick(OmnisonicColors.warning, OmnisonicColors.warningAccessible),
        OmnisonicIcons.sync,
        'Connecting',
      ),
      ServerStatus.authenticating => ServerStatusVisuals._(
        pick(OmnisonicColors.info, OmnisonicColors.infoAccessible),
        OmnisonicIcons.lock,
        'Signing in',
      ),
      ServerStatus.syncing => ServerStatusVisuals._(
        Theme.of(context).colorScheme.primary,
        OmnisonicIcons.syncAlt,
        'Syncing',
      ),
      ServerStatus.error => ServerStatusVisuals._(
        pick(OmnisonicColors.error, OmnisonicColors.errorAccessible),
        OmnisonicIcons.warning,
        'Error',
      ),
    };
  }
}

/// A server's status as a small tinted chip: icon and label, never colour
/// alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ServerStatus status;

  @override
  Widget build(BuildContext context) {
    final visuals = ServerStatusVisuals.of(context, status);
    return TintedChip(
      color: visuals.color,
      icon: visuals.icon,
      label: visuals.label,
      semanticLabel: 'Status: ${visuals.label}',
    );
  }
}

/// A neutral, outlined fact about an item — "12 tracks", "2019", "FLAC".
class MetadataChip extends StatelessWidget {
  const MetadataChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = OmnisonicSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.ms,
        vertical: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: surfaces.well,
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        border: Border.all(color: surfaces.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            // Follows the label: a fixed 16 sat beside 3x text.
            size: OmnisonicTextScale.textExtent(
              context,
              OmnisonicIconSizes.sm,
              max: OmnisonicIconSizes.sm * 2,
            ),
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmnisonicTypography.labelMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small status pill in a semantic colour: tinted fill, tinted edge,
/// icon and label in the colour itself. Status, count and offline badges all
/// use it, so "online" looks the same wherever it is said.
class TintedChip extends StatelessWidget {
  const TintedChip({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    this.semanticLabel,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OmnisonicSpacing.sm,
          vertical: OmnisonicSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(OmnisonicRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: OmnisonicIconSizes.xs, color: color),
            const SizedBox(width: OmnisonicSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmnisonicTypography.labelMedium.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What an [InlineBanner] reports.
enum BannerKind { info, success, warning, error }

/// A message that stays in the layout — a connection test result, a stale
/// cache notice — as opposed to a transient snackbar.
///
/// Replaces the result banners hand-built in each server dialog and the
/// offline banner.
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.kind = BannerKind.info,
    this.title,
    this.action,
    this.icon,
  });

  final String message;
  final String? title;
  final BannerKind kind;

  /// A trailing button, e.g. Retry.
  final Widget? action;

  /// Overrides the kind's icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final (Color accent, IconData kindIcon) = switch (kind) {
      BannerKind.info => (scheme.primary, OmnisonicIcons.info),
      BannerKind.success => (
        light ? OmnisonicColors.successAccessible : OmnisonicColors.success,
        OmnisonicIcons.checkCircle,
      ),
      BannerKind.warning => (
        light ? OmnisonicColors.warningAccessible : OmnisonicColors.warning,
        OmnisonicIcons.warning,
      ),
      BannerKind.error => (scheme.error, OmnisonicIcons.error),
    };

    return Semantics(
      liveRegion: kind == BannerKind.error || kind == BannerKind.success,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(OmnisonicRadius.tile),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? kindIcon, color: accent, size: OmnisonicIconSizes.smd),
            const SizedBox(width: OmnisonicSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: OmnisonicTypography.titleSmall.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  Text(
                    message,
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: OmnisonicSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
