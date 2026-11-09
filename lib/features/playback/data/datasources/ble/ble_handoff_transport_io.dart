import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:universal_ble/universal_ble.dart';

import '../../../../../core/services/device_identity.dart';
import '../../../../../core/utils/app_log.dart';
import '../../../../../core/utils/platform_info.dart';
import '../handoff_crypto.dart';
import '../handoff_keyring.dart';
import '../handoff_service.dart';

/// The Omnisonic handoff GATT service, advertised by a device while it plays.
const String handoffServiceUuid = 'a6f3e2c0-6d1b-4e7a-9a44-0e5c1a0b9d21';

/// Written by a device that starts playing; carries a [HandoffMessage].
const String handoffControlUuid = 'a6f3e2c1-6d1b-4e7a-9a44-0e5c1a0b9d21';

/// Bluetooth exists in this build.
bool get bleHandoffSupported => !AppPlatform.isWeb;

/// Whether this device can be told to stop over Bluetooth: it needs to
/// advertise and run a GATT server, which the plugin offers on Android,
/// iOS, macOS and Windows. Checked again at runtime (some adapters cannot).
bool get blePeripheralSupported =>
    AppPlatform.isAndroid ||
    AppPlatform.isIOS ||
    AppPlatform.isMacOS ||
    AppPlatform.isWindows;

/// Asks for the Bluetooth permissions the handoff needs. Returns why it
/// cannot be used, or null when it can.
Future<String?> requestBleHandoffPermissions() async {
  try {
    final state = await UniversalBle.getBluetoothAvailabilityState();
    if (state == AvailabilityState.unsupported) {
      return 'This device has no Bluetooth Low Energy.';
    }
    await UniversalBle.requestPermissions();
    if (blePeripheralSupported) {
      // Android asks for the advertising permission when advertising first
      // starts: start and stop once now, so the prompt comes with the
      // switch rather than in the middle of pressing play.
      final caps = await UniversalBlePeripheral.getCapabilities();
      if (caps.supportsPeripheralMode) {
        await UniversalBlePeripheral.startAdvertising(
          services: [handoffServiceUuid],
        );
        await UniversalBlePeripheral.stopAdvertising();
      }
    }
    return null;
  } catch (e) {
    AppLog.warn('Bluetooth permission request failed: $e');
    return 'Bluetooth permission was not granted.';
  }
}

/// Creates and starts the Bluetooth transport.
Future<HandoffTransport> startBleHandoffTransport({
  required DeviceIdentity identity,
  required HandoffKeyring keyring,
}) async {
  final transport = BleHandoffTransport(identity: identity, keyring: keyring);
  await transport.start();
  return transport;
}

/// Tells nearby devices about a takeover over Bluetooth Low Energy.
///
/// A device that plays advertises [handoffServiceUuid] and accepts writes to
/// [handoffControlUuid]. A device that starts playing scans for that service
/// for a few seconds, connects to whatever it finds and writes a signed
/// [HandoffMessage]; the receiver checks the signature against its own
/// account keys and the message's age and nonce, then stops. Nothing needs
/// pairing: the shared secret is the account both devices already use.
///
/// Best effort throughout: every failure is logged and left to the server
/// check, which catches the takeover a few seconds later anyway.
class BleHandoffTransport implements HandoffTransport {
  BleHandoffTransport({required this.identity, required this.keyring});

  final DeviceIdentity identity;
  final HandoffKeyring keyring;

  static const Duration _scanFor = Duration(seconds: 3);
  static const Duration _connectTimeout = Duration(seconds: 5);
  static const int _maxDevices = 4;

  final _takeovers = StreamController<String>.broadcast();
  List<HandoffKey> _keys = const [];

  /// The account keys messages are checked against (set by [start]).
  @visibleForTesting
  set keys(List<HandoffKey> keys) => _keys = keys;
  bool _peripheralReady = false;
  bool _advertising = false;
  bool _wantAdvertising = false;

  /// Partial writes per sender (long writes arrive in pieces).
  final Map<String, List<int>> _buffers = {};

  /// Nonces already acted on, against replays.
  final Map<String, DateTime> _seenNonces = {};

  @override
  Stream<String> get takeovers => _takeovers.stream;

  /// Loads the keys and, where supported, sets up the GATT server.
  Future<void> start() async {
    _keys = await keyring.keys();
    if (!blePeripheralSupported) return;
    try {
      final caps = await UniversalBlePeripheral.getCapabilities();
      if (!caps.supportsPeripheralMode) return;
      UniversalBlePeripheral.setWriteRequestHandlers(handleWrite);
      await UniversalBlePeripheral.clearServices();
      await UniversalBlePeripheral.addService(
        BlePeripheralService(
          uuid: handoffServiceUuid,
          characteristics: [
            BlePeripheralCharacteristic(
              uuid: handoffControlUuid,
              properties: [CharacteristicProperty.write],
              permissions: [PeripheralAttributePermission.writeable],
            ),
          ],
        ),
      );
      _peripheralReady = true;
      if (_wantAdvertising) await _updateAdvertising();
    } catch (e) {
      AppLog.warn('Bluetooth handoff receiver unavailable: $e');
    }
  }

  @override
  Future<void> setPlaying(bool playing) async {
    _wantAdvertising = playing;
    await _updateAdvertising();
  }

  Future<void> _updateAdvertising() async {
    if (!_peripheralReady || _wantAdvertising == _advertising) return;
    try {
      // No pairing: the signature authenticates the sender.
      if (_wantAdvertising) {
        await UniversalBlePeripheral.startAdvertising(
          services: [handoffServiceUuid],
        );
      } else {
        await UniversalBlePeripheral.stopAdvertising();
      }
      _advertising = _wantAdvertising;
    } catch (e) {
      AppLog.warn('Bluetooth advertising change failed: $e');
    }
  }

  /// A write from a central: pieces of a [HandoffMessage], by offset.
  @visibleForTesting
  PeripheralWriteRequestResult? handleWrite(
    String deviceId,
    String characteristicId,
    int offset,
    Uint8List? value,
  ) {
    if (characteristicId.toLowerCase() != handoffControlUuid) return null;
    if (value == null) return PeripheralWriteRequestResult(status: 0);

    final buffer = offset == 0 ? <int>[] : (_buffers[deviceId] ?? <int>[]);
    if (buffer.length != offset) {
      _buffers.remove(deviceId);
      return PeripheralWriteRequestResult(status: 0);
    }
    buffer.addAll(value);
    _buffers[deviceId] = buffer;

    final expected = HandoffMessage.expectedLength(buffer);
    if (expected == null || buffer.length < expected) {
      return PeripheralWriteRequestResult(status: 0);
    }
    _buffers.remove(deviceId);
    _handle(buffer);
    return PeripheralWriteRequestResult(status: 0);
  }

  void _handle(List<int> bytes) {
    final now = DateTime.now();
    final message = HandoffMessage.verify(bytes, _keys, now: now);
    if (message == null) {
      AppLog.debug('Ignored an unverifiable Bluetooth handoff message');
      return;
    }
    if (message.senderTag == identity.tag) return;

    _seenNonces.removeWhere(
      (_, seen) => now.difference(seen) > HandoffMessage.maxAge * 2,
    );
    final nonce = message.nonce.join(',');
    if (_seenNonces.containsKey(nonce)) return;
    _seenNonces[nonce] = now;

    _takeovers.add(message.senderName);
  }

  @override
  Future<void> announceTakeover() async {
    if (_keys.isEmpty) _keys = await keyring.keys();
    if (_keys.isEmpty) return;
    final payload = HandoffMessage.create(
      senderTag: identity.tag,
      senderName: identity.name,
      now: DateTime.now(),
    ).encode(_keys);

    final found = <String>{};
    StreamSubscription<BleDevice>? scan;
    try {
      scan = UniversalBle.scanStream.listen((device) {
        if (found.length < _maxDevices) found.add(device.deviceId);
      });
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [handoffServiceUuid]),
        skipDuplicates: true,
      );
      await Future<void>.delayed(_scanFor);
    } catch (e) {
      AppLog.warn('Bluetooth handoff scan failed: $e');
    } finally {
      try {
        await UniversalBle.stopScan();
      } catch (_) {}
      await scan?.cancel();
    }

    await Future.wait(found.map((id) => _tell(id, payload)));
  }

  Future<void> _tell(String deviceId, Uint8List payload) async {
    try {
      await UniversalBle.connect(deviceId, timeout: _connectTimeout);
      try {
        // Room for the whole message in one write where the platform lets
        // the central ask; elsewhere it is negotiated anyway.
        if (AppPlatform.isAndroid) {
          await UniversalBle.requestMtu(deviceId, 247);
        }
      } catch (_) {}
      await UniversalBle.discoverServices(deviceId);
      await UniversalBle.write(
        deviceId,
        handoffServiceUuid,
        handoffControlUuid,
        payload,
        timeout: _connectTimeout,
      );
      AppLog.info('Told a nearby device to stop over Bluetooth');
    } catch (e) {
      AppLog.debug('Bluetooth handoff to $deviceId failed: $e');
    } finally {
      try {
        await UniversalBle.disconnect(deviceId);
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    try {
      if (_advertising) await UniversalBlePeripheral.stopAdvertising();
      if (_peripheralReady) {
        UniversalBlePeripheral.setWriteRequestHandlers(null);
        await UniversalBlePeripheral.clearServices();
      }
    } catch (_) {}
    _advertising = false;
    _peripheralReady = false;
    await _takeovers.close();
  }
}
