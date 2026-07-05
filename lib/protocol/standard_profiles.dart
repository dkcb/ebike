import '../models/telemetry.dart';

/// Decoders for Bluetooth SIG standard fitness characteristics.
///
/// All formats follow the published GATT specifications and are byte-exact:
/// - Cycling Speed and Cadence Measurement (0x2A5B)
/// - Cycling Power Measurement (0x2A63)
/// - Heart Rate Measurement (0x2A37)
/// - Battery Level (0x2A19)
class StandardProfileDecoder {
  StandardProfileDecoder({this.wheelCircumferenceMm = 2200});

  /// Wheel circumference used to convert wheel revolutions to distance.
  /// STEPS bikes commonly register 2050–2300 mm; user-adjustable so the
  /// dashboard can compensate for dealer-set circumference values.
  int wheelCircumferenceMm;

  int? _lastWheelRevs;
  int? _lastWheelEventTime; // 1/1024 s units
  int? _lastCrankRevs;
  int? _lastCrankEventTime; // 1/1024 s units

  /// Total distance accumulated from wheel revolutions, in meters.
  double distanceMeters = 0;

  void reset() {
    _lastWheelRevs = null;
    _lastWheelEventTime = null;
    _lastCrankRevs = null;
    _lastCrankEventTime = null;
    distanceMeters = 0;
  }

  /// Decodes a CSC Measurement notification into speed and cadence.
  RideTelemetry decodeCscMeasurement(List<int> data) {
    if (data.isEmpty) return const RideTelemetry();
    final flags = data[0];
    final hasWheel = flags & 0x01 != 0;
    final hasCrank = flags & 0x02 != 0;
    var offset = 1;

    double? speedKmh;
    int? cadenceRpm;

    if (hasWheel && data.length >= offset + 6) {
      final wheelRevs = _u32(data, offset);
      final eventTime = _u16(data, offset + 4);
      offset += 6;
      if (_lastWheelRevs != null) {
        final revDelta = (wheelRevs - _lastWheelRevs!) & 0xFFFFFFFF;
        final timeDelta = (eventTime - _lastWheelEventTime!) & 0xFFFF;
        if (timeDelta > 0) {
          final meters = revDelta * wheelCircumferenceMm / 1000.0;
          final seconds = timeDelta / 1024.0;
          speedKmh = meters / seconds * 3.6;
          distanceMeters += meters;
        }
      }
      _lastWheelRevs = wheelRevs;
      _lastWheelEventTime = eventTime;
    }

    if (hasCrank && data.length >= offset + 4) {
      final crankRevs = _u16(data, offset);
      final eventTime = _u16(data, offset + 2);
      if (_lastCrankRevs != null) {
        final revDelta = (crankRevs - _lastCrankRevs!) & 0xFFFF;
        final timeDelta = (eventTime - _lastCrankEventTime!) & 0xFFFF;
        if (timeDelta > 0) {
          cadenceRpm = (revDelta * 1024 * 60 / timeDelta).round();
        }
      }
      _lastCrankRevs = crankRevs;
      _lastCrankEventTime = eventTime;
    }

    return RideTelemetry(
      speedKmh: speedKmh,
      cadenceRpm: cadenceRpm,
      timestamp: DateTime.now(),
    );
  }

  /// Decodes a Cycling Power Measurement notification.
  RideTelemetry decodePowerMeasurement(List<int> data) {
    if (data.length < 4) return const RideTelemetry();
    // flags: uint16 (bytes 0-1), instantaneous power: sint16 (bytes 2-3).
    var power = _u16(data, 2);
    if (power > 0x7FFF) power -= 0x10000;
    return RideTelemetry(powerWatts: power, timestamp: DateTime.now());
  }

  /// Decodes a Heart Rate Measurement notification.
  RideTelemetry decodeHeartRate(List<int> data) {
    if (data.length < 2) return const RideTelemetry();
    final is16Bit = data[0] & 0x01 != 0;
    final bpm = is16Bit && data.length >= 3 ? _u16(data, 1) : data[1];
    return RideTelemetry(heartRateBpm: bpm, timestamp: DateTime.now());
  }

  /// Decodes a Battery Level read/notification (0-100 %).
  RideTelemetry decodeBatteryLevel(List<int> data) {
    if (data.isEmpty) return const RideTelemetry();
    return RideTelemetry(
      batteryPercent: data[0].clamp(0, 100),
      timestamp: DateTime.now(),
    );
  }

  static int _u16(List<int> d, int i) => d[i] | (d[i + 1] << 8);

  static int _u32(List<int> d, int i) =>
      d[i] | (d[i + 1] << 8) | (d[i + 2] << 16) | (d[i + 3] << 24);
}
