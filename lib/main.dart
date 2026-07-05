import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ble/bike_connection.dart';
import 'ble/flutter_blue_bike_connection.dart';
import 'ble/simulated_bike_connection.dart';
import 'state/ride_controller.dart';
import 'ui/scan_page.dart';

/// Run with `--dart-define=SIMULATE_BIKE=true` to develop without hardware.
const bool kSimulateBike =
    bool.fromEnvironment('SIMULATE_BIKE', defaultValue: false);

void main() {
  final BikeConnection connection =
      kSimulateBike ? SimulatedBikeConnection() : FlutterBlueBikeConnection();
  runApp(ShimanoRideApp(connection: connection));
}

class ShimanoRideApp extends StatelessWidget {
  const ShimanoRideApp({super.key, required this.connection});

  final BikeConnection connection;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RideController(connection),
      child: MaterialApp(
        title: 'Shimano Ride',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF004A8F),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const ScanPage(),
      ),
    );
  }
}
