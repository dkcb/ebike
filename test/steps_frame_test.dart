import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shimano_ride/models/telemetry.dart';
import 'package:shimano_ride/protocol/steps_decoder.dart';
import 'package:shimano_ride/protocol/steps_frame.dart';

void main() {
  group('StepsFrame', () {
    test('encode/decode round-trip preserves fields', () {
      final frame = StepsFrame(
        address: 0x40,
        command: StepsFrame.commandTelemetry,
        payload: Uint8List.fromList([1, 2, 3, 4]),
      );
      final decoded = StepsFrame.decode(frame.encode());
      expect(decoded, isNotNull);
      expect(decoded!.address, 0x40);
      expect(decoded.command, StepsFrame.commandTelemetry);
      expect(decoded.payload, [1, 2, 3, 4]);
    });

    test('rejects frames with corrupted CRC', () {
      final bytes = StepsFrame(
        address: 0x00,
        command: 0x20,
        payload: Uint8List.fromList([9, 9]),
      ).encode();
      bytes[bytes.length - 1] ^= 0xFF;
      expect(StepsFrame.decode(bytes), isNull);
    });

    test('rejects truncated frames', () {
      final bytes = StepsFrame(
        address: 0x00,
        command: 0x20,
        payload: Uint8List.fromList(List.filled(8, 1)),
      ).encode();
      expect(StepsFrame.decode(bytes.sublist(0, bytes.length - 2)), isNull);
      expect(StepsFrame.decode([0x00]), isNull);
    });

    test('crc8 matches known vector', () {
      // CRC-8/SMBUS poly 0x07 init 0x00 of "123456789" is 0xF4.
      expect(StepsFrame.crc8('123456789'.codeUnits), 0xF4);
    });
  });

  group('StepsTelemetryPayload', () {
    test('round-trips all fields including 0.1 km range units', () {
      const payload = StepsTelemetryPayload(
        assistLevel: 2,
        batteryPercent: 76,
        rangeKm: 68.3,
        rearGear: 7,
        frontGear: 1,
        assistPowerWatts: 250,
      );
      final decoded = StepsTelemetryPayload.decode(payload.encode());
      expect(decoded, isNotNull);
      expect(decoded!.assistLevel, 2);
      expect(decoded.batteryPercent, 76);
      expect(decoded.rangeKm, closeTo(68.3, 0.001));
      expect(decoded.rearGear, 7);
      expect(decoded.frontGear, 1);
      expect(decoded.assistPowerWatts, 250);
    });

    test('rejects short payloads', () {
      expect(StepsTelemetryPayload.decode([1, 2, 3]), isNull);
    });
  });

  group('StepsDecoder', () {
    test('decodes a telemetry frame into RideTelemetry', () {
      final frame = StepsFrame(
        address: 0x00,
        command: StepsFrame.commandTelemetry,
        payload: const StepsTelemetryPayload(
          assistLevel: 3,
          batteryPercent: 55,
          rangeKm: 40,
          rearGear: 9,
          frontGear: 0,
          assistPowerWatts: 310,
        ).encode(),
      ).encode();

      final t = StepsDecoder().decode(frame);
      expect(t, isNotNull);
      expect(t!.assistMode, AssistMode.boost);
      expect(t.batteryPercent, 55);
      expect(t.rangeKm, 40);
      expect(t.gearRear, 9);
      expect(t.gearFront, isNull); // 0 means unknown
      expect(t.powerWatts, 310);
    });

    test('ignores unknown commands and garbage', () {
      final decoder = StepsDecoder();
      final unknown = StepsFrame(
        address: 0x00,
        command: 0x7F,
        payload: Uint8List.fromList([1]),
      ).encode();
      expect(decoder.decode(unknown), isNull);
      expect(decoder.decode([0xDE, 0xAD, 0xBE, 0xEF]), isNull);
    });
  });
}
