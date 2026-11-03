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
    final gutter = PageGutter.of(context);
    // Tabs start at the gutter, under the title, and the selection is the
    // ink underline: a tab is navigation, not live state.
    return TabBar(
      controller: controller,
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment: isScrollable ? TabAlignment.start : null,
      padding: isScrollable
          ? EdgeInsets.symmetric(horizontal: gutter - OmnisonicSpacing.md)
          : EdgeInsets.symmetric(horizontal: gutter),
      labelPadding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: scheme.onSurface, width: 2),
        borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: OmnisonicSurfaces.of(context).hairline,
      tabs: tabs,
    );
  }

  /// The same header as a pinned [SliverAppBar], for pages built from a
  /// [CustomScrollView]. Search used a stock SliverAppBar with Material's
  /// small title, the only top-level page that did.
  static Widget sliver(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    bool pinned = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final gutter = PageGutter.of(context);
    return SliverAppBar(
      pinned: pinned,
      toolbarHeight: toolbarHeight,
      titleSpacing: gutter,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: _title(context, title),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      actionsPadding: EdgeInsets.only(
        right: (gutter - OmnisonicSpacing.ms).clamp(0, gutter),
      ),
      actions: actions,
    );
  }

  static Widget _title(BuildContext context, String title) {
    final compact =
        MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobile;
    final style = compact
        ? OmnisonicTypography.sectionTitle
        : OmnisonicTypography.pageTitle;
    return Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final gutter = PageGutter.of(context);
    return AppBar(
      toolbarHeight: toolbarHeight,
      // The title starts on the page's gutter, so it lines up with the
      // content under it at every width.
      titleSpacing: leading == null && !_canPop(context) ? gutter : 0,
      centerTitle: false,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: _title(context, title),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      // Icon buttons carry their own 10px of padding around a 20px glyph;
      // trimming that from the gutter puts the last glyph on the content
      // edge.
      actionsPadding: EdgeInsets.only(
        right: (gutter - OmnisonicSpacing.ms).clamp(0, gutter),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  bool _canPop(BuildContext context) =>
      automaticallyImplyLeading &&
      (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
}
