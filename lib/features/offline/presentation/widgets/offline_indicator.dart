import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/offline_mode_service.dart';
import '../../../ui/presentation/widgets/chips.dart';
import '../viewmodels/offline_mode_view_model.dart';

/// Online/offline status as a small pill.
///
/// The fills are the vivid warning/success hues, so the text and icon on
/// them are the dark on-colours: white on these was 2.1:1 and 2.5:1.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({
    super.key,
    this.showWhenOnline = false,
    this.compact = false,
  });

  final bool showWhenOnline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        final offline = viewModel.isOffline;
        if (!offline && !showWhenOnline) return const SizedBox.shrink();

        final fill = offline
            ? OmnisonicColors.warning
            : OmnisonicColors.success;
        final on = offline
            ? OmnisonicColors.onWarning
            : OmnisonicColors.onSuccess;
        final label = offline ? 'Offline' : 'Online';

        return Semantics(
          label: label,
          excludeSemantics: true,
          child: Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(OmnisonicRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    offline
                        ? OmnisonicIcons.cloudOff
                        : OmnisonicIcons.cloudDone,
                    size: compact
                        ? OmnisonicIconSizes.inline
                        : OmnisonicIconSizes.sm,
                    color: on,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: OmnisonicTypography.labelMedium.copyWith(
                        color: on,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Network quality as an outlined chip.
class NetworkQualityIndicator extends StatelessWidget {
  const NetworkQualityIndicator({super.key, this.showLabel = true});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isOffline) return const SizedBox.shrink();

        final quality = viewModel.networkQuality;
        final color = _qualityColor(context, quality);

        return Tooltip(
          message: 'Network: ${quality.description}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(OmnisonicRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _qualityIcon(quality),
                  size: OmnisonicIconSizes.inline,
                  color: color,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  Text(
                    quality.description,
                    style: OmnisonicTypography.labelMedium.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Accessible variants in light mode, where the vivid hues fail as text.
  Color _qualityColor(BuildContext context, NetworkQuality quality) {
    final light = Theme.of(context).brightness == Brightness.light;
    Color pick(Color vivid, Color accessible) => light ? accessible : vivid;
    return switch (quality) {
      NetworkQuality.none => Theme.of(context).colorScheme.onSurfaceVariant,
      NetworkQuality.poor => pick(
        OmnisonicColors.error,
        OmnisonicColors.errorAccessible,
      ),
      NetworkQuality.fair => pick(
        OmnisonicColors.warning,
        OmnisonicColors.warningAccessible,
      ),
      NetworkQuality.good => pick(
        OmnisonicColors.info,
        OmnisonicColors.infoAccessible,
      ),
      NetworkQuality.excellent => pick(
        OmnisonicColors.success,
        OmnisonicColors.successAccessible,
      ),
    };
  }

  IconData _qualityIcon(NetworkQuality quality) => switch (quality) {
    NetworkQuality.none => OmnisonicIcons.signalCellularOff,
    NetworkQuality.poor => OmnisonicIcons.networkCell,
    NetworkQuality.fair => OmnisonicIcons.networkWifi1Bar,
    NetworkQuality.good => OmnisonicIcons.networkWifi2Bar,
    NetworkQuality.excellent => OmnisonicIcons.wifi,
  };
}

/// "Available offline" badge for a card.
class OfflineContentBadge extends StatelessWidget {
  const OfflineContentBadge({
    super.key,
    required this.isAvailable,
    this.size = 16,
  });

  final bool isAvailable;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) return const SizedBox.shrink();

    return Semantics(
      label: 'Available offline',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: OmnisonicColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(
          OmnisonicIcons.offlinePin,
          size: size * 0.7,
          color: OmnisonicColors.onSuccess,
        ),
      ),
    );
  }
}

/// Connection type as an icon with a tooltip.
class ConnectionTypeIndicator extends StatelessWidget {
  const ConnectionTypeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isOffline) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final (IconData icon, String label) = viewModel.isWiFiConnection
            ? (OmnisonicIcons.wifi, 'Wi-Fi')
            : viewModel.isMeteredConnection
            ? (OmnisonicIcons.signalCellular4Bar, 'Mobile data')
            : (OmnisonicIcons.lan, 'Ethernet');

        return Tooltip(
          message: label,
          child: Icon(
            icon,
            size: OmnisonicIconSizes.sm,
            color: scheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

/// Banner shown while offline.
class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isOffline) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.md,
            vertical: OmnisonicSpacing.sm,
          ),
          child: InlineBanner(
            kind: BannerKind.warning,
            icon: OmnisonicIcons.cloudOff,
            title: "You're offline",
            message:
                'Showing the ${viewModel.offlineTrackCount} tracks saved on '
                'this device.',
            action: TextButton(
              onPressed: viewModel.checkConnectivity,
              child: const Text('Retry'),
            ),
          ),
        );
      },
    );
  }
}
