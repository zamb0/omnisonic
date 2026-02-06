import 'library_tab.dart';
import 'sort_option.dart';

/// Manages sort state for each library tab
class LibrarySortState {
  final Map<LibraryTab, SortOption> _sortOptions;

  LibrarySortState()
      : _sortOptions = {
          for (var tab in LibraryTab.values) tab: SortOption.alphabetical
        };

  /// Get the sort option for a specific tab
  SortOption getOption(LibraryTab tab) => _sortOptions[tab]!;

  /// Set the sort option for a specific tab
  void setOption(LibraryTab tab, SortOption option) {
    _sortOptions[tab] = option;
  }

  /// Get the current sort option based on tab index
  SortOption getOptionByIndex(int index) {
    final tab = LibraryTab.fromIndex(index);
    return getOption(tab);
  }

  /// Set the sort option based on tab index
  void setOptionByIndex(int index, SortOption option) {
    final tab = LibraryTab.fromIndex(index);
    setOption(tab, option);
  }
}
