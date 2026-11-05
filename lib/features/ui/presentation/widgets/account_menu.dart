import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/destinations.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import 'chips.dart';
import 'server_health.dart';

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
    final surfaces = OmnisonicSurfaces.of(context);
    final path = GoRouterState.of(context).uri.path;
    final active = AppDestinations.isSecondary(path);
    final color = active ? scheme.onSurface : scheme.onSurfaceVariant;
    final vertical = axis == Axis.vertical;

    // The ring is the aggregate server state (success / warning / error).
    // Its colour is never alone: the semantics label says it too.
    final health = context.select<ServerManagementViewModel, ServerHealth>(
      (vm) => ServerHealth.of(vm.servers.map((server) => server.status)),
    );
    final healthStatus = health.status;
    final ringColor = healthStatus == null
        ? null
        : ServerStatusVisuals.of(context, healthStatus).color;

    // Active, the sidebar footer avatar takes the `wellHover` fill. In the
    // bottom bar the shared sliding indicator sits behind this slot, so the
    // avatar stays bare there.
    final disc = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: vertical ? null : (active ? surfaces.wellHover : surfaces.well),
        border: ringColor == null
            ? null
            : Border.all(color: ringColor, width: 2),
      ),
      child: Icon(
        active ? OmnisonicIcons.person : OmnisonicIcons.personOutline,
        size: OmnisonicIconSizes.sm,
        color: color,
      ),
    );
    final avatar = SizedBox(
      width: vertical ? 52 : 28,
      height: 28,
      child: Center(child: disc),
    );

    final label = Text(
      'Account',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: vertical
          ? OmnisonicTypography.labelSmall.copyWith(color: color)
          : OmnisonicTypography.navLabel.copyWith(color: color),
    );

    Widget button(VoidCallback onTap) => Semantics(
      button: true,
      selected: active,
      label: 'Account and settings, ${health.description}',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Account and settings',
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(OmnisonicRadius.full),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: OmnisonicTouchTargets.minimum,
              minHeight: OmnisonicTouchTargets.minimum,
            ),
            child: Padding(
              padding: vertical
                  ? const EdgeInsets.symmetric(vertical: OmnisonicSpacing.xs)
                  : const EdgeInsets.symmetric(
                      horizontal: OmnisonicSpacing.xs,
                      vertical: OmnisonicSpacing.xs,
                    ),
              child: Flex(
                direction: axis,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  avatar,
                  if (showLabel) ...[
                    SizedBox(
                      width: vertical ? 0 : OmnisonicSpacing.ms,
                      height: vertical ? OmnisonicSpacing.xxs : 0,
                    ),
                    Flexible(child: label),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The bottom bar opens a sheet, as phones expect. In the sidebar the
    // menu is anchored to the button: a sheet rising from the bottom of a
    // desktop window, far from what was clicked, read as a different app.
    if (vertical) return button(() => showAccountMenu(context));
    return MenuAnchor(
      reservedPadding: OmnisonicInsets.menuScreen,
      builder: (context, controller, child) => button(
        () => controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        for (final destination in AppDestinations.secondary)
          MenuItemButton(
            leadingIcon: Icon(
              destination.matches(path)
                  ? destination.activeIcon
                  : destination.icon,
            ),
            onPressed: () => GoRouter.of(context).go(destination.route),
            child: Text(destination.label),
          ),
      ],
    );
  }
}

/// Opens the sheet listing [AppDestinations.secondary].
void showAccountMenu(BuildContext context) {
  final currentPath = GoRouterState.of(context).uri.path;

  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    // The glass panel is the sheet: without this the theme's hairline drew a
    // second, empty outline around it.
    shape: const RoundedRectangleBorder(),
    showDragHandle: false,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OmnisonicLayout.chromeInset,
          OmnisonicSpacing.sm,
          OmnisonicLayout.chromeInset,
          OmnisonicLayout.chromeInset,
        ),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(OmnisonicRadius.overlay),
          padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The sheet's 36 × 4 handle (docs/design-system.md, "Bottom
              // sheet"), inside the
              // floating panel rather than on an invisible sheet above it.
              ExcludeSemantics(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: OmnisonicSpacing.xs),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.outline,
                    borderRadius: BorderRadius.circular(OmnisonicRadius.full),
                  ),
                ),
              ),
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
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return ListTile(
      leading: Icon(
        selected ? destination.activeIcon : destination.icon,
        color: color,
        size: OmnisonicIconSizes.smd,
      ),
      title: Text(destination.label),
      trailing: selected
          ? Icon(
              OmnisonicIcons.check,
              color: scheme.primary,
              size: OmnisonicIconSizes.smd,
            )
          : null,
      selected: selected,
      onTap: () {
        // Pop the sheet before navigating: pushing first leaves the sheet
        // stacked over the destination.
        //
        // Pushed, not replaced: these pages sit above the tabs, and with go()
        // Servers had a back arrow when opened from Home but none from here.
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        if (!selected) router.push(destination.route);
      },
    );
  }
}
