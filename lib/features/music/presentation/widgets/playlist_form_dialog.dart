import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../ui/presentation/widgets/chips.dart';
import '../../../ui/presentation/widgets/dialogs.dart';
import '../../../ui/presentation/widgets/feedback.dart';
import '../viewmodels/playlist_view_model.dart';

/// Creates a playlist, or edits [playlist] when given.
///
/// Replaces `PlaylistCreationDialog` and `PlaylistEditDialog`, which were the
/// same form line for line. Enter submits from the name field; validation
/// runs as the user types; the dialog is sized by a max width and scrolls,
/// so the keyboard no longer crushes it.
Future<void> showPlaylistFormDialog(
  BuildContext context, {
  Playlist? playlist,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => PlaylistFormDialog(playlist: playlist),
  );
}

class PlaylistFormDialog extends StatefulWidget {
  const PlaylistFormDialog({super.key, this.playlist});

  /// The playlist to edit, or null to create one.
  final Playlist? playlist;

  @override
  State<PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<PlaylistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.playlist?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.playlist?.description ?? '',
  );
  late bool _isPublic = widget.playlist?.isPublic ?? false;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.playlist != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final name = _name.text.trim();
    final description = _description.text.trim().isEmpty
        ? null
        : _description.text.trim();
    final existing = widget.playlist;

    if (existing != null &&
        name == existing.name &&
        description == existing.description &&
        _isPublic == existing.isPublic) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final viewModel = context.read<PlaylistViewModel>();
    final ok = existing != null
        ? await viewModel.updatePlaylist(
            existing.copyWith(
              name: name,
              description: description,
              isPublic: _isPublic,
              updatedAt: DateTime.now(),
            ),
          )
        : await viewModel.createPlaylist(
            name: name,
            description: description,
            isPublic: _isPublic,
          );
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      showFeedback(
        context,
        existing != null ? 'Saved "$name"' : 'Created "$name"',
        kind: FeedbackKind.success,
      );
      return;
    }
    // Shown here, in the dialog, rather than in a snackbar hidden behind
    // its barrier.
    setState(() {
      _saving = false;
      _error = viewModel.actionError;
    });
    viewModel.clearActionError();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit playlist' : 'New playlist'),
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: kDialogMaxWidth,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                InlineBanner(message: _error!, kind: BannerKind.error),
                const SizedBox(height: OmnisonicSpacing.md),
              ],
              TextFormField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Enter a name';
                  if (text.length > 100) return 'Use 100 characters or fewer';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: OmnisonicSpacing.md),
              TextFormField(
                controller: _description,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                validator: (value) => (value?.trim().length ?? 0) > 500
                    ? 'Use 500 characters or fewer'
                    : null,
              ),
              const SizedBox(height: OmnisonicSpacing.sm),
              SwitchListTile(
                title: const Text('Public'),
                subtitle: const Text('Others on the server can find it'),
                value: _isPublic,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _isPublic = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
