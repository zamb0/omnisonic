import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// A widget for displaying empty states with consistent styling
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = OmnisonicSurfaces.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.xl),
        child: ConstrainedBox(
          // A sentence of copy, not a banner: wide empty states read as
          // errors stretched across the window.
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: surfaces.well,
                    shape: BoxShape.circle,
                    border: Border.all(color: surfaces.hairline),
                  ),
                  child: Icon(
                    icon,
                    size: OmnisonicIconSizes.lg,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: OmnisonicSpacing.ml),
              Text(
                title,
                style: OmnisonicTypography.overlayTitle.copyWith(
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: OmnisonicSpacing.sm),
                Text(
                  subtitle!,
                  style: OmnisonicTypography.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: OmnisonicSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
