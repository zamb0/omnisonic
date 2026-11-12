import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/services/device_identity.dart';
import '../../../../../core/utils/app_log.dart';
import '../handoff_keyring.dart';
import '../handoff_service.dart';
import 'ble_handoff.dart';

/// Turns the Bluetooth handoff on and off with its setting
/// ([DeviceIdentity.bleHandoffEnabled], off by default).
@lazySingleton
class BleHandoffController {
  BleHandoffController(this._identity, this._handoff, this._keyring);

  final DeviceIdentity _identity;
  final HandoffService _handoff;
  final HandoffKeyring _keyring;

  HandoffTransport? _transport;
  Future<void>? _syncing;

  /// Set while the Bluetooth stack is being started, cleared once it is up.
  /// Still set at the next launch means the start never finished: the
  /// process died in native code, which Dart cannot catch.
  static const _startingKey = 'handoff_ble_starting';

  /// Replaces the real start in tests.
  @visibleForTesting
  Future<HandoffTransport> Function({
    required DeviceIdentity identity,
    required HandoffKeyring keyring,
  })?
  starter;

  /// Whether the last start crashed and Bluetooth handoff was turned off
  /// because of it; for a notice in Settings.
  bool get disabledAfterCrash => _disabledAfterCrash;
  bool _disabledAfterCrash = false;

  /// Whether this build can use Bluetooth at all (not on the web).
  bool get supported => bleHandoffSupported;

  /// Whether this device can be stopped over Bluetooth, besides stopping
  /// others (no GATT server on Linux).
  bool get canBeStopped => blePeripheralSupported;

  /// Follows the setting from now on.
  void init() {
    _identity.addListener(_sync);
    _sync();
  }

  /// For the Settings switch: asks for the permissions first. Returns why
  /// it could not be turned on, or null.
  Future<String?> setEnabled(bool enabled) async {
    if (enabled) {
      final error = await requestBleHandoffPermissions();
      if (error != null) return error;
    }
    await _identity.setBleHandoffEnabled(enabled);
    return null;
  }

  void _sync() {
    // One change at a time; the last one wins once the running one is done.
    _syncing = (_syncing ?? Future<void>.value()).then((_) => _apply());
  }

  Future<void> _apply() async {
    final wanted = supported && _identity.bleHandoffEnabled;
    try {
      if (wanted && _transport == null) {
        final prefs = await SharedPreferences.getInstance();
        // A start that crashed the app would crash it on every launch with
        // the setting saved on, with no way to reach Settings and turn it
        // off. Turn it off instead.
        if (prefs.getBool(_startingKey) ?? false) {
          await prefs.remove(_startingKey);
          _disabledAfterCrash = true;
          AppLog.error(
            'Bluetooth handoff did not start last time; turned it off',
          );
          await _identity.setBleHandoffEnabled(false);
          return;
        }
        await prefs.setBool(_startingKey, true);
        final HandoffTransport transport;
        try {
          transport = await (starter ?? startBleHandoffTransport)(
            identity: _identity,
            keyring: _keyring,
          );
        } finally {
          await prefs.remove(_startingKey);
        }
        _transport = transport;
        _handoff.addTransport(transport);
        AppLog.info('Bluetooth handoff on');
      } else if (!wanted && _transport != null) {
        final transport = _transport!;
        _transport = null;
        await _handoff.removeTransport(transport);
        AppLog.info('Bluetooth handoff off');
      }
    } catch (e) {
      AppLog.warn('Bluetooth handoff could not be started: $e');
    }
  }
}
