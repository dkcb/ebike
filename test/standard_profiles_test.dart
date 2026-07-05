import 'package:flutter_test/flutter_test.dart';
import 'package:shimano_ride/protocol/standard_profiles.dart';

void main() {
  group('StandardProfileDecoder', () {
    test('CSC wheel data yields speed after two notifications', () {
      final decoder = StandardProfileDecoder(wheelCircumferenceMm: 2000);

      // flags=0x01 (wheel only), 100 revs, event time 0.
      final first = decoder.decodeCscMeasurement(
          [0x01, 100, 0, 0, 0, 0x00, 0x00]);
      expect(first.speedKmh, isNull);

      // +5 revs over 1024 ticks (1 s): 10 m/s = 36 km/h.
      final second = decoder.decodeCscMeasurement(
          [0x01, 105, 0, 0, 0, 0x00, 0x04]);
      expect(second.speedKmh, closeTo(36.0, 0.01));
      expect(decoder.distanceMeters, closeTo(10.0, 0.001));
    });

    test('CSC crank data yields cadence and handles rollover', () {
      final decoder = StandardProfileDecoder();

      // flags=0x02 (crank only), revs near uint16 max, time near max.
      decoder.decodeCscMeasurement([0x02, 0xFE, 0xFF, 0x00, 0xFC]);
      // Rolls over: +2 revs in 2048 ticks (2 s) -> 60 rpm.
      final t = decoder.decodeCscMeasurement([0x02, 0x00, 0x00, 0x00, 0x04]);
      expect(t.cadenceRpm, 60);
    });

    test('power measurement decodes signed watts', () {
      final decoder = StandardProfileDecoder();
      expect(decoder.decodePowerMeasurement([0, 0, 0xFA, 0x00]).powerWatts, 250);
      expect(
          decoder.decodePowerMeasurement([0, 0, 0xFF, 0xFF]).powerWatts, -1);
    });

    test('heart rate decodes 8-bit and 16-bit formats', () {
      final decoder = StandardProfileDecoder();
      expect(decoder.decodeHeartRate([0x00, 132]).heartRateBpm, 132);
      expect(decoder.decodeHeartRate([0x01, 0x2C, 0x01]).heartRateBpm, 300);
    });

    test('battery level clamps to 0-100', () {
      final decoder = StandardProfileDecoder();
      expect(decoder.decodeBatteryLevel([87]).batteryPercent, 87);
      expect(decoder.decodeBatteryLevel([120]).batteryPercent, 100);
    });
  });
}
