# Shimano Ride

An open ride dashboard + logger for Shimano STEPS e-bikes — our own take on
Shimano's **E-TUBE RIDE** app (Phase A of the project; a config/tuning app is
a possible later phase).

## What it does

- **Scan & connect** over Bluetooth LE to a STEPS bike (via the
  EW-WU101/EW-WU111 wireless unit) and to standard fitness sensors
  (heart rate, cycling power, speed/cadence).
- **Live dashboard**: speed, assist mode, battery %, remaining range,
  Di2 gear, cadence, assist power, heart rate.
- **Ride recording**: GPS track annotated with telemetry, exported as
  **GPX 1.1** with Garmin TrackPointExtension (Strava-importable).
- **Bench simulator**: full pipeline (frame encode → CRC → decode →
  dashboard) without hardware.

## Architecture

```
lib/
  models/telemetry.dart        RideTelemetry snapshot + AssistMode
  protocol/
    ble_uuids.dart             Bluetooth SIG assigned numbers
    standard_profiles.dart     CSC / Cycling Power / HR / Battery decoders
    steps_frame.dart           STEPS vendor framing (address/cmd/len/CRC-8)
    steps_decoder.dart         frames -> RideTelemetry
  ble/
    bike_connection.dart       transport-agnostic interface
    flutter_blue_bike_connection.dart  real BLE (flutter_blue_plus)
    simulated_bike_connection.dart     bench simulator
  ride/
    ride_recorder.dart         GPS fixes + telemetry -> ride log
    gpx.dart                   GPX 1.1 writer
  state/ride_controller.dart   app state (provider)
  ui/                          scan page, dashboard
```

Data sources, in order of reliability:

1. **Standard BLE fitness profiles** (speed/cadence/power/HR/battery) —
   byte-exact per the published GATT specs; fully trustworthy.
2. **STEPS vendor frames** — framing (addressed frames + CRC-8) follows
   community reverse engineering of the STEPS wire protocols. Payload field
   offsets are provisional and must be validated against captures from the
   target motor/display generation (E7000/E6100/EN100 expose telemetry;
   E8000 does not) before being trusted on real hardware.

## Running

```sh
flutter pub get
flutter test
flutter analyze

# Without hardware (simulator):
flutter run --dart-define=SIMULATE_BIKE=true

# With a real bike/sensors:
flutter run
```

## Scope & safety

This app is **read-only**: it never writes settings or firmware to the bike.
Configuration/tuning (assist profiles, shift timing) is deliberately out of
scope for this phase — firmware is signed by Shimano, and modifying speed
limits is illegal for road use in many jurisdictions.
