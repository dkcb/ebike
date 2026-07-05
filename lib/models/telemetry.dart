import 'package:flutter/foundation.dart';

/// Assist mode reported by a Shimano STEPS drive unit.
///
/// The numeric [level] mirrors the value Shimano displays (0 = OFF).
enum AssistMode {
  off(0, 'OFF'),
  eco(1, 'ECO'),
  trail(2, 'TRAIL'),
  boost(3, 'BOOST'),
  walk(4, 'WALK');

  const AssistMode(this.level, this.label);

  final int level;
  final String label;

  static AssistMode fromLevel(int level) {
    for (final mode in AssistMode.values) {
      if (mode.level == level) return mode;
    }
    return AssistMode.off;
  }
}

/// A single immutable snapshot of the data exposed by a STEPS e-bike.
///
/// Any field may be `null` when the connected display/motor generation does
/// not expose it (older E8000 displays expose far less than E7000/E6100).
@immutable
class RideTelemetry {
  const RideTelemetry({
    this.speedKmh,
    this.cadenceRpm,
    this.powerWatts,
    this.assistMode,
    this.gearFront,
    this.gearRear,
    this.batteryPercent,
    this.rangeKm,
    this.heartRateBpm,
    this.timestamp,
  });

  final double? speedKmh;
  final int? cadenceRpm;
  final int? powerWatts;
  final AssistMode? assistMode;
  final int? gearFront;
  final int? gearRear;
  final int? batteryPercent;
  final double? rangeKm;
  final int? heartRateBpm;
  final DateTime? timestamp;

  String get gearLabel {
    if (gearRear == null) return '--';
    if (gearFront == null) return '$gearRear';
    return '$gearFront x $gearRear';
  }

  /// Returns a copy where non-null fields of [other] override this snapshot.
  ///
  /// Used to merge partial updates arriving from separate BLE characteristics
  /// (e.g. speed from CSC, battery from the battery service) into one view.
  RideTelemetry merge(RideTelemetry other) {
    return RideTelemetry(
      speedKmh: other.speedKmh ?? speedKmh,
      cadenceRpm: other.cadenceRpm ?? cadenceRpm,
      powerWatts: other.powerWatts ?? powerWatts,
      assistMode: other.assistMode ?? assistMode,
      gearFront: other.gearFront ?? gearFront,
      gearRear: other.gearRear ?? gearRear,
      batteryPercent: other.batteryPercent ?? batteryPercent,
      rangeKm: other.rangeKm ?? rangeKm,
      heartRateBpm: other.heartRateBpm ?? heartRateBpm,
      timestamp: other.timestamp ?? timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RideTelemetry &&
      other.speedKmh == speedKmh &&
      other.cadenceRpm == cadenceRpm &&
      other.powerWatts == powerWatts &&
      other.assistMode == assistMode &&
      other.gearFront == gearFront &&
      other.gearRear == gearRear &&
      other.batteryPercent == batteryPercent &&
      other.rangeKm == rangeKm &&
      other.heartRateBpm == heartRateBpm;

  @override
  int get hashCode => Object.hash(
        speedKmh,
        cadenceRpm,
        powerWatts,
        assistMode,
        gearFront,
        gearRear,
        batteryPercent,
        rangeKm,
        heartRateBpm,
      );
}
