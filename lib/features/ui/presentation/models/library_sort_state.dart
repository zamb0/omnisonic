import 'library_tab.dart';
import 'sort_option.dart';

/// Sort option per library tab.
class LibrarySortState {
  final Map<LibraryTab, SortOption> _sortOptions = {
    for (final tab in LibraryTab.values) tab: SortOption.alphabetical,
  };

  /// Get the sort option for a specific tab
  SortOption getOption(LibraryTab tab) => _sortOptions[tab]!;

  /// Set the sort option for a specific tab
  void setOption(LibraryTab tab, SortOption option) {
    _sortOptions[tab] = option;
  }
}
