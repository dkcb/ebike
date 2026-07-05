import 'dart:async';
import 'dart:math' as math;

import '../models/telemetry.dart';
import '../protocol/steps_decoder.dart';
import '../protocol/steps_frame.dart';
import 'bike_connection.dart';

/// Bench simulator: emits realistic STEPS telemetry frames so the full
/// pipeline (frame encode -> CRC -> decode -> dashboard) is exercised
/// end-to-end without hardware, exactly like ESP32 bus-simulator rigs do.
class SimulatedBikeConnection implements BikeConnection {
  SimulatedBikeConnection({this.tickInterval = const Duration(seconds: 1)});

  final Duration tickInterval;

  final _stateController =
      StreamController<BikeConnectionState>.broadcast();
  final _scanController = StreamController<List<DiscoveredBike>>.broadcast();
  final _telemetryController = StreamController<RideTelemetry>.broadcast();
  final _decoder = StepsDecoder();
  final _random = math.Random();

  Timer? _timer;
  double _phase = 0;
  double _battery = 87;

  static const _simulatedBike =
      DiscoveredBike(id: 'sim-steps-e7000', name: 'SHIMANO STEPS (Simulated)', rssi: -55);

  @override
  Stream<BikeConnectionState> get connectionState => _stateController.stream;

  @override
  Stream<List<DiscoveredBike>> get scanResults => _scanController.stream;

  @override
  Stream<RideTelemetry> get telemetry => _telemetryController.stream;

  @override
  Future<void> startScan() async {
    _stateController.add(BikeConnectionState.scanning);
    Timer(const Duration(milliseconds: 400), () {
      if (!_scanController.isClosed) _scanController.add(const [_simulatedBike]);
    });
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(String deviceId) async {
    _stateController.add(BikeConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _stateController.add(BikeConnectionState.connected);
    _timer = Timer.periodic(tickInterval, (_) => _tick());
  }

  void _tick() {
    _phase += 0.05;
    _battery = math.max(5, _battery - 0.01);
    final speed = 18 + 7 * math.sin(_phase) + _random.nextDouble();
    final assistLevel = speed > 22 ? 1 : (speed > 16 ? 2 : 3);
    final payload = StepsTelemetryPayload(
      assistLevel: assistLevel,
      batteryPercent: _battery.round(),
      rangeKm: _battery * 0.9,
      rearGear: (5 + 4 * math.sin(_phase)).round().clamp(1, 11),
      frontGear: 1,
      assistPowerWatts: (120 + 90 * math.sin(_phase + 1)).round(),
    );
    final frame = StepsFrame(
      address: 0x00,
      command: StepsFrame.commandTelemetry,
      payload: payload.encode(),
    ).encode();

    final decoded = _decoder.decode(frame);
    if (decoded == null) return;
    _telemetryController.add(decoded.merge(RideTelemetry(
      speedKmh: double.parse(speed.toStringAsFixed(1)),
      cadenceRpm: (70 + 12 * math.sin(_phase * 1.3)).round(),
      heartRateBpm: (120 + 18 * math.sin(_phase * 0.7)).round(),
      timestamp: DateTime.now(),
    )));
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _stateController.add(BikeConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _stateController.close();
    await _scanController.close();
    await _telemetryController.close();
  }
}
