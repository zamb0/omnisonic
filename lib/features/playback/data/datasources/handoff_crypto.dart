import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A key the user's devices share for one server account, so a takeover
/// sent over Bluetooth can be checked without pairing: every device of the
/// account already knows its username and password.
class HandoffKey {
  const HandoffKey({required this.serverId, required this.key});

  final String serverId;
  final Uint8List key;

  /// A short public reference to the key, so a receiver knows which of its
  /// keys a signature is for. Derived from the (slow) key, not the password.
  Uint8List get keyId =>
      Uint8List.fromList(sha256.convert(key).bytes.sublist(0, 4));

  /// PBKDF2 iterations. What travels over the air is a signature, which an
  /// eavesdropper could try passwords against; the iterations make each
  /// guess cost that much.
  static const int iterations = 20000;

  /// Derives the key of the account [username] / [password]. Slow on
  /// purpose (see [iterations]): run it off the UI thread.
  static Uint8List derive(String username, String password) => pbkdf2Sha256(
    utf8.encode(password),
    utf8.encode('omnisonic-handoff-v1|${username.toLowerCase()}'),
    iterations,
    32,
  );
}

/// PBKDF2 with HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2Sha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int length,
) {
  final hmac = Hmac(sha256, password);
  final out = BytesBuilder();
  for (var block = 1; out.length < length; block++) {
    final blockIndex = ByteData(4)..setUint32(0, block);
    var u = hmac.convert([...salt, ...blockIndex.buffer.asUint8List()]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.fromList(out.toBytes().sublist(0, length));
}

/// "I have started playing", sent to nearby devices over Bluetooth.
///
/// Layout, all big-endian:
///
///     version (1) | time, unix seconds (4) | nonce (8) | sender tag (3)
///     | name length (1) | name, UTF-8 | signature count (1)
///     | count × (key id (4) | HMAC-SHA256 truncated (16))
///
/// Everything before the signature count is signed. One signature per
/// account the sender has, so a receiver sharing any one account with it
/// can check it.
class HandoffMessage {
  const HandoffMessage({
    required this.time,
    required this.nonce,
    required this.senderTag,
    required this.senderName,
  });

  static const int version = 1;
  static const int _maxName = 30;
  static const int _macLength = 16;

  /// How far the sender's clock may be from the receiver's.
  static const Duration maxAge = Duration(seconds: 60);

  final DateTime time;
  final Uint8List nonce;

  /// The sender's device tag (hex), so a device ignores its own message.
  final String senderTag;
  final String senderName;

  factory HandoffMessage.create({
    required String senderTag,
    required String senderName,
    required DateTime now,
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    return HandoffMessage(
      time: now,
      nonce: Uint8List.fromList([for (var i = 0; i < 8; i++) rng.nextInt(256)]),
      senderTag: senderTag,
      senderName: senderName,
    );
  }

  Uint8List _signedPart() {
    var name = utf8.encode(senderName);
    if (name.length > _maxName) {
      // Cut on a character boundary.
      var cut = senderName;
      while (utf8.encode(cut).length > _maxName) {
        cut = cut.substring(0, cut.length - 1);
      }
      name = utf8.encode(cut);
    }
    final tagBytes = _hexToBytes(senderTag.padRight(6, '0').substring(0, 6));
    final header = ByteData(5)
      ..setUint8(0, version)
      ..setUint32(1, time.toUtc().millisecondsSinceEpoch ~/ 1000);
    return Uint8List.fromList([
      ...header.buffer.asUint8List(),
      ...nonce,
      ...tagBytes,
      name.length,
      ...name,
    ]);
  }

  /// The bytes to send, signed with every key in [keys].
  Uint8List encode(List<HandoffKey> keys) {
    final signed = _signedPart();
    return Uint8List.fromList([
      ...signed,
      keys.length,
      for (final key in keys) ...[...key.keyId, ..._mac(key.key, signed)],
    ]);
  }

  static List<int> _mac(List<int> key, List<int> data) =>
      Hmac(sha256, key).convert(data).bytes.sublist(0, _macLength);

  /// How many bytes a message starting with [bytes] has in total, or null
  /// while not enough of it has arrived to tell.
  static int? expectedLength(List<int> bytes) {
    const fixed = 1 + 4 + 8 + 3;
    if (bytes.length <= fixed) return null;
    final nameLength = bytes[fixed];
    final countAt = fixed + 1 + nameLength;
    if (bytes.length <= countAt) return null;
    return countAt + 1 + bytes[countAt] * (4 + _macLength);
  }

  /// Reads and checks a message: signed with one of [keys], recent enough
  /// at [now]. Null when it is malformed, unsigned for us, or stale.
  static HandoffMessage? verify(
    List<int> bytes,
    List<HandoffKey> keys, {
    required DateTime now,
  }) {
    final length = expectedLength(bytes);
    if (length == null || bytes.length != length) return null;
    if (bytes[0] != version) return null;

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    const fixed = 1 + 4 + 8 + 3;
    final nameLength = bytes[fixed];
    final signedEnd = fixed + 1 + nameLength;
    final signed = bytes.sublist(0, signedEnd);

    var trusted = false;
    final count = bytes[signedEnd];
    for (var i = 0; i < count && !trusted; i++) {
      final at = signedEnd + 1 + i * (4 + _macLength);
      final keyId = bytes.sublist(at, at + 4);
      final mac = bytes.sublist(at + 4, at + 4 + _macLength);
      for (final key in keys) {
        if (_equal(key.keyId, keyId) && _equal(_mac(key.key, signed), mac)) {
          trusted = true;
          break;
        }
      }
    }
    if (!trusted) return null;

    final time = DateTime.fromMillisecondsSinceEpoch(
      data.getUint32(1) * 1000,
      isUtc: true,
    );
    if (now.toUtc().difference(time).abs() > maxAge) return null;

    String name;
    try {
      name = utf8.decode(bytes.sublist(fixed + 1, signedEnd));
    } on FormatException {
      return null;
    }
    return HandoffMessage(
      time: time,
      nonce: Uint8List.fromList(bytes.sublist(5, 13)),
      senderTag: _bytesToHex(bytes.sublist(13, 16)),
      senderName: name,
    );
  }

  /// Constant-time comparison, so timing does not leak how much of a
  /// forged signature was right.
  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static List<int> _hexToBytes(String hex) => [
    for (var i = 0; i + 1 < hex.length; i += 2)
      int.tryParse(hex.substring(i, i + 2), radix: 16) ?? 0,
  ];

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
