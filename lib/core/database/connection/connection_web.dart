import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../../utils/app_log.dart';

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'omnisonic',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      // Without COOP/COEP headers (GitHub Pages cannot set them) drift falls
      // back to IndexedDB storage; that works, so this is informational.
      if (result.missingFeatures.isNotEmpty) {
        AppLog.info(
          'Web database uses ${result.chosenImplementation} '
          '(missing: ${result.missingFeatures})',
        );
      }

      return result.resolvedExecutor;
    }),
  );
}
