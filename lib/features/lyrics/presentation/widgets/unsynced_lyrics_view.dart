import 'package:flutter/material.dart';

import '../../../../core/design_system/spacing.dart';

class UnsyncedLyricsView extends StatelessWidget {
  const UnsyncedLyricsView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }
}
