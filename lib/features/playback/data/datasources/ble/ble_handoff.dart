/// Bluetooth handoff, where the platform has it (see the io variant).
library;

export 'ble_handoff_transport_web.dart'
    if (dart.library.io) 'ble_handoff_transport_io.dart';
