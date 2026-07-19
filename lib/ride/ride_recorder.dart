import 'dart:math' as math;

import '../models/telemetry.dart';
import 'gpx.dart';
import 'track_point.dart';

/// Accumulates GPS fixes and merged telemetry into a ride log.
class RideRecorder {
  final List<TrackPoint> _points = [];
  DateTime? _startedAt;
  bool _recording = false;
  double _distanceMeters = 0.0;

  bool get isRecording => _recording;
  List<TrackPoint> get points => List.unmodifiable(_points);
  DateTime? get startedAt => _startedAt;

  Duration get elapsed => _startedAt == null || _points.isEmpty
      ? Duration.zero
      : _points.last.time.difference(_startedAt!);

  double get distanceKm => _distanceMeters / 1000.0;

  double get averageSpeedKmh {
    final hours = elapsed.inSeconds / 3600.0;
    return hours > 0 ? distanceKm / hours : 0;
  }

  void start() {
    _points.clear();
    _distanceMeters = 0.0;
    _startedAt = DateTime.now();
    _recording = true;
  }

  void stop() => _recording = false;

  /// Adds a GPS fix, annotated with the latest telemetry snapshot.
  void addFix({
    required double latitude,
    required double longitude,
    double? elevationMeters,
    DateTime? time,
    RideTelemetry? telemetry,
  }) {
    if (!_recording) return;
    final point = TrackPoint(
      latitude: latitude,
      longitude: longitude,
      time: time ?? DateTime.now(),
      elevationMeters: elevationMeters,
      speedKmh: telemetry?.speedKmh,
      heartRateBpm: telemetry?.heartRateBpm,
      cadenceRpm: telemetry?.cadenceRpm,
      powerWatts: telemetry?.powerWatts,
    );
    if (_points.isNotEmpty) {
      _distanceMeters += _haversineMeters(_points.last, point);
    }
    _points.add(point);
  }

  /// Exports the recorded ride as a GPX 1.1 document (Strava-importable).
  String toGpx({String trackName = 'Ride'}) =>
      const GpxWriter().build(_points, trackName: trackName);

  static double _haversineMeters(TrackPoint a, TrackPoint b) {
    const earthRadius = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h.toDouble()));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
