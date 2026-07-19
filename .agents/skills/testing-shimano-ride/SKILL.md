---
name: testing-shimano-ride
description: End-to-end test the Shimano Ride (Phase A) Flutter app golden path (scan -> connect -> live dashboard -> record -> GPX) in a browser using simulator mode. Use when verifying ride-dashboard/telemetry/recording UI or protocol-decode changes.
---

# Testing Shimano Ride (Phase A)

Golden path: scan -> discover simulated STEPS bike -> connect -> live dashboard
(8 telemetry tiles) -> Record -> Stop -> "Ride saved (N points, GPX ready)".

## Run the app for GUI testing
Simulator mode drives the real STEPS encode->CRC->decode pipeline (no mocks):
`--dart-define=SIMULATE_BIKE=true`.

- Prefer a **release web build served statically** over `flutter run -d web-server`
  (debug). The debug web build depends on a single debug-service client and may
  render **blank white** on reload or in a second tab. Release avoids this:
  ```
  flutter build web --release --dart-define=SIMULATE_BIKE=true --dart-define=FAKE_GPS=true
  cd build/web && python -m http.server 8090 --bind 127.0.0.1
  ```
- Flutter web can take ~7s to first paint (CanvasKit). Wait before assuming failure.

## Browser navigation gotcha (Windows / Chrome for Testing)
The computer-tool `type` into the Chrome omnibox may **drop the ":"** so
`127.0.0.1:8080` becomes a Google search (and can hit a reCAPTCHA). Instead open
URLs via the shell so no typing is involved:
`Start-Process chrome "http://127.0.0.1:8090/"`.
This opens a new tab in the running Chrome. Then middle-click stray tabs to close
them (verify with a screenshot — tab X/coordinate clicks are easy to misfire).

## GPS in a headless browser
Real geolocation won't produce *moving* fixes, so the recorder shows 0 distance.
Add a temporary, **uncommitted** `FAKE_GPS` env hook in
`lib/state/ride_controller.dart` `startRecording()` that feeds synthetic moving
fixes on a timer (revert it after testing; keep `lib` matching the repo).
GPX/recorder correctness itself is covered by `flutter test` (unit), so the GUI
test only needs to prove the record->save UI transition.

## What to assert
- Dashboard tiles are below the fold on wide/tall windows — **scroll** to verify
  all 8 (Speed, Assist, Battery, Range, Gear, Cadence, Assist power, Heart rate).
  A broken decode leaves STEPS-derived tiles as "--".
- Liveness: Speed and Assist **change** across samples (proves continuous decode).
- Recording: REC distance climbs from 0.00 and timer runs; after Stop the bar
  shows "Ride saved (N points, GPX ready)" with N >= 3.

## Scope / caveats to report
- No real BLE hardware or real GPS is exercised in the VM — those paths are
  runtime-untested; only the simulator transport + decode/UI/record pipeline are.
- STEPS vendor frame offsets are provisional; test proves the app decodes its own
  frame format, not that the format matches real Shimano hardware.

## Devin Secrets Needed
None for simulator-mode testing.
