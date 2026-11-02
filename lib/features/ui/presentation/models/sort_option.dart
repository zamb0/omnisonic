import '../../../../core/design_system/icons.dart';
import 'package:flutter/widgets.dart';

/// What a library list is ordered by.
enum SortField {
  title('Name', OmnisonicIcons.sortByAlpha),
  artist('Artist', OmnisonicIcons.person),
  year('Year', OmnisonicIcons.calendarToday),

  /// The server's last-modified date — when the item was added or last
  /// changed there. It used to be labelled "Recently Synced", which it is
  /// not.
  dateAdded('Date added', OmnisonicIcons.accessTime);

  const SortField(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Whether newest/largest first is the natural default.
  bool get descendingByDefault => this == dateAdded || this == year;
}

/// A sort field and a direction.
@immutable
class SortOption {
  const SortOption(this.field, {bool? descending})
    : descending = descending ?? false;

  /// The field's natural direction: A→Z for names, newest first for dates.
  factory SortOption.natural(SortField field) =>
      SortOption(field, descending: field.descendingByDefault);

  static const SortOption alphabetical = SortOption(SortField.title);

  final SortField field;
  final bool descending;

  SortOption withDescending(bool value) => SortOption(field, descending: value);

  @override
  bool operator ==(Object other) =>
      other is SortOption &&
      other.field == field &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(field, descending);
}
