import 'dart:async';

import 'package:injectable/injectable.dart';

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
        final transport = await startBleHandoffTransport(
          identity: _identity,
          keyring: _keyring,
        );
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
