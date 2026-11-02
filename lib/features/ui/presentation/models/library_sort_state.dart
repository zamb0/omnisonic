import 'library_tab.dart';
import 'sort_option.dart';

/// Manages sort state for each library tab
class LibrarySortState {
  final Map<LibraryTab, SortOption> _sortOptions;

  LibrarySortState()
    : _sortOptions = {
        for (var tab in LibraryTab.values) tab: SortOption.alphabetical,
      };

  /// Get the sort option for a specific tab
  SortOption getOption(LibraryTab tab) => _sortOptions[tab]!;

  /// Set the sort option for a specific tab
  void setOption(LibraryTab tab, SortOption option) {
    _sortOptions[tab] = option;
  }
}
