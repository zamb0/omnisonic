import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/offline_mode_service.dart';
import '../viewmodels/offline_mode_view_model.dart';

/// Widget that shows offline mode status
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
        if (!viewModel.isOffline && !showWhenOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: viewModel.isOffline ? Colors.orange : Colors.green,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                viewModel.isOffline ? Icons.cloud_off : Icons.cloud_done,
                size: compact ? 14 : 16,
                color: Colors.white,
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  viewModel.isOffline ? 'Offline' : 'Online',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget that shows network quality indicator
class NetworkQualityIndicator extends StatelessWidget {
  const NetworkQualityIndicator({super.key, this.showLabel = true});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isOffline) {
          return const SizedBox.shrink();
        }

        final quality = viewModel.networkQuality;
        final color = _getQualityColor(quality);
        final icon = _getQualityIcon(quality);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  quality.description,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.none:
        return Colors.grey;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.good:
        return Colors.blue;
      case NetworkQuality.excellent:
        return Colors.green;
    }
  }

  IconData _getQualityIcon(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.none:
        return Icons.signal_cellular_off;
      case NetworkQuality.poor:
        return Icons.network_cell;
      case NetworkQuality.fair:
        return Icons.network_wifi_1_bar;
      case NetworkQuality.good:
        return Icons.network_wifi_2_bar;
      case NetworkQuality.excellent:
        return Icons.wifi;
    }
  }
}

/// Widget that shows offline content availability
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
    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.offline_pin, size: size * 0.7, color: Colors.white),
    );
  }
}

/// Widget that shows connection type
class ConnectionTypeIndicator extends StatelessWidget {
  const ConnectionTypeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isOffline) {
          return const SizedBox.shrink();
        }

        IconData icon;
        String label;
        Color color;

        if (viewModel.isWiFiConnection) {
          icon = Icons.wifi;
          label = 'WiFi';
          color = Colors.blue;
        } else if (viewModel.isMeteredConnection) {
          icon = Icons.signal_cellular_4_bar;
          label = 'Mobile';
          color = Colors.orange;
        } else {
          icon = Icons.lan;
          label = 'Ethernet';
          color = Colors.green;
        }

        return Tooltip(
          message: label,
          child: Icon(icon, size: 16, color: color),
        );
      },
    );
  }
}

/// Banner that shows when in offline mode
class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineModeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isOffline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Showing ${viewModel.offlineTrackCount} cached tracks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => viewModel.checkConnectivity(),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
