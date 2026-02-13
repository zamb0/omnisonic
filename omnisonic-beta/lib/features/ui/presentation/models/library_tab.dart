import 'package:flutter/material.dart';

/// Enum representing the different tabs in the library
enum LibraryTab {
  albums('Albums', Icons.album),
  artists('Artists', Icons.person),
  tracks('Tracks', Icons.music_note),
  playlists('Playlists', Icons.playlist_play);

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

  /// Get total number of tabs
  static int get count => LibraryTab.values.length;
}
