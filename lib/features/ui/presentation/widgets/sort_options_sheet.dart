import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../models/sort_option.dart';

/// Bottom sheet widget for selecting sort options
class SortOptionsSheet extends StatelessWidget {
  final SortOption currentOption;
  final ValueChanged<SortOption> onOptionSelected;

  const SortOptionsSheet({
    super.key,
    required this.currentOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sort Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...SortOption.values.map(
            (option) => _buildSortOption(context, option),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, SortOption option) {
    final isSelected = currentOption == option;
    final subtitle = option.subtitle;

    return ListTile(
      leading: Icon(_getIconForOption(option)),
      title: Text(option.label),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: isSelected
          ? Icon(
              OmnisonicIcons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        onOptionSelected(option);
      },
    );
  }

  IconData _getIconForOption(SortOption option) {
    switch (option) {
      case SortOption.alphabetical:
        return OmnisonicIcons.sortByAlpha;
      case SortOption.recentlyAdded:
        return OmnisonicIcons.accessTime;
    }
  }
}
