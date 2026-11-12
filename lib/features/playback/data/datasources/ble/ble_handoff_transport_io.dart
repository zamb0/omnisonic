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

/// Read (and notified on change) by devices following this one's playback;
/// carries an encrypted [HandoffState]. The notification itself is one
/// counter byte: notifications are cut at the link's MTU, reads are not.
const String handoffStateUuid = 'a6f3e2c2-6d1b-4e7a-9a44-0e5c1a0b9d21';

/// The handoff GATT service a playing device publishes.
///
/// No descriptors, on purpose: the state characteristic's Client
/// Characteristic Configuration descriptor (0x2902), which notifications
/// need, is added by the platform — Android's plugin adds it, CoreBluetooth
/// and WinRT create it themselves. Declaring it here crashed the app on iOS
/// and macOS at launch: CoreBluetooth refuses a hand-made CCCD with an
/// uncaught Objective-C exception, which no Dart code can catch.
BlePeripheralService handoffGattService() => BlePeripheralService(
  uuid: handoffServiceUuid,
  characteristics: [
    BlePeripheralCharacteristic(
      uuid: handoffControlUuid,
      properties: [CharacteristicProperty.write],
      permissions: [PeripheralAttributePermission.writeable],
    ),
    BlePeripheralCharacteristic(
      uuid: handoffStateUuid,
      properties: [CharacteristicProperty.read, CharacteristicProperty.notify],
      permissions: [PeripheralAttributePermission.readable],
    ),
  ],
);

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
  final _nearby = StreamController<NearbyPlayback?>.broadcast();

  // Publishing (the playing device).
  PublishedPlayback? _published;
  DateTime _publishedAt = DateTime.now();
  int _stateVersion = 0;

  /// The sealed state handed out per reader, so the pieces of one long read
  /// come from the same encryption.
  final Map<String, Uint8List> _stateReads = {};

  // Following (an idle device).
  bool _following = false;
  String? _followed;
  StreamSubscription<Uint8List>? _followNotifications;
  StreamSubscription<bool>? _followConnection;
  Timer? _followRetry;
  static const Duration _followRetryAfter = Duration(seconds: 15);
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

  @override
  Stream<NearbyPlayback?> get nearbyPlayback => _nearby.stream;

  /// Loads the keys and, where supported, sets up the GATT server.
  Future<void> start() async {
    _keys = await keyring.keys();
    if (!blePeripheralSupported) return;
    try {
      final caps = await UniversalBlePeripheral.getCapabilities();
      if (!caps.supportsPeripheralMode) return;
      UniversalBlePeripheral.setWriteRequestHandlers(handleWrite);
      UniversalBlePeripheral.setReadRequestHandlers(handleRead);
      await UniversalBlePeripheral.clearServices();
      await UniversalBlePeripheral.addService(handoffGattService());
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

  // ---------------------------------------------------------------------
  // Publishing: what this device plays, for the ones following it.
  // ---------------------------------------------------------------------

  @override
  Future<void> publishState(PublishedPlayback? state) async {
    _published = state;
    _publishedAt = DateTime.now();
    _stateReads.clear();
    if (!_peripheralReady) return;
    try {
      // Followers read the new state when this changes.
      _stateVersion = (_stateVersion + 1) & 0xff;
      await UniversalBlePeripheral.updateCharacteristicValue(
        characteristicId: handoffStateUuid,
        value: Uint8List.fromList([_stateVersion]),
      );
    } catch (e) {
      AppLog.debug('Could not notify followers: $e');
    }
  }

  /// The current state, sealed for the account of the playing track's
  /// server; empty when this device is not playing anything.
  @visibleForTesting
  Uint8List sealedState({DateTime? now}) {
    final state = _published;
    if (state == null) return Uint8List(0);
    final key = _keys.where((k) => k.serverId == state.serverId);
    if (key.isEmpty) return Uint8List(0);
    final elapsed = (now ?? DateTime.now()).difference(_publishedAt);
    var position = state.playing ? state.position + elapsed : state.position;
    if (state.duration > Duration.zero && position > state.duration) {
      position = state.duration;
    }
    return HandoffState(
      senderTag: identity.tag,
      deviceName: identity.name,
      serverId: state.serverId,
      trackId: state.trackId,
      playing: state.playing,
      position: position,
      duration: state.duration,
    ).encrypt(key.first);
  }

  /// A read of the state characteristic, possibly one piece of a long read.
  @visibleForTesting
  PeripheralReadRequestResult? handleRead(
    String deviceId,
    String characteristicId,
    int offset,
    Uint8List? value,
  ) {
    if (characteristicId.toLowerCase() != handoffStateUuid) return null;
    final sealed = offset == 0
        ? (_stateReads[deviceId] = sealedState())
        : (_stateReads[deviceId] ?? sealedState());
    final from = offset.clamp(0, sealed.length);
    return PeripheralReadRequestResult(value: sealed.sublist(from));
  }

  // ---------------------------------------------------------------------
  // Following: an idle device keeps up with a nearby playing one.
  // ---------------------------------------------------------------------

  @override
  Future<void> setFollowing(bool following) async {
    if (following == _following) return;
    _following = following;
    if (following) {
      unawaited(_follow());
    } else {
      _followRetry?.cancel();
      await _unfollow();
    }
  }

  Future<void> _follow() async {
    _followRetry?.cancel();
    if (!_following || _followed != null) return;
    if (_keys.isEmpty) _keys = await keyring.keys();

    final device = await _findPlayingDevice();
    if (!_following) return;
    if (device == null) {
      _scheduleFollowRetry();
      return;
    }

    try {
      await UniversalBle.connect(device, timeout: _connectTimeout);
      _followed = device;
      _followConnection = UniversalBle.connectionStream(device).listen((up) {
        if (!up) unawaited(_lost());
      });
      try {
        if (AppPlatform.isAndroid) {
          await UniversalBle.requestMtu(device, 247);
        }
      } catch (_) {}
      await UniversalBle.discoverServices(device);
      _followNotifications = UniversalBle.characteristicValueStream(
        device,
        handoffStateUuid,
      ).listen((_) => unawaited(_readState(device)));
      await UniversalBle.subscribeNotifications(
        device,
        handoffServiceUuid,
        handoffStateUuid,
      );
      await _readState(device);
    } catch (e) {
      AppLog.debug('Could not follow $device: $e');
      await _lost();
    }
  }

  Future<String?> _findPlayingDevice() async {
    String? found;
    StreamSubscription<BleDevice>? scan;
    try {
      scan = UniversalBle.scanStream.listen((device) {
        found ??= device.deviceId;
      });
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [handoffServiceUuid]),
        skipDuplicates: true,
      );
      final deadline = DateTime.now().add(_scanFor);
      while (found == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      AppLog.debug('Scan for a playing device failed: $e');
    } finally {
      try {
        await UniversalBle.stopScan();
      } catch (_) {}
      await scan?.cancel();
    }
    return found;
  }

  Future<void> _readState(String device) async {
    try {
      final bytes = await UniversalBle.read(
        device,
        handoffServiceUuid,
        handoffStateUuid,
        timeout: _connectTimeout,
      );
      final state = HandoffState.decrypt(bytes, _keys);
      if (state == null) {
        // Not playing, or another account: nothing to show.
        _nearby.add(null);
        return;
      }
      if (state.senderTag == identity.tag) return;
      _nearby.add(
        NearbyPlayback(
          deviceName: state.deviceName,
          serverId: state.serverId,
          trackId: '${state.serverId}_${state.trackId}',
          playing: state.playing,
          position: state.position,
          duration: state.duration,
          receivedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLog.debug('Reading the nearby playback state failed: $e');
    }
  }

  Future<void> _lost() async {
    await _unfollow();
    _scheduleFollowRetry();
  }

  void _scheduleFollowRetry() {
    _followRetry?.cancel();
    if (!_following) return;
    _followRetry = Timer(_followRetryAfter, () => unawaited(_follow()));
  }

  Future<void> _unfollow() async {
    final device = _followed;
    _followed = null;
    await _followNotifications?.cancel();
    await _followConnection?.cancel();
    _followNotifications = null;
    _followConnection = null;
    if (!_nearby.isClosed) _nearby.add(null);
    if (device == null) return;
    try {
      await UniversalBle.disconnect(device);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Takeover: this device starts playing and tells the others to stop.
  // ---------------------------------------------------------------------

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
    _following = false;
    _followRetry?.cancel();
    await _unfollow();
    try {
      if (_advertising) await UniversalBlePeripheral.stopAdvertising();
      if (_peripheralReady) {
        UniversalBlePeripheral.setWriteRequestHandlers(null);
        UniversalBlePeripheral.setReadRequestHandlers(null);
        await UniversalBlePeripheral.clearServices();
      }
    } catch (_) {}
    _advertising = false;
    _peripheralReady = false;
    await _takeovers.close();
    await _nearby.close();
  }
}
