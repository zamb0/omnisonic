import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/entities.dart';
import '../viewmodels/server_management_view_model.dart';
import '../../../../core/design_system/design_system.dart';

/// Dialog for editing an existing server
class ServerEditDialog extends StatefulWidget {
  final MusicServer server;

  const ServerEditDialog({super.key, required this.server});

  @override
  State<ServerEditDialog> createState() => _ServerEditDialogState();
}

class _ServerEditDialogState extends State<ServerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server.name);
    _urlController = TextEditingController(text: widget.server.url);
    _usernameController = TextEditingController(text: widget.server.username);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Server'),
      content: SizedBox(
        width: 400,
        height: 400, // Set a fixed height
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Server Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a server name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a server URL';
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OmnisonicColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                    border: Border.all(color: OmnisonicColors.info, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: OmnisonicColors.info, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To change the password, delete and re-add the server.',
                          style: TextStyle(
                            color: OmnisonicColors.info,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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
          onPressed: _isUpdating ? null : _updateServer,
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

  Future<void> _updateServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if anything actually changed
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();

    if (name == widget.server.name &&
        url == widget.server.url &&
        username == widget.server.username) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedServer = widget.server.copyWith(
        name: name,
        url: url,
        username: username,
      );

      final viewModel = context.read<ServerManagementViewModel>();
      final success = await viewModel.updateServer(updatedServer);

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
            content: Text('Failed to update server: $e'),
            backgroundColor: OmnisonicColors.error,
          ),
        );
      }
    }
  }
}
