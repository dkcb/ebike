import 'package:flutter_test/flutter_test.dart';
import 'package:shimano_ride/models/telemetry.dart';
import 'package:shimano_ride/ride/gpx.dart';
import 'package:shimano_ride/ride/ride_recorder.dart';
import 'package:shimano_ride/ride/track_point.dart';

void main() {
  group('RideRecorder', () {
    test('accumulates distance between fixes', () {
      final recorder = RideRecorder()..start();
      // ~111 m apart (0.001 deg latitude).
      recorder.addFix(latitude: 52.0, longitude: 5.0);
      recorder.addFix(latitude: 52.001, longitude: 5.0);
      recorder.stop();
      expect(recorder.distanceKm * 1000, closeTo(111.2, 1.0));
    });

    test('ignores fixes when not recording', () {
      final recorder = RideRecorder();
      recorder.addFix(latitude: 52.0, longitude: 5.0);
      expect(recorder.points, isEmpty);
    });

    test('annotates fixes with telemetry', () {
      final recorder = RideRecorder()..start();
      recorder.addFix(
        latitude: 52.0,
        longitude: 5.0,
        telemetry: const RideTelemetry(
          speedKmh: 21.5,
          heartRateBpm: 140,
          cadenceRpm: 75,
          powerWatts: 200,
        ),
      );
      final p = recorder.points.single;
      expect(p.speedKmh, 21.5);
      expect(p.heartRateBpm, 140);
      expect(p.cadenceRpm, 75);
      expect(p.powerWatts, 200);
    });
  });

  group('GpxWriter', () {
    test('emits valid GPX with extensions', () {
      final gpx = const GpxWriter().build([
        TrackPoint(
          latitude: 52.0,
          longitude: 5.0,
          time: DateTime.utc(2026, 7, 4, 10, 0, 0),
          elevationMeters: 12.5,
          speedKmh: 18.0,
          heartRateBpm: 130,
          cadenceRpm: 80,
          powerWatts: 180,
        ),
      ], trackName: 'Test <Ride>');

      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('<name>Test &lt;Ride&gt;</name>'));
      expect(gpx, contains('<trkpt lat="52.0" lon="5.0">'));
      expect(gpx, contains('<ele>12.5</ele>'));
      expect(gpx, contains('<time>2026-07-04T10:00:00.000Z</time>'));
      expect(gpx, contains('<gpxtpx:hr>130</gpxtpx:hr>'));
      expect(gpx, contains('<gpxtpx:cad>80</gpxtpx:cad>'));
      expect(gpx, contains('<gpxtpx:speed>5.00</gpxtpx:speed>'));
      expect(gpx, contains('<power>180</power>'));
    });

    test('omits extensions when no sensor data', () {
      final gpx = const GpxWriter().build([
        TrackPoint(
          latitude: 52.0,
          longitude: 5.0,
          time: DateTime.utc(2026, 7, 4),
        ),
      ]);
      expect(gpx, isNot(contains('<extensions>')));
    });
  });
}
