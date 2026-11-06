/// Opens the app database on the current platform.
///
/// Native builds use a file-backed `NativeDatabase` (`dart:ffi`); web builds
/// use drift's `WasmDatabase`, which needs `sqlite3.wasm` and
/// `drift_worker.js` served next to `index.html` (both live in `web/`).
library;

export 'connection_web.dart' if (dart.library.io) 'connection_native.dart';
