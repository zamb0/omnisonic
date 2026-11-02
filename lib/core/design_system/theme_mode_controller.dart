import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's light/dark/system theme preference across launches.
///
/// A plain singleton (like [OmnisonicImageCacheManager]) rather than a DI
/// registration: it's read by `main.dart` before the widget tree — and
/// therefore before `getIt` provider wiring — is fully built.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController._() {
    _load();
  }

  static final ThemeModeController instance = ThemeModeController._();

  static const _prefsKey = 'omnisonic_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
