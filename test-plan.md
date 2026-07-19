# Test Plan — Shimano Ride (Phase A)

Environment: Flutter web build served at http://127.0.0.1:8080, run with
`--dart-define=SIMULATE_BIKE=true --dart-define=FAKE_GPS=true`.
- `SIMULATE_BIKE`: uses `SimulatedBikeConnection`, which encodes real STEPS
  frames (CRC-8) and decodes them back through the production `StepsDecoder`
  pipeline — so the dashboard values exercise the actual protocol code.
- `FAKE_GPS`: test-only, uncommitted hook feeding synthetic moving GPS fixes so
  the ride recorder is demonstrable in a headless browser (real geolocation
  won't move). Recorder/GPX correctness itself is covered by unit tests.

UI path (from code): `lib/ui/scan_page.dart` Scan FAB → `startScan()` →
tap discovered bike → `connect()` → `DashboardPage` (`lib/ui/dashboard_page.dart`);
Record button in `_RecordingBar` → `RideController.startRecording/stopRecording`
(`lib/state/ride_controller.dart:52,93`).

## Test 1 — Scan discovers the simulated bike
Steps: On "Connect your bike", tap **Scan**.
- PASS: a list tile "SHIMANO STEPS (Simulated)" with an RSSI subtitle (e.g.
  "-55 dBm") appears within ~1s.
- FAIL: no device appears / stays on "Tap Scan…".
(Broken decode would still list the device, so this only proves scanning.)

## Test 2 — Connect opens live dashboard with decoded telemetry
Steps: Tap the "SHIMANO STEPS (Simulated)" tile.
- PASS: navigates to "Ride dashboard"; the BT icon in the app bar is green
  (connected). Metric tiles show non-placeholder values: Speed is a number in
  ~11–26 km/h, Assist shows one of ECO/TRAIL/BOOST (not "--"), Battery ~87%,
  Range a number in km, Gear like "1 x N", Cadence/Assist power/Heart rate
  numeric.
- PASS (liveness): after ~3s, Speed and Assist power **change** between
  screenshots (proves frames are being decoded continuously, not a static
  placeholder).
- FAIL: values remain "--", or BT icon red, or values frozen.
This is the core assertion — a broken frame/CRC/decoder path would leave the
STEPS-derived tiles (Assist, Battery, Range, Gear, Assist power) as "--".

## Test 3 — Ride recording accumulates distance and exports GPX
Steps: Tap **Record**; wait ~5s; tap **Stop**.
- PASS: while recording, the bar shows "REC" with distance climbing from
  0.00 km and an incrementing mm:ss timer.
- PASS: after Stop, the bar shows "Ride saved (N points, GPX ready)" with N ≥ 3.
- Evidence: dump the exported GPX (via a debug console read or the recorder
  unit tests) and confirm it contains `<gpx version="1.1"`, multiple `<trkpt>`,
  and `<gpxtpx:` extension tags with the telemetry.
- FAIL: distance stays 0.00, timer frozen, or "Ride saved" never shown.

## Out of scope
Real BLE hardware, real GPS, firmware/config writes (Phase B).
