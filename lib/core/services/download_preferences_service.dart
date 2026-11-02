import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists download-related user preferences across launches.
///
/// A plain singleton (like [ThemeModeController]) so it can be read from
/// anywhere without going through `getIt`/provider wiring.
class DownloadPreferencesService extends ChangeNotifier {
  DownloadPreferencesService._() {
    _load();
  }

  static final DownloadPreferencesService instance =
      DownloadPreferencesService._();

  static const _wifiOnlyKey = 'omnisonic_downloads_wifi_only';

  bool _wifiOnlyEnabled = false;
  bool get wifiOnlyEnabled => _wifiOnlyEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_wifiOnlyKey) ?? false;
    if (stored != _wifiOnlyEnabled) {
      _wifiOnlyEnabled = stored;
      notifyListeners();
    }
  }

  Future<void> setWifiOnlyEnabled(bool enabled) async {
    if (enabled == _wifiOnlyEnabled) return;
    _wifiOnlyEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, enabled);
  }
}
