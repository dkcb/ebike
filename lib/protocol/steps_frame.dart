import 'dart:typed_data';

/// Framed message used for Shimano STEPS vendor telemetry.
///
/// Community reverse engineering of the STEPS wire protocols (battery UART,
/// E-TUBE power-line bus) shows addressed frames of the shape
/// `[address, command, length, payload..., crc]` with an 8-bit checksum.
/// This class implements that framing for the vendor BLE characteristic and
/// for the bench simulator. Payload field offsets in [StepsTelemetryPayload]
/// follow the community analyses but MUST be validated against captures from
/// the target motor/display generation before being trusted on real hardware.
class StepsFrame {
  StepsFrame({required this.address, required this.command, required this.payload});

  /// Sender address. Observed on the wire: 0x00/0x40 (motor/charger side),
  /// 0x80/0xC0 (battery side).
  final int address;
  final int command;
  final Uint8List payload;

  static const int commandTelemetry = 0x20;
  static const int commandDeviceInfo = 0x11;
  static const int commandTrip = 0x32;

  /// CRC-8 (poly 0x07, init 0x00) over address, command, length and payload.
  static int crc8(Iterable<int> bytes) {
    var crc = 0;
    for (final b in bytes) {
      crc ^= b & 0xFF;
      for (var i = 0; i < 8; i++) {
        crc = crc & 0x80 != 0 ? ((crc << 1) ^ 0x07) & 0xFF : (crc << 1) & 0xFF;
      }
    }
    return crc;
  }

  Uint8List encode() {
    final header = [address & 0xFF, command & 0xFF, payload.length & 0xFF];
    final body = [...header, ...payload];
    return Uint8List.fromList([...body, crc8(body)]);
  }

  /// Parses a frame, returning `null` on truncation or CRC mismatch.
  static StepsFrame? decode(List<int> data) {
    if (data.length < 4) return null;
    final length = data[2];
    if (data.length < length + 4) return null;
    final body = data.sublist(0, 3 + length);
    final crc = data[3 + length];
    if (crc8(body) != crc) return null;
    return StepsFrame(
      address: data[0],
      command: data[1],
      payload: Uint8List.fromList(data.sublist(3, 3 + length)),
    );
  }
}

/// Field layout of a [StepsFrame.commandTelemetry] payload.
///
/// Layout (little-endian):
///   0     assist mode (0=OFF 1=ECO 2=TRAIL 3=BOOST 4=WALK)
///   1     battery percent (0-100)
///   2-3   remaining range, 0.1 km units
///   4     rear gear position (1-based, 0 = unknown)
///   5     front gear position (1-based, 0 = unknown)
///   6-7   motor assist power, watts
class StepsTelemetryPayload {
  const StepsTelemetryPayload({
    required this.assistLevel,
    required this.batteryPercent,
    required this.rangeKm,
    required this.rearGear,
    required this.frontGear,
    required this.assistPowerWatts,
  });

  final int assistLevel;
  final int batteryPercent;
  final double rangeKm;
  final int rearGear;
  final int frontGear;
  final int assistPowerWatts;

  static const int byteLength = 8;

  Uint8List encode() {
    final range = (rangeKm * 10).round().clamp(0, 0xFFFF);
    return Uint8List.fromList([
      assistLevel & 0xFF,
      batteryPercent.clamp(0, 100),
      range & 0xFF,
      (range >> 8) & 0xFF,
      rearGear & 0xFF,
      frontGear & 0xFF,
      assistPowerWatts & 0xFF,
      (assistPowerWatts >> 8) & 0xFF,
    ]);
  }

  static StepsTelemetryPayload? decode(List<int> payload) {
    if (payload.length < byteLength) return null;
    return StepsTelemetryPayload(
      assistLevel: payload[0],
      batteryPercent: payload[1],
      rangeKm: (payload[2] | (payload[3] << 8)) / 10.0,
      rearGear: payload[4],
      frontGear: payload[5],
      assistPowerWatts: payload[6] | (payload[7] << 8),
    );
  }
}
