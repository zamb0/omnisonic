import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// The header every top-level screen uses: an oversized Gabarito title on a
/// transparent bar, so the art tint runs behind it instead of stopping at an
/// opaque band.
///
/// Library and Starred had this; Servers, Playlists, Downloads and Settings
/// had centred, opaque Material app bars with titles that did not match
/// their nav labels ("Server Management" under a "Servers" tab).
///
/// The title steps down from [OmnisonicTypography.pageTitle] to
/// [OmnisonicTypography.sectionTitle] on compact widths, where 40px titles
/// left no room for actions.
class PageHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageHeaderAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  static const double toolbarHeight = 72;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  /// A tab bar styled for this header.
  static TabBar tabBar(
    BuildContext context, {
    required List<Widget> tabs,
    TabController? controller,
    ValueChanged<int>? onTap,
    bool isScrollable = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TabBar(
      controller: controller,
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment: isScrollable ? TabAlignment.start : null,
      labelStyle: OmnisonicTypography.navLabel,
      unselectedLabelStyle: OmnisonicTypography.navLabel,
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact =
        MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobile;
    final style = compact
        ? OmnisonicTypography.sectionTitle
        : OmnisonicTypography.pageTitle;

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: leading == null && !_canPop(context)
          ? OmnisonicSpacing.md
          : 0,
      centerTitle: false,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Semantics(
        header: true,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: scheme.onSurface),
        ),
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      actions: actions == null
          ? null
          : [...actions!, const SizedBox(width: OmnisonicSpacing.xs)],
      bottom: bottom,
    );
  }

  bool _canPop(BuildContext context) =>
      automaticallyImplyLeading &&
      (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
}
