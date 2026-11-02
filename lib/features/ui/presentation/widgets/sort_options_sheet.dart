import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../models/sort_option.dart';

/// Picks a sort field and direction.
///
/// Was two options with no direction; now any of [fields], ascending or
/// descending. Choosing a field switches to its natural direction (A→Z,
/// newest first); the direction can then be flipped.
class SortOptionsSheet extends StatefulWidget {
  final SortOption currentOption;
  final List<SortField> fields;
  final ValueChanged<SortOption> onOptionSelected;

  const SortOptionsSheet({
    super.key,
    required this.currentOption,
    required this.onOptionSelected,
    this.fields = SortField.values,
  });

  @override
  State<SortOptionsSheet> createState() => _SortOptionsSheetState();
}

class _SortOptionsSheetState extends State<SortOptionsSheet> {
  late SortOption _option = widget.currentOption;

  void _set(SortOption option) {
    setState(() => _option = option);
    widget.onOptionSelected(option);
  }

  String _directionLabel(bool descending) => switch (_option.field) {
    SortField.title || SortField.artist => descending ? 'Z → A' : 'A → Z',
    SortField.year => descending ? 'Newest first' : 'Oldest first',
    SortField.dateAdded => descending ? 'Newest first' : 'Oldest first',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OmnisonicSpacing.md,
          0,
          OmnisonicSpacing.md,
          OmnisonicSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Sort by',
                style: OmnisonicTypography.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            for (final field in widget.fields)
              ListTile(
                leading: Icon(field.icon),
                title: Text(field.label),
                selected: _option.field == field,
                trailing: _option.field == field
                    ? Icon(OmnisonicIcons.check, color: scheme.primary)
                    : null,
                onTap: () => _set(SortOption.natural(field)),
              ),
            const SizedBox(height: OmnisonicSpacing.sm),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(OmnisonicIcons.arrowUpward),
                  label: Text(_directionLabel(false)),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(OmnisonicIcons.arrowDownward),
                  label: Text(_directionLabel(true)),
                ),
              ],
              selected: {_option.descending},
              onSelectionChanged: (value) =>
                  _set(_option.withDescending(value.single)),
            ),
          ],
        ),
      ),
    );
  }
}
