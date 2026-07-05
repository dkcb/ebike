import '../models/telemetry.dart';
import 'steps_frame.dart';

/// Converts raw STEPS vendor frames into [RideTelemetry] snapshots.
class StepsDecoder {
  /// Decodes one raw notification. Returns `null` for frames that fail CRC
  /// or carry commands without dashboard-relevant data.
  RideTelemetry? decode(List<int> data) {
    final frame = StepsFrame.decode(data);
    if (frame == null) return null;
    switch (frame.command) {
      case StepsFrame.commandTelemetry:
        final t = StepsTelemetryPayload.decode(frame.payload);
        if (t == null) return null;
        return RideTelemetry(
          assistMode: AssistMode.fromLevel(t.assistLevel),
          batteryPercent: t.batteryPercent,
          rangeKm: t.rangeKm,
          gearRear: t.rearGear == 0 ? null : t.rearGear,
          gearFront: t.frontGear == 0 ? null : t.frontGear,
          powerWatts: t.assistPowerWatts,
          timestamp: DateTime.now(),
        );
      default:
        return null;
    }
  }
}
