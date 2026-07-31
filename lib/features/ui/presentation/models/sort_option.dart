/// Available sort options for library content
enum SortOption { alphabetical, recentlyAdded }

/// Extension to provide display information for sort options
extension SortOptionDisplay on SortOption {
  String get label {
    switch (this) {
      case SortOption.alphabetical:
        return 'Alphabetical';
      case SortOption.recentlyAdded:
        return 'Recently Synced';
    }
  }

  String? get subtitle {
    switch (this) {
      case SortOption.alphabetical:
        return null;
      case SortOption.recentlyAdded:
        return 'By last sync date';
    }
  }
}
