import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_info.dart';

/// Physical feedback for the interactions that change something.
///
/// The app had none. `PlatformOptimizations.triggerHapticFeedback` existed
/// and was never called from anywhere, so it went with the rest of that
/// file; this is the deliberate replacement.
///
/// Every call is a no-op off iOS and Android. The desktop and web engines
/// either ignore the platform channel or, on some Linux setups, log a
/// missing-plugin warning per call — neither is useful, and a music player
/// buzzing a laptop trackpad on every tap would be worse.
///
/// A plain singleton like [DownloadPreferencesService] rather than a DI
/// registration, so a widget can fire feedback without wiring a provider
/// through to it.
class Haptics extends ChangeNotifier {
  Haptics._() {
    _load();
  }

  static final Haptics instance = Haptics._();

  static const _prefsKey = 'omnisonic_haptics_enabled';

  bool _enabled = true;

  /// Whether feedback fires at all.
  ///
  /// A setting rather than an assumption: haptics are polarising, and some
  /// people turn them off system-wide precisely so apps stop doing this.
  bool get enabled => _enabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey) ?? true;
    if (stored != _enabled) {
      _enabled = stored;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    // Confirm the change through the channel being switched on, so the
    // toggle demonstrates what it controls.
    if (value) await impact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  static bool get _supported =>
      instance._enabled && (AppPlatform.isIOS || AppPlatform.isAndroid);

  /// Moving between discrete options: a tab, a chip, a queue reorder.
  static Future<void> selection() async {
    if (!_supported) return;
    await HapticFeedback.selectionClick();
  }

  /// Committing something: play/pause, a swipe that lands.
  static Future<void> impact() async {
    if (!_supported) return;
    await HapticFeedback.lightImpact();
  }

  /// A state change worth noticing: starring a track, clearing the queue.
  static Future<void> success() async {
    if (!_supported) return;
    await HapticFeedback.mediumImpact();
  }
}
