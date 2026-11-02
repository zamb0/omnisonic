import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stubs the platform channels the DI container touches so integration tests
/// can resolve the real repositories without a running device.
///
/// Without this, `getApplicationDocumentsDirectory()` throws
/// `MissingPluginException`, the drift database never opens, and every
/// repository call comes back as a `DatabaseFailure`.
///
/// Returns the temporary directory used as the app documents directory; it is
/// deleted automatically when the test group finishes.
Directory setUpTestPlatformChannels() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('omnisonic_test_');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDir.path,
  );

  // Secure storage has no in-memory fake, so back it with a plain map.
  final secureStorage = <String, String>{};
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          secureStorage[args['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          return secureStorage[args['key'] as String];
        case 'readAll':
          return Map<String, String>.from(secureStorage);
        case 'delete':
          secureStorage.remove(args['key'] as String);
          return null;
        case 'deleteAll':
          secureStorage.clear();
          return null;
        case 'containsKey':
          return secureStorage.containsKey(args['key'] as String);
        default:
          return null;
      }
    },
  );

  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/connectivity'),
    (call) async => call.method == 'check' ? ['wifi'] : null,
  );

  SharedPreferences.setMockInitialValues({});

  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  return tempDir;
}
