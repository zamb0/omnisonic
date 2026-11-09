import '../../../../../core/services/device_identity.dart';
import '../handoff_keyring.dart';
import '../handoff_service.dart';

/// The web build has no Bluetooth handoff: a page can neither advertise nor
/// connect without the user picking a device each time. The server check
/// covers it.
bool get bleHandoffSupported => false;

bool get blePeripheralSupported => false;

Future<String?> requestBleHandoffPermissions() async =>
    'Bluetooth handoff is not available in the browser.';

Future<HandoffTransport> startBleHandoffTransport({
  required DeviceIdentity identity,
  required HandoffKeyring keyring,
}) => throw UnsupportedError('No Bluetooth handoff on the web');
