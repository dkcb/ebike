import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../ble/bike_connection.dart';
import '../models/telemetry.dart';
import '../ride/ride_recorder.dart';

/// Application state: bike connection, latest merged telemetry, and ride
/// recording driven by GPS fixes.
class RideController extends ChangeNotifier {
  RideController(this._connection) {
    _stateSub = _connection.connectionState.listen((state) {
      connectionState = state;
      notifyListeners();
    });
    _scanSub = _connection.scanResults.listen((results) {
      discoveredBikes = results;
      notifyListeners();
    });
    _telemetrySub = _connection.telemetry.listen((snapshot) {
      final merged = latest.merge(snapshot);
      if (merged != latest) {
        latest = merged;
        notifyListeners();
      }
    });
  }

  final BikeConnection _connection;
  final RideRecorder recorder = RideRecorder();

  BikeConnectionState connectionState = BikeConnectionState.disconnected;
  List<DiscoveredBike> discoveredBikes = const [];
  RideTelemetry latest = const RideTelemetry();
  String? lastExportedGpx;

  late final StreamSubscription<BikeConnectionState> _stateSub;
  late final StreamSubscription<List<DiscoveredBike>> _scanSub;
  late final StreamSubscription<RideTelemetry> _telemetrySub;
  StreamSubscription<Position>? _gpsSub;

  bool get isRecording => recorder.isRecording;

  Future<void> startScan() => _connection.startScan();

  Future<void> connect(String deviceId) => _connection.connect(deviceId);

  Future<void> disconnect() async {
    await stopRecording();
    await _connection.disconnect();
  }

  Future<void> startRecording() async {
    if (recorder.isRecording) return;
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;
    lastExportedGpx = null;
    recorder.start();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((position) {
      recorder.addFix(
        latitude: position.latitude,
        longitude: position.longitude,
        elevationMeters: position.altitude,
        telemetry: latest,
      );
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!recorder.isRecording) return;
    recorder.stop();
    await _gpsSub?.cancel();
    _gpsSub = null;
    lastExportedGpx = recorder.toGpx(
      trackName: 'Ride ${DateTime.now().toIso8601String()}',
    );
    notifyListeners();
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _scanSub.cancel();
    _telemetrySub.cancel();
    _gpsSub?.cancel();
    _connection.dispose();
    super.dispose();
  }
}
