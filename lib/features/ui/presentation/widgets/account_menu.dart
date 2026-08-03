import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/destinations.dart';
import '../../../../core/utils/animation_utils.dart';

/// The way into every destination that doesn't get a permanent slot —
/// Starred, Downloads, Servers, Settings.
///
/// Rendered by both shells so the set is reachable at every window width.
/// Before this, the bottom bar reached them through a "More" button on the
/// Home page only, and the sidebar reached Settings through a top bar that
/// is hidden below 1024px, which left a band of widths with no route to
/// Settings at all.
class AccountButton extends StatelessWidget {
  const AccountButton({
    super.key,
    this.axis = Axis.horizontal,
    this.showLabel = false,
  });

  /// [Axis.vertical] stacks the label under the avatar so the button lines up
  /// with the bottom bar's nav pills; [Axis.horizontal] sits it alongside,
  /// for the sidebar footer.
  final Axis axis;

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = GoRouterState.of(context).uri.path;
    final active = AppDestinations.isSecondary(path);
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    final vertical = axis == Axis.vertical;

    final avatar = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(
        OmnisonicIcons.personOutline,
        size: OmnisonicIconSizes.sm,
        color: color,
      ),
    );

    final label = Text(
      'Account',
      style: vertical
          ? OmnisonicTypography.labelSmall.copyWith(
              color: color,
              fontWeight: active
                  ? OmnisonicTypography.semiBold
                  : OmnisonicTypography.medium,
            )
          : OmnisonicTypography.navLabel.copyWith(color: color),
    );

    return Semantics(
      button: true,
      selected: active,
      label: 'Account and settings',
      child: InkWell(
        onTap: () => showAccountMenu(context),
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.sm,
            vertical: OmnisonicSpacing.xs,
          ),
          child: Flex(
            direction: axis,
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              if (showLabel) ...[
                SizedBox(
                  width: vertical ? 0 : OmnisonicSpacing.sm,
                  height: vertical ? 2 : 0,
                ),
                label,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the sheet listing [AppDestinations.secondary].
void showAccountMenu(BuildContext context) {
  final currentPath = GoRouterState.of(context).uri.path;

  AnimationUtils.showCustomBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(OmnisonicRadius.xl),
          padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final destination in AppDestinations.secondary)
                _AccountMenuItem(
                  destination: destination,
                  selected: destination.matches(currentPath),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({required this.destination, required this.selected});

  final AppDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface;

    return ListTile(
      leading: Icon(
        selected ? destination.activeIcon : destination.icon,
        color: color,
      ),
      title: Text(destination.label, style: TextStyle(color: color)),
      selected: selected,
      onTap: () {
        // Pop the sheet before navigating: pushing first leaves the sheet
        // stacked over the destination.
        Navigator.of(context).pop();
        GoRouter.of(context).go(destination.route);
      },
    );
  }
}
