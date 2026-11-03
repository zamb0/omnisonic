import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Widest a form or confirmation dialog gets. Dialogs used fixed 400×350–500
/// boxes, which left holes on desktop and crushed the scroll area when the
/// keyboard opened.
const double kDialogMaxWidth = 440;

/// Asks the user to confirm an action. Resolves to true only on confirm.
///
/// [destructive] colours the confirm button with the error colour. For a
/// reversible action, prefer doing it straight away and offering Undo in a
/// snackbar instead of asking first.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kDialogMaxWidth),
          child: Text(message),
        ),
        scrollable: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            autofocus: !destructive,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Asks for one line of text — a name for a duplicated playlist, say.
///
/// Resolves to the trimmed text, or null if cancelled. Enter submits, and an
/// empty value is refused with a message instead of silently doing nothing.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String initialValue = '',
  String? Function(String value)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      validator: validator,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.initialValue,
    this.validator,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;
  final String? Function(String value)? validator;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialValue.length,
        );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: kDialogMaxWidth,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: widget.label),
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Enter a name';
              return widget.validator?.call(text);
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// A read-only sheet of facts about one thing — a track, a server — as
/// label/value rows, with Close and optional extra [actions] before it.
///
/// Track info and server details each laid this out by hand with different
/// label widths, label styles and row spacing.
Future<void> showDetailsDialog(
  BuildContext context, {
  required String title,
  required List<(String, String)> rows,
  List<Widget> Function(BuildContext dialogContext)? actions,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        scrollable: true,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kDialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          label.toUpperCase(),
                          style: OmnisonicTypography.eyebrow.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          value,
                          style: OmnisonicTypography.bodyMedium.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          ...?actions?.call(dialogContext),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
