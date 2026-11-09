import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/server_repository.dart';
import '../../../../core/utils/app_log.dart';
import 'handoff_crypto.dart';

/// The [HandoffKey]s of every configured server account, derived once per
/// password (the derivation is slow on purpose) and off the UI thread.
@lazySingleton
class HandoffKeyring {
  HandoffKeyring(this._servers);

  final ServerRepository _servers;

  /// Per server: a fingerprint of the credentials the key was made from,
  /// so a changed password makes a new key.
  final Map<String, ({String fingerprint, HandoffKey key})> _cache = {};

  Future<List<HandoffKey>> keys() async {
    final servers =
        (await _servers.getAllServers()).valueOrNull ?? const <MusicServer>[];
    final keys = <HandoffKey>[];
    for (final server in servers) {
      final password = (await _servers.getCredentials(server.id)).valueOrNull;
      if (password == null) continue;
      final fingerprint = sha256
          .convert(utf8.encode('${server.username}\u0000$password'))
          .toString();
      final cached = _cache[server.id];
      if (cached != null && cached.fingerprint == fingerprint) {
        keys.add(cached.key);
        continue;
      }
      try {
        final bytes = await compute(_derive, [server.username, password]);
        final key = HandoffKey(serverId: server.id, key: bytes);
        _cache[server.id] = (fingerprint: fingerprint, key: key);
        keys.add(key);
      } catch (e) {
        AppLog.warn('Could not derive the handoff key for ${server.name}: $e');
      }
    }
    return keys;
  }
}

Uint8List _derive(List<String> credentials) =>
    HandoffKey.derive(credentials[0], credentials[1]);
