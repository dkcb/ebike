import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/telemetry.dart';
import '../protocol/ble_uuids.dart';
import '../protocol/standard_profiles.dart';
import '../protocol/steps_decoder.dart';
import 'bike_connection.dart';

/// Real BLE transport built on flutter_blue_plus.
///
/// Subscribes to the standard fitness characteristics (CSC, Cycling Power,
/// Heart Rate, Battery) which STEPS wireless units and third-party sensors
/// expose, and to any vendor characteristic that notifies STEPS frames.
class FlutterBlueBikeConnection implements BikeConnection {
  FlutterBlueBikeConnection();

  final _stateController = StreamController<BikeConnectionState>.broadcast();
  final _scanController = StreamController<List<DiscoveredBike>>.broadcast();
  final _telemetryController = StreamController<RideTelemetry>.broadcast();

  final _profileDecoder = StandardProfileDecoder();
  final _stepsDecoder = StepsDecoder();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  BluetoothDevice? _device;
  StreamSubscription<dynamic>? _scanSub;
  bool _connecting = false;

  static const _knownServices = {
    BleUuids.cyclingSpeedCadenceService,
    BleUuids.cyclingPowerService,
    BleUuids.heartRateService,
    BleUuids.batteryService,
  };

  @override
  Stream<BikeConnectionState> get connectionState => _stateController.stream;

  @override
  Stream<List<DiscoveredBike>> get scanResults => _scanController.stream;

  @override
  Stream<RideTelemetry> get telemetry => _telemetryController.stream;

  @override
  Future<void> startScan() async {
    _stateController.add(BikeConnectionState.scanning);
    _scanController.add([]);
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final bikes = results
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => DiscoveredBike(
                id: r.device.remoteId.str,
                name: r.device.platformName,
                rssi: r.rssi,
              ))
          .toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      _scanController.add(bikes);
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> connect(String deviceId) async {
    if (_connecting || _device != null) return;
    await stopScan();
    _connecting = true;
    _stateController.add(BikeConnectionState.connecting);
    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(license: License.nonprofit);
      _device = device;
      _stateController.add(BikeConnectionState.connected);

      final services = await device.discoverServices();
      for (final service in services) {
        final serviceId = _short(service.uuid);
        for (final characteristic in service.characteristics) {
          if (!characteristic.properties.notify &&
              !characteristic.properties.indicate) {
            continue;
          }
          final decoder = _decoderFor(serviceId, _short(characteristic.uuid));
          if (decoder == null) continue;
          await characteristic.setNotifyValue(true);
          _subscriptions.add(characteristic.onValueReceived.listen((data) {
            final snapshot = decoder(data);
            if (snapshot != null) _telemetryController.add(snapshot);
          }));
        }
      }

      _subscriptions.add(device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _stateController.add(BikeConnectionState.disconnected);
        }
      }));
    } on Exception {
      _stateController.add(BikeConnectionState.disconnected);
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  RideTelemetry? Function(List<int>)? _decoderFor(
      String serviceId, String characteristicId) {
    switch (characteristicId) {
      case BleUuids.cscMeasurement:
        return _profileDecoder.decodeCscMeasurement;
      case BleUuids.cyclingPowerMeasurement:
        return _profileDecoder.decodePowerMeasurement;
      case BleUuids.heartRateMeasurement:
        return _profileDecoder.decodeHeartRate;
      case BleUuids.batteryLevel:
        return _profileDecoder.decodeBatteryLevel;
      default:
        // Unknown characteristic on a non-standard service: try the STEPS
        // vendor frame decoder; CRC validation rejects unrelated data.
        return _knownServices.contains(serviceId) ? null : _stepsDecoder.decode;
    }
  }

  static String _short(Guid uuid) {
    final s = uuid.str.toLowerCase();
    return s.length == 4 ? s : s.substring(4, 8);
  }

  @override
  Future<void> disconnect() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _scanSub?.cancel();
    _scanSub = null;
    await _device?.disconnect();
    _device = null;
    _connecting = false;
    _stateController.add(BikeConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _scanController.close();
    await _telemetryController.close();
  }
}
