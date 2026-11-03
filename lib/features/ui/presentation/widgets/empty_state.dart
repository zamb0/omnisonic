import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
        child: _MaxWidth(
          // A sentence of copy, not a banner: wide empty states read as
          // errors stretched across the window.
          maxWidth: 380,
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

/// A max-width box that intrinsic sizing honours too. [ConstrainedBox] passes
/// the full width to its child's intrinsics, so inside
/// `SliverFillRemaining(hasScrollBody: false)` the copy was measured on one
/// line, laid out on two, and the empty state overflowed short windows.
class _MaxWidth extends SingleChildRenderObjectWidget {
  const _MaxWidth({required this.maxWidth, super.child});

  final double maxWidth;

  @override
  _RenderMaxWidth createRenderObject(BuildContext context) =>
      _RenderMaxWidth(maxWidth);

  @override
  void updateRenderObject(BuildContext context, _RenderMaxWidth renderObject) {
    renderObject.maxWidth = maxWidth;
  }
}

class _RenderMaxWidth extends RenderConstrainedBox {
  _RenderMaxWidth(double maxWidth)
    : super(additionalConstraints: BoxConstraints(maxWidth: maxWidth));

  double get maxWidth => additionalConstraints.maxWidth;
  set maxWidth(double value) =>
      additionalConstraints = BoxConstraints(maxWidth: value);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(math.min(width, maxWidth));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(math.min(width, maxWidth));
}
