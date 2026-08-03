import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'app_router.dart';

/// Where a destination lives in the navigation hierarchy.
enum DestinationScope {
  /// Always visible: the bottom bar's slots, the sidebar's nav column.
  primary,

  /// Behind the account affordance in both shells.
  secondary,
}

/// One place the user can navigate to from the shell's chrome.
class AppDestination {
  const AppDestination({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.scope,
    this.alsoSelectedBy = const [],
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final DestinationScope scope;

  /// Routes that are "inside" this destination and should keep it lit —
  /// album detail belongs to Library, for instance.
  final List<String> alsoSelectedBy;

  bool matches(String path) => path == route || alsoSelectedBy.contains(path);
}

/// The single source of truth for the shell's navigation.
///
/// The bottom bar and the sidebar used to declare their own lists, and they
/// disagreed: the sidebar had no Downloads and no Settings, the bottom bar
/// had no Starred, and between 768 and 1023px — where the sidebar is a rail
/// and the top bar is hidden — there was no way to reach Settings at all.
/// Both shells now render from here, so a destination cannot exist in one
/// and not the other.
class AppDestinations {
  const AppDestinations._();

  /// The four slots. Search sits second because it is the most-used
  /// destination after Home and that is the easiest reach on a phone.
  static const List<AppDestination> primary = [
    AppDestination(
      route: AppRouter.home,
      icon: OmnisonicIcons.homeOutline,
      activeIcon: OmnisonicIcons.home,
      label: 'Home',
      scope: DestinationScope.primary,
    ),
    AppDestination(
      route: AppRouter.search,
      icon: OmnisonicIcons.searchOutline,
      activeIcon: OmnisonicIcons.search,
      label: 'Search',
      scope: DestinationScope.primary,
    ),
    AppDestination(
      route: AppRouter.library,
      icon: OmnisonicIcons.libraryMusicOutline,
      activeIcon: OmnisonicIcons.libraryMusic,
      label: 'Library',
      scope: DestinationScope.primary,
      alsoSelectedBy: [AppRouter.albumDetail, AppRouter.artistDetail],
    ),
    AppDestination(
      route: AppRouter.playlistManagement,
      icon: OmnisonicIcons.queueMusicOutline,
      activeIcon: OmnisonicIcons.queueMusic,
      label: 'Playlists',
      scope: DestinationScope.primary,
      alsoSelectedBy: [AppRouter.playlistDetail],
    ),
  ];

  /// Reached through the account affordance rather than a permanent slot.
  static const List<AppDestination> secondary = [
    AppDestination(
      route: AppRouter.favorites,
      icon: OmnisonicIcons.starOutline,
      activeIcon: OmnisonicIcons.star,
      label: 'Starred',
      scope: DestinationScope.secondary,
    ),
    AppDestination(
      route: AppRouter.downloads,
      icon: OmnisonicIcons.downloadOutline,
      activeIcon: OmnisonicIcons.download,
      label: 'Downloads',
      scope: DestinationScope.secondary,
    ),
    AppDestination(
      route: AppRouter.servers,
      icon: OmnisonicIcons.dnsOutline,
      activeIcon: OmnisonicIcons.dns,
      label: 'Servers',
      scope: DestinationScope.secondary,
    ),
    AppDestination(
      route: AppRouter.settings,
      icon: OmnisonicIcons.settingsOutline,
      activeIcon: OmnisonicIcons.settings,
      label: 'Settings',
      scope: DestinationScope.secondary,
    ),
  ];

  static List<AppDestination> get all => [...primary, ...secondary];

  /// Index into [primary] for [path], or `null` when the current route is
  /// not one of the four.
  ///
  /// Returning null rather than falling back to Home matters: /queue and
  /// /now-playing used to light the Home tab, which told the user they were
  /// somewhere they weren't.
  static int? selectedPrimaryIndex(String path) {
    for (var i = 0; i < primary.length; i++) {
      if (primary[i].matches(path)) return i;
    }
    return null;
  }

  /// Whether [path] is one of the destinations behind the account
  /// affordance, so the shell can highlight that instead.
  static bool isSecondary(String path) =>
      secondary.any((destination) => destination.matches(path));
}
