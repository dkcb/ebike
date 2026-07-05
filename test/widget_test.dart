import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimano_ride/ble/simulated_bike_connection.dart';
import 'package:shimano_ride/main.dart';
import 'package:shimano_ride/ui/dashboard_page.dart';

void main() {
  testWidgets('scan page finds simulated bike and opens dashboard',
      (tester) async {
    final connection = SimulatedBikeConnection();
    await tester.pumpWidget(ShimanoRideApp(connection: connection));

    expect(find.text('Connect your bike'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('SHIMANO STEPS (Simulated)'), findsOneWidget);

    await tester.tap(find.text('SHIMANO STEPS (Simulated)'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);
    expect(find.text('ASSIST'), findsOneWidget);

    // Let the simulator tick once; telemetry should replace placeholders.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('BATTERY'), findsOneWidget);

    await connection.disconnect();
    await tester.pumpWidget(const SizedBox());
  });
}
