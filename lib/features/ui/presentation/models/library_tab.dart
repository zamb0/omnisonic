import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// The sections of the library.
///
/// Playlists used to be a third tab here as well as a top-level destination
/// with its own page. Two lists of the same thing, one of which had a
/// "Manage" button leading to the other — so the tab is gone and
/// [AppRouter.playlistManagement] is the only place playlists live.
enum LibraryTab {
  albums('Albums', OmnisonicIcons.album),
  artists('Artists', OmnisonicIcons.person);

  const LibraryTab(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Get tab by index (uses built-in enum index property)
  static LibraryTab fromIndex(int index) {
    return LibraryTab.values.firstWhere(
      (tab) => tab.index == index,
      orElse: () => LibraryTab.albums,
    );
  }

  /// Get tab by name (matches enum name values)
  static LibraryTab? fromName(String? name) {
    if (name == null || name.isEmpty) {
      return null;
    }

    for (final tab in LibraryTab.values) {
      if (tab.name == name) {
        return tab;
      }
    }

    return null;
  }

  /// Get total number of tabs
  static int get count => LibraryTab.values.length;
}
