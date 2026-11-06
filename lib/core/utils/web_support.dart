import 'package:flutter/foundation.dart';

/// Features that need a real file system and are therefore off in the web
/// build. Downloads and the audio cache write files with `dart:io`, which
/// throws in a browser.
const bool supportsOfflineDownloads = !kIsWeb;

/// Shown where the downloads UI would otherwise be.
const String offlineUnavailableOnWebMessage =
    'Downloads and offline listening need the desktop or mobile app. '
    'The web app streams only.';
