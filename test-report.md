# Test Report — Shimano Ride (Phase A)

**How tested:** Ran the app as a Flutter **web release build** served locally
(`--dart-define=SIMULATE_BIKE=true`), driven through the browser end-to-end.
Simulator mode encodes real STEPS frames (CRC-8) and decodes them through the
**production `StepsDecoder` pipeline**, so the dashboard values exercise the
actual protocol code, not mocks. Ride recording used a temporary, uncommitted
`FAKE_GPS` hook to supply moving GPS fixes (headless-browser geolocation can't
move); recorder/GPX correctness itself is proven by unit tests.

**Result:** All three tested flows passed. No failures or unexpected behavior.

## Escalations / caveats
- **No real hardware/BLE or real GPS** was exercised — impossible in this VM.
  The BLE transport (`FlutterBlueBikeConnection`) and real geolocation paths
  are therefore **untested at runtime**; only the simulator transport and the
  decode/UI/record pipeline were verified live.
- The **STEPS vendor frame field offsets remain provisional** (documented in
  the code/README) and still need validation against captures from a real
  motor/display before trusting on hardware. The test proves the app correctly
  decodes and displays frames in the format it defines — not that the format
  matches Shimano's.
- Recording used a synthetic GPS hook (see above), so the distance value comes
  from simulated fixes, not a real track.

## Test results
- **Scan discovers the simulated STEPS bike** — passed. "SHIMANO STEPS (Simulated)" tile with "-55 dBm" appeared on tapping Scan.
- **Connect opens live dashboard with decoded telemetry** — passed. Green BT (connected); all 8 tiles decoded (Speed, Assist, Battery 87%, Range 78 km, Gear 1×9, Cadence 82 rpm, Assist power 162 W, HR 136 bpm); values updated continuously (Speed 19.6→24.1 km/h, Assist TRAIL→ECO→BOOST).
- **Ride recording accumulates distance and exports GPX** — passed. "REC" distance climbed 0.03→0.43 km over a running timer; after Stop, "Ride saved (20 points, GPX ready)".
- **Unit suite (GPX/decoder/recorder correctness)** — passed. `flutter test` → 19/19 passing, `flutter analyze` → no issues.

## Evidence

### Scan → discovery
| Precondition (🟢) | Bike discovered (🟢) |
|---|---|
| ![scan page](https://app.devin.ai/attachments/a39713fc-45bb-46e3-a45a-38e6865330e9/ss_82706f48.png) | ![bike found](https://app.devin.ai/attachments/7fe738fb-9374-4b93-8cbe-6e69c0f0937a/ss_0c3d4148.png) |

### Live dashboard (all tiles decoded)
| Speed / Assist (🟢) | Battery / Range (🟢) |
|---|---|
| ![speed assist](https://app.devin.ai/attachments/84b63029-1545-4b6b-bff9-536de6065b77/ss_51b1c2d9.png) | ![battery range](https://app.devin.ai/attachments/f8f5cdaa-adfb-4eb3-82f1-649e832ed2e8/ss_884f9591.png) |

| Gear / Cadence (🟢) | Assist power / Heart rate (🟢) |
|---|---|
| ![gear cadence](https://app.devin.ai/attachments/77c0f74d-04dc-4bc1-a683-88d1d8dbaf2b/ss_6ecab0bb.png) | ![power hr](https://app.devin.ai/attachments/df4b37c7-99df-4591-9e65-3f645f33d735/ss_1ea150ce.png) |

### Liveness + recording
| Values changed live (🟢) | Recording in progress (🟢) |
|---|---|
| ![liveness](https://app.devin.ai/attachments/e7264f26-4308-40ee-94ab-8389793a5402/ss_c83ba4d5.png) | ![recording](https://app.devin.ai/attachments/53e189f5-0133-41aa-9eb2-3848459929c9/ss_c89332b2.png) |

### Ride saved
![ride saved](https://app.devin.ai/attachments/454271ba-40ba-4409-a985-b66c49943014/ss_3f922a2f.png)
