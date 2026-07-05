import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ble/bike_connection.dart';
import '../state/ride_controller.dart';
import 'widgets/metric_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RideController>();
    final t = controller.latest;
    final connected =
        controller.connectionState == BikeConnectionState.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: connected ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                children: [
                  MetricTile(
                    label: 'Speed',
                    value: t.speedKmh?.toStringAsFixed(1) ?? '--',
                    unit: 'km/h',
                    highlight: true,
                  ),
                  MetricTile(
                    label: 'Assist',
                    value: t.assistMode?.label ?? '--',
                    highlight: true,
                  ),
                  MetricTile(
                    label: 'Battery',
                    value: t.batteryPercent?.toString() ?? '--',
                    unit: '%',
                  ),
                  MetricTile(
                    label: 'Range',
                    value: t.rangeKm?.toStringAsFixed(0) ?? '--',
                    unit: 'km',
                  ),
                  MetricTile(label: 'Gear', value: t.gearLabel),
                  MetricTile(
                    label: 'Cadence',
                    value: t.cadenceRpm?.toString() ?? '--',
                    unit: 'rpm',
                  ),
                  MetricTile(
                    label: 'Assist power',
                    value: t.powerWatts?.toString() ?? '--',
                    unit: 'W',
                  ),
                  MetricTile(
                    label: 'Heart rate',
                    value: t.heartRateBpm?.toString() ?? '--',
                    unit: 'bpm',
                  ),
                ],
              ),
            ),
            _RecordingBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({required this.controller});

  final RideController controller;

  @override
  Widget build(BuildContext context) {
    final recorder = controller.recorder;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.isRecording
                    ? 'REC ${recorder.distanceKm.toStringAsFixed(2)} km · '
                        '${_fmt(recorder.elapsed)}'
                    : controller.lastExportedGpx != null
                        ? 'Ride saved (${recorder.points.length} points, GPX ready)'
                        : 'Not recording',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: controller.isRecording
                  ? controller.stopRecording
                  : controller.startRecording,
              icon: Icon(controller.isRecording
                  ? Icons.stop
                  : Icons.fiber_manual_record),
              label: Text(controller.isRecording ? 'Stop' : 'Record'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
