import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ble/bike_connection.dart';
import '../state/ride_controller.dart';
import 'dashboard_page.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RideController>();
    final scanning =
        controller.connectionState == BikeConnectionState.scanning;

    return Scaffold(
      appBar: AppBar(title: const Text('Connect your bike')),
      body: Column(
        children: [
          if (scanning) const LinearProgressIndicator(),
          Expanded(
            child: controller.discoveredBikes.isEmpty
                ? Center(
                    child: Text(scanning
                        ? 'Scanning for bikes and sensors…'
                        : 'Tap Scan to find your STEPS bike'),
                  )
                : ListView.builder(
                    itemCount: controller.discoveredBikes.length,
                    itemBuilder: (context, index) {
                      final bike = controller.discoveredBikes[index];
                      return ListTile(
                        leading: const Icon(Icons.electric_bike),
                        title: Text(bike.name),
                        subtitle: Text('${bike.rssi} dBm'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await controller.connect(bike.id);
                          if (context.mounted) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const DashboardPage(),
                            ));
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanning ? null : controller.startScan,
        icon: const Icon(Icons.bluetooth_searching),
        label: Text(scanning ? 'Scanning…' : 'Scan'),
      ),
    );
  }
}
