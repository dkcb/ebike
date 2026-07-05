import 'package:flutter/foundation.dart';

@immutable
class TrackPoint {
  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.elevationMeters,
    this.speedKmh,
    this.heartRateBpm,
    this.cadenceRpm,
    this.powerWatts,
  });

  final double latitude;
  final double longitude;
  final DateTime time;
  final double? elevationMeters;
  final double? speedKmh;
  final int? heartRateBpm;
  final int? cadenceRpm;
  final int? powerWatts;
}
