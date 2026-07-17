import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import '../utils/app_log.dart';

/// Theme manager for handling theme switching and persistence
class OmnisonicThemeManager extends ChangeNotifier {
  static const String _themePreferenceKey = 'omnisonic_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Initialize theme manager and load saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themePreferenceKey);

      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      }
    } catch (e) {
      // If loading fails, keep default system theme
      AppLog.warn('Failed to load theme preference: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Save theme preference to persistent storage
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, _themeMode.index);
    } catch (e) {
      AppLog.warn('Failed to save theme preference: $e');
    }
  }

  /// Get the current theme data based on brightness
  ThemeData getTheme(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return OmnisonicTheme.lightTheme;
      case Brightness.dark:
        return OmnisonicTheme.darkTheme;
    }
  }

  /// Switch to light theme
  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Switch to dark theme
  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Switch to system theme
  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setLightTheme();
        break;
      case ThemeMode.system:
        // When system, toggle to opposite of current system setting
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.light) {
          await setDarkTheme();
        } else {
          await setLightTheme();
        }
        break;
    }
  }

  /// Get theme mode name for display
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Check if current theme is dark
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  /// Check if current theme is light
  bool isLight(BuildContext context) {
    return !isDark(context);
  }
}
