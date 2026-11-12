import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/services/device_identity.dart';
import 'package:omnisonic/features/playback/data/datasources/ble/ble_handoff_controller.dart';
import 'package:omnisonic/features/playback/data/datasources/handoff_keyring.dart';
import 'package:omnisonic/features/playback/data/datasources/handoff_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_handoff.dart';

/// Bluetooth handoff is started at launch when its setting is on, so a
/// start that kills the app in native code must not do it again.
void main() {
  Future<(BleHandoffController, DeviceIdentity, List<String>)> setUpWith(
    Map<String, Object> prefs,
  ) async {
    SharedPreferences.setMockInitialValues({
      'handoff_device_id': 'abc123ffffffffffffffffffffffffff',
      'handoff_ble_enabled': true,
      ...prefs,
    });
    final identity = DeviceIdentity();
    await identity.load();
    final starts = <String>[];
    final controller = BleHandoffController(identity, _Handoff(), _NoKeyring())
      ..starter = ({required identity, required keyring}) async {
        starts.add('start');
        return _NoTransport();
      };
    return (controller, identity, starts);
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('starts when the setting is on, and records that it finished', () async {
    final (controller, identity, starts) = await setUpWith({});

    controller.init();
    await settle();

    expect(starts, ['start']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('handoff_ble_starting'), isNull);
    expect(identity.bleHandoffEnabled, isTrue);
  });

  test('a start that never finished turns Bluetooth handoff off', () async {
    final (controller, identity, starts) = await setUpWith({
      // Left behind by a launch that crashed while starting Bluetooth.
      'handoff_ble_starting': true,
    });

    controller.init();
    await settle();

    expect(starts, isEmpty);
    expect(identity.bleHandoffEnabled, isFalse);
    expect(controller.disabledAfterCrash, isTrue);
  });
}

class _Handoff extends FakeHandoffService {
  @override
  void addTransport(HandoffTransport transport) {}
}

class _NoKeyring implements HandoffKeyring {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTransport implements HandoffTransport {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
