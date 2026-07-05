/// Bluetooth SIG assigned numbers used by the app.
///
/// Standard fitness profiles are fully documented by the Bluetooth SIG and are
/// the primary, reliable data source. Speed/cadence/power/HR/battery all come
/// from these.
///
/// Shimano's EW-WU101/EW-WU111 wireless units additionally expose proprietary
/// vendor services carrying STEPS-specific data (assist mode, Di2 gear,
/// range). Those UUIDs and payload layouts are not published by Shimano and
/// must be confirmed by sniffing E-TUBE RIDE traffic against real hardware;
/// see `StepsFrame` for the framing used on the wire.
abstract final class BleUuids {
  // --- Standard services -------------------------------------------------
  static const String cyclingSpeedCadenceService = '1816';
  static const String cscMeasurement = '2a5b';

  static const String cyclingPowerService = '1818';
  static const String cyclingPowerMeasurement = '2a63';

  static const String heartRateService = '180d';
  static const String heartRateMeasurement = '2a37';

  static const String batteryService = '180f';
  static const String batteryLevel = '2a19';

  /// Expands a 16-bit SIG-assigned UUID to its canonical 128-bit form.
  static String expand(String short) =>
      '0000$short-0000-1000-8000-00805f9b34fb';
}
