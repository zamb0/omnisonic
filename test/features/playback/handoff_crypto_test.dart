import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/device_identity.dart';
import 'package:omnisonic/features/playback/data/datasources/ble/ble_handoff_transport_io.dart';
import 'package:omnisonic/features/playback/data/datasources/handoff_crypto.dart';
import 'package:omnisonic/features/playback/data/datasources/handoff_keyring.dart';
import 'package:shared_preferences/shared_preferences.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

HandoffKey keyFor(String serverId, int seed) => HandoffKey(
  serverId: serverId,
  key: Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) % 256)),
);

void main() {
  group('pbkdf2Sha256', () {
    // RFC 7914 §11 / widely published PBKDF2-HMAC-SHA256 vectors.
    test('matches the published test vectors', () {
      expect(
        hex(pbkdf2Sha256(utf8.encode('password'), utf8.encode('salt'), 1, 32)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        hex(pbkdf2Sha256(utf8.encode('password'), utf8.encode('salt'), 2, 32)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });
  });

  group('HandoffMessage', () {
    final now = DateTime.utc(2026, 11, 9, 12);
    final home = keyFor('home', 1);
    final work = keyFor('work', 2);
    final stranger = keyFor('elsewhere', 3);

    HandoffMessage message({DateTime? at}) => HandoffMessage.create(
      senderTag: 'abc123',
      senderName: 'iPhone di Fabio',
      now: at ?? now,
      random: Random(1),
    );

    test('a receiver sharing one account reads the sender back', () {
      final bytes = message().encode([home, work]);

      final read = HandoffMessage.verify(bytes, [work], now: now)!;

      expect(read.senderName, 'iPhone di Fabio');
      expect(read.senderTag, 'abc123');
      expect(HandoffMessage.expectedLength(bytes), bytes.length);
    });

    test('another account cannot make or read one', () {
      final bytes = message().encode([stranger]);

      expect(HandoffMessage.verify(bytes, [home, work], now: now), isNull);
    });

    test('a changed byte breaks the signature', () {
      final bytes = message().encode([home]);
      // A letter of the name.
      bytes[18] ^= 0x01;

      expect(HandoffMessage.verify(bytes, [home], now: now), isNull);
    });

    test('an old message is refused', () {
      final bytes = message(
        at: now.subtract(const Duration(minutes: 5)),
      ).encode([home]);

      expect(HandoffMessage.verify(bytes, [home], now: now), isNull);
    });

    test('a long name is cut to fit', () {
      final bytes = HandoffMessage.create(
        senderTag: 'abc123',
        senderName: 'Un nome davvero molto lungo per un dispositivo',
        now: now,
      ).encode([home]);

      final read = HandoffMessage.verify(bytes, [home], now: now)!;
      expect(utf8.encode(read.senderName).length, lessThanOrEqualTo(30));
    });
  });

  group('HandoffState', () {
    final home = keyFor('home', 1);
    final work = keyFor('work', 2);

    HandoffState state() => const HandoffState(
      senderTag: 'abc123',
      deviceName: 'iPhone di Fabio',
      serverId: '1731000000000',
      trackId: 'tr-9f3a',
      playing: true,
      position: Duration(seconds: 83, milliseconds: 250),
      duration: Duration(minutes: 4, seconds: 2),
    );

    test('a device of the same account reads it back', () {
      final sealed = state().encrypt(home);

      final read = HandoffState.decrypt(sealed, [work, home])!;

      expect(read.deviceName, 'iPhone di Fabio');
      expect(read.serverId, '1731000000000');
      expect(read.trackId, 'tr-9f3a');
      expect(read.playing, isTrue);
      expect(read.position, const Duration(seconds: 83, milliseconds: 250));
      expect(read.duration, const Duration(minutes: 4, seconds: 2));
      expect(read.senderTag, 'abc123');
    });

    test('nothing about the track is readable without the key', () {
      final sealed = state().encrypt(home);

      expect(HandoffState.decrypt(sealed, [work]), isNull);
      // Not even as plain text in the bytes.
      expect(
        utf8.decode(sealed, allowMalformed: true),
        isNot(contains('tr-9f3a')),
      );
    });

    test('a changed byte is refused', () {
      final sealed = state().encrypt(home);
      sealed[20] ^= 0x40;

      expect(HandoffState.decrypt(sealed, [home]), isNull);
    });
  });

  test('the GATT service declares no descriptors (CoreBluetooth crash)', () {
    // iOS and macOS abort the app on a hand-made 0x2902 descriptor; the
    // platforms add the ones notifications need themselves.
    final service = handoffGattService();
    for (final characteristic in service.characteristics) {
      expect(characteristic.descriptors, isEmpty, reason: characteristic.uuid);
    }
    expect(
      service.characteristics.map((c) => c.uuid),
      containsAll([handoffControlUuid, handoffStateUuid]),
    );
  });

  group('receiver', () {
    late BleHandoffTransport transport;
    final key = keyFor('home', 1);

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'handoff_device_id': 'ffeedd00000000000000000000000000',
      });
      final identity = DeviceIdentity();
      await identity.load();
      transport = BleHandoffTransport(identity: identity, keyring: _NoKeyring())
        ..keys = [key];
    });

    Uint8List signed({String tag = 'abc123'}) => HandoffMessage.create(
      senderTag: tag,
      senderName: 'MacBook',
      now: DateTime.now(),
    ).encode([key]);

    test('reassembles a long write and reports the takeover once', () async {
      final takeovers = <String>[];
      transport.takeovers.listen(takeovers.add);
      final bytes = signed();

      // Two pieces, as a long (prepared) write delivers them.
      transport.handleWrite(
        'central',
        handoffControlUuid,
        0,
        bytes.sublist(0, 20),
      );
      transport.handleWrite(
        'central',
        handoffControlUuid,
        20,
        bytes.sublist(20),
      );
      // The same message again: a replay.
      transport.handleWrite('central', handoffControlUuid, 0, bytes);
      await pumpEventQueue();

      expect(takeovers, ['MacBook']);
    });

    test('hands out its state to readers, one long read in pieces', () async {
      await transport.publishState((
        serverId: 'home',
        trackId: 't42',
        playing: true,
        position: const Duration(seconds: 10),
        duration: const Duration(minutes: 3),
      ));

      final first = transport
          .handleRead('central', handoffStateUuid, 0, null)!
          .value;
      final rest = transport
          .handleRead('central', handoffStateUuid, 20, null)!
          .value;
      final read = HandoffState.decrypt(
        [...first.sublist(0, 20), ...rest],
        [key],
      )!;

      expect(read.trackId, 't42');
      expect(read.playing, isTrue);
      expect(read.position, greaterThanOrEqualTo(const Duration(seconds: 10)));
    });

    test('the position read later has moved on while playing', () async {
      await transport.publishState((
        serverId: 'home',
        trackId: 't42',
        playing: true,
        position: const Duration(seconds: 10),
        duration: const Duration(minutes: 3),
      ));

      final later = HandoffState.decrypt(
        transport.sealedState(
          now: DateTime.now().add(const Duration(seconds: 5)),
        ),
        [key],
      )!;

      expect(later.position.inSeconds, inInclusiveRange(15, 16));
    });

    test('nothing to read when it is not playing anything', () async {
      await transport.publishState(null);

      expect(transport.sealedState(), isEmpty);
    });

    test('ignores its own announcement', () async {
      final takeovers = <String>[];
      transport.takeovers.listen(takeovers.add);

      transport.handleWrite(
        'central',
        handoffControlUuid,
        0,
        signed(tag: 'ffeedd'),
      );
      await pumpEventQueue();

      expect(takeovers, isEmpty);
    });
  });
}

class _NoKeyring implements HandoffKeyring {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
