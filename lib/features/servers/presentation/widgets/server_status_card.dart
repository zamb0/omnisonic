import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// One count on the Status tab — "Online 3" — as a glass stat tile.
class ServerStatusCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const ServerStatusCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title: $count',
      excludeSemantics: true,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: OmnisonicIconSizes.smd),
                const Spacer(),
                Text(
                  '$count',
                  style: OmnisonicTypography.statValue.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            Text(
              title,
              style: OmnisonicTypography.labelMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
