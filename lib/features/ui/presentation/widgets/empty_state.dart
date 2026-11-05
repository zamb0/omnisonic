import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/design_system/design_system.dart';

/// A widget for displaying empty states with consistent styling.
///
/// v2 (docs/design-system.md §9.8): a soft Aurora mesh behind, the icon in an
/// 80 px `well` disc ringed in `auroraSoft`, a `groupTitle`, the copy, and —
/// when there is exactly one thing to do — an Aurora button as [action].
/// [accent] recolours the icon (the error state) and [hero] is the first-run
/// version, with the wordmark and the mesh at full strength.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  /// Icon colour; the muted text colour by default.
  final Color? accent;

  /// The first-run welcome: the Omnisonic wordmark above, a livelier mesh.
  final bool hero;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.accent,
    this.hero = false,
  });

  /// The disc around the icon.
  static const double discSize = 80;

  /// How far the ring floats outside the disc.
  static const double ringGap = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = OmnisonicSurfaces.of(context);

    final content = _MaxWidth(
      // A sentence of copy, not a banner: wide empty states read as
      // errors stretched across the window.
      maxWidth: 380,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hero) ...[
            Text(
              'Omnisonic',
              // The brand mark, at hero scale: the section title's size in the
              // wordmark's own face.
              style: OmnisonicTypography.sectionTitle.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.lg),
          ],
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: discSize + ringGap * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(child: AuroraRing()),
                  Container(
                    width: discSize,
                    height: discSize,
                    decoration: BoxDecoration(
                      color: surfaces.well,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaces.hairline),
                    ),
                    child: Icon(
                      icon,
                      size: OmnisonicIconSizes.xl,
                      color: accent ?? scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: OmnisonicSpacing.ml),
          Text(
            title,
            style: OmnisonicTypography.groupTitle.copyWith(
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
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.xl),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // A halo of Aurora behind the copy, reaching past it.
            Positioned(
              left: -meshReach,
              right: -meshReach,
              top: -meshReach,
              bottom: -meshReach,
              child: AuroraMesh(
                opacity: hero ? heroMeshOpacity : meshOpacity,
                drift: hero,
                vignette: true,
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  /// Strength of the mesh behind an empty state, and behind the first-run
  /// hero.
  static const double meshOpacity = 0.5;
  static const double heroMeshOpacity = 1;

  /// How far the mesh extends past the copy.
  static const double meshReach = 96;
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
