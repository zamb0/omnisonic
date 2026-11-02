import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../viewmodels/server_management_view_model.dart';

/// Dialog for adding a new Subsonic server
class ServerAddDialog extends StatefulWidget {
  const ServerAddDialog({super.key});

  @override
  State<ServerAddDialog> createState() => _ServerAddDialogState();
}

class _ServerAddDialogState extends State<ServerAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isAdding = false;
  bool _isTesting = false;
  bool _obscurePassword = true;
  String? _testResult;
  bool _testPassed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Server'),
      content: SizedBox(
        width: 400,
        height: 500, // Set a fixed height
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
                    hintText: 'My Music Server',
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
                    hintText: 'https://music.example.com',
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
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? OmnisonicIcons.visibility
                            : OmnisonicIcons.visibilityOff,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
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
                  child: const _NavidromeTips(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTesting || _isAdding
                            ? null
                            : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(OmnisonicIcons.wifiProtectedSetup),
                        label: Text(
                          _isTesting ? 'Testing...' : 'Test Connection',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testPassed
                          ? OmnisonicColors.success.withValues(alpha: 0.1)
                          : OmnisonicColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                      border: Border.all(
                        color: _testPassed
                            ? OmnisonicColors.success
                            : OmnisonicColors.error,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testPassed
                              ? OmnisonicIcons.checkCircle
                              : OmnisonicIcons.error,
                          color: _testPassed
                              ? OmnisonicColors.success
                              : OmnisonicColors.error,
                          size: OmnisonicIconSizes.smd,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              color: _testPassed
                                  ? OmnisonicColors.success
                                  : OmnisonicColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAdding ? null : _addServer,
          child: _isAdding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Server'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final viewModel = context.read<ServerManagementViewModel>();
      final result = await viewModel.testConnectionWithCredentials(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isTesting = false;
          if (result != null && result.isSuccessful) {
            _testPassed = true;
            _testResult =
                'Connection successful! Server: ${result.serverInfo?.version ?? 'Unknown'}';
          } else {
            _testPassed = false;
            _testResult =
                'Connection failed: ${result?.errorMessage ?? 'Unknown error'}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testPassed = false;
          _testResult = 'Connection failed: $e';
        });
      }
    }
  }

  Future<void> _addServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final viewModel = context.read<ServerManagementViewModel>();
      final success = await viewModel.addServer(
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added "${_nameController.text.trim()}"')),
          );
        } else {
          // Show specific error message from view model
          final errorMessage =
              viewModel.errorMessage ?? 'Unknown error occurred';
          setState(() {
            _isAdding = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: OmnisonicColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add server: $e'),
            backgroundColor: OmnisonicColors.error,
          ),
        );
      }
    }
  }
}

/// Setup hints for Navidrome, the most common server people get wrong.
class _NavidromeTips extends StatelessWidget {
  const _NavidromeTips();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              OmnisonicIcons.info,
              color: OmnisonicColors.info,
              size: 20,
            ),
            const SizedBox(width: OmnisonicSpacing.sm),
            Text(
              'Navidrome Setup Tips',
              style: OmnisonicTypography.sectionTitleSmall.copyWith(
                color: OmnisonicColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        Text(
          '• URL: https://your-server.com (no /rest)\n'
          '• Use your Navidrome username/password\n'
          '• Enable "Subsonic API" in Navidrome settings',
          style: OmnisonicTypography.metadata.copyWith(
            color: OmnisonicColors.info,
          ),
        ),
      ],
    );
  }
}
