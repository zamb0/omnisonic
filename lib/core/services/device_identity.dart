import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_log.dart';
import '../utils/platform_info.dart';

/// Who this installation is, as far as other devices are concerned.
///
/// Every device of the user saves the play queue on the same server account,
/// so playback can move between them (see `HandoffService`). For that each
/// one needs a name the server records with the queue: the Subsonic client
/// name, `c`, which Navidrome stores as the queue's `changedBy`. It used to
/// be "Omnisonic" everywhere, so no device could tell its own saves from
/// another's.
///
/// The client name carries a short random tag besides the editable name, so
/// renaming a device, or giving two the same name, does not make one take
/// the other's saves for its own.
@lazySingleton
class DeviceIdentity extends ChangeNotifier {
  static const String clientPrefix = 'Omnisonic';

  static const _idKey = 'handoff_device_id';
  static const _nameKey = 'handoff_device_name';
  static const _bleKey = 'handoff_ble_enabled';

  /// Length of the tag taken from [id] into the client name.
  static const int tagLength = 6;

  String _id = '';
  String _name = '';
  bool _bleHandoffEnabled = false;

  /// Stable random ID of this installation (hex).
  String get id => _id;

  /// The name other devices show for this one ("Playing on …").
  String get name => _name.isEmpty ? defaultName() : _name;

  /// The part of [id] that goes into [clientName].
  String get tag => _id.length >= tagLength ? _id.substring(0, tagLength) : _id;

  /// Whether nearby devices are told about a takeover over Bluetooth too.
  /// Off unless turned on in Settings.
  bool get bleHandoffEnabled => _bleHandoffEnabled;

  /// The Subsonic client name (`c`) for this device.
  String get clientName => '$clientPrefix ($name · $tag)';

  /// Whether a queue saved by [client] was saved by this device.
  bool isThisDevice(String? client) => parseClient(client).tag == tag;

  /// Loads (or creates) the identity. Safe to call more than once.
  Future<void> load({SharedPreferences? preferences}) async {
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      var id = prefs.getString(_idKey);
      if (id == null || id.length < tagLength) {
        id = _randomId();
        await prefs.setString(_idKey, id);
      }
      _id = id;
      _name = prefs.getString(_nameKey) ?? '';
      _bleHandoffEnabled = prefs.getBool(_bleKey) ?? false;
    } catch (e) {
      // Without storage, an identity for this run is still better than
      // none: the device just gets a new tag next time.
      AppLog.warn('Could not load the device identity: $e');
      if (_id.isEmpty) _id = _randomId();
    }
    notifyListeners();
  }

  /// Renames this device. An empty name goes back to the default.
  Future<void> rename(String newName) async {
    final trimmed = newName.trim();
    // Parentheses and the separator would confuse [parseClient].
    _name = trimmed.replaceAll(RegExp(r'[()·]'), '');
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, _name);
    } catch (e) {
      AppLog.warn('Could not save the device name: $e');
    }
  }

  Future<void> setBleHandoffEnabled(bool enabled) async {
    if (enabled == _bleHandoffEnabled) return;
    _bleHandoffEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bleKey, enabled);
    } catch (e) {
      AppLog.warn('Could not save the Bluetooth handoff setting: $e');
    }
  }

  /// A name for this device before the user picks one.
  static String defaultName() {
    if (AppPlatform.isWeb) return 'Web browser';
    if (AppPlatform.isIOS) return 'iPhone';
    if (AppPlatform.isAndroid) return 'Android';
    final host = AppPlatform.hostName;
    if (host != null) return host.split('.').first;
    if (AppPlatform.isMacOS) return 'Mac';
    if (AppPlatform.isWindows) return 'Windows PC';
    if (AppPlatform.isLinux) return 'Linux PC';
    return 'This device';
  }

  static final RegExp _clientPattern = RegExp(
    '^${RegExp.escape(clientPrefix)} \\((.*) · ([0-9a-f]+)\\)\$',
  );

  /// Splits a client name into the device name to show and, for another
  /// Omnisonic device, its tag. Other apps (Feishin, Symfonium, the
  /// server's web UI) keep their own name and have no tag.
  static ({String name, String? tag}) parseClient(String? client) {
    if (client == null || client.isEmpty) {
      return (name: 'another device', tag: null);
    }
    final match = _clientPattern.firstMatch(client);
    if (match == null) return (name: client, tag: null);
    return (name: match.group(1)!, tag: match.group(2));
  }

  static String _randomId() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
