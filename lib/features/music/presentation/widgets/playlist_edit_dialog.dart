import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../viewmodels/playlist_view_model.dart';

/// Dialog for editing an existing playlist
class PlaylistEditDialog extends StatefulWidget {
  final Playlist playlist;

  const PlaylistEditDialog({super.key, required this.playlist});

  @override
  State<PlaylistEditDialog> createState() => _PlaylistEditDialogState();
}

class _PlaylistEditDialogState extends State<PlaylistEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isPublic;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _descriptionController = TextEditingController(
      text: widget.playlist.description ?? '',
    );
    _isPublic = widget.playlist.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Playlist'),
      content: SizedBox(
        width: 400,
        height: 350, // Set a fixed height
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Name *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a playlist name';
                    }
                    if (value.trim().length > 100) {
                      return 'Name must be 100 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.trim().length > 500) {
                      return 'Description must be 500 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Public Playlist'),
                  subtitle: const Text(
                    'Allow others to discover and view this playlist',
                  ),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updatePlaylist,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _updatePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if anything actually changed
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    if (name == widget.playlist.name &&
        description == widget.playlist.description &&
        _isPublic == widget.playlist.isPublic) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedPlaylist = widget.playlist.copyWith(
        name: name,
        description: description,
        isPublic: _isPublic,
        updatedAt: DateTime.now(),
      );

      final viewModel = context.read<PlaylistViewModel>();
      final success = await viewModel.updatePlaylist(updatedPlaylist);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Updated "$name"')));
        } else {
          // Error message is handled by the view model
          setState(() {
            _isUpdating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
