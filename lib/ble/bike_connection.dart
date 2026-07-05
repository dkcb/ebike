import '../models/telemetry.dart';

enum BikeConnectionState { disconnected, scanning, connecting, connected }

/// A discovered bike / sensor.
class DiscoveredBike {
  const DiscoveredBike({required this.id, required this.name, required this.rssi});

  final String id;
  final String name;
  final int rssi;
}

/// Transport-agnostic connection to an e-bike and its sensors.
///
/// Implementations: [FlutterBlueBikeConnection] (real BLE via the
/// EW-WU101/EW-WU111 wireless unit and standard fitness sensors) and
/// [SimulatedBikeConnection] (bench development without hardware).
abstract class BikeConnection {
  Stream<BikeConnectionState> get connectionState;
  Stream<List<DiscoveredBike>> get scanResults;

  /// Merged telemetry snapshots, one per incoming notification.
  Stream<RideTelemetry> get telemetry;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<void> dispose();
}
