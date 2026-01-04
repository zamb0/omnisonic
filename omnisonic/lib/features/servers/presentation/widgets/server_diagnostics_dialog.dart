import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/server_connection_service.dart';

/// Dialog for displaying server and secure storage diagnostics
class ServerDiagnosticsDialog extends StatefulWidget {
  const ServerDiagnosticsDialog({super.key});

  @override
  State<ServerDiagnosticsDialog> createState() => _ServerDiagnosticsDialogState();
}

class _ServerDiagnosticsDialogState extends State<ServerDiagnosticsDialog> {
  final ServerConnectionService _connectionService = GetIt.instance<ServerConnectionService>();
  
  bool _isTestingStorage = false;
  String? _storageTestResult;
  bool _storageTestPassed = false;
  Map<String, dynamic>? _diagnostics;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  void _loadDiagnostics() {
    setState(() {
      _diagnostics = _connectionService.getSecureStorageDiagnostics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server Diagnostics'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagnosticsSection(),
              const SizedBox(height: 16),
              _buildStorageTestSection(),
              if (_storageTestResult != null) ...[
                const SizedBox(height: 16),
                _buildTestResultSection(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isTestingStorage ? null : _testSecureStorage,
          child: _isTestingStorage
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test Storage'),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsSection() {
    if (_diagnostics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Storage Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Initialized',
              _diagnostics!['initialized'] as bool,
            ),
            _buildStatusRow(
              'Available',
              _diagnostics!['available'] as bool,
            ),
            _buildStatusRow(
              'Database Fallback',
              _diagnostics!['database_fallback'] as bool,
            ),
            _buildStatusRow(
              'Encryption Test',
              _diagnostics!['encryption_test'] as bool,
            ),
            const SizedBox(height: 8),
            Text(
              'Cached Passwords: ${_diagnostics!['cached_passwords']}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Platform Support:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ..._buildPlatformSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Test',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test secure storage by writing and reading a test value.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultSection() {
    return Card(
      color: _storageTestPassed ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _storageTestPassed ? Icons.check_circle : Icons.error,
                  color: _storageTestPassed ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Test Result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _storageTestPassed ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _storageTestResult!,
              style: TextStyle(
                fontSize: 14,
                color: _storageTestPassed ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${status ? 'Yes' : 'No'}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlatformSupport() {
    final platforms = _diagnostics!['platform_support'] as Map<String, dynamic>;
    return platforms.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              entry.value as bool ? Icons.check : Icons.close,
              color: entry.value as bool ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              entry.key.toUpperCase(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _testSecureStorage() async {
    setState(() {
      _isTestingStorage = true;
      _storageTestResult = null;
    });

    try {
      final result = await _connectionService.checkSecureStorageAvailability();
      
      if (mounted) {
        setState(() {
          _isTestingStorage = false;
          
          result.fold(
            (failure) {
              _storageTestPassed = false;
              _storageTestResult = 'Storage test failed: ${failure.message}';
            },
            (success) {
              _storageTestPassed = true;
              _storageTestResult = 'Secure storage is working correctly!';
            },
          );
          
          // Refresh diagnostics after test
          _loadDiagnostics();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingStorage = false;
          _storageTestPassed = false;
          _storageTestResult = 'Unexpected error during test: $e';
        });
      }
    }
  }
}