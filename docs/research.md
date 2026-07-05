# Shimano E-Bike Apps — Research & "Build Our Own" Feasibility

## 1. What Shimano ships today

Shimano's e-bike ecosystem (STEPS) is served by **two official smartphone apps** plus a legacy PC tool:

| App | Purpose | Key capabilities |
|-----|---------|------------------|
| **E-TUBE PROJECT Cyclist** (mobile) | Setup / configuration | Firmware updates, customize electric shifting (Di2), tune **assist power profiles** (Profile 1/2, BASIC + FINE-TUNE modes), configure **AUTO SHIFT / FREE SHIFT** timing, motor-unit & display settings, "Mybike" image registration |
| **E-TUBE RIDE** | Ride computer / dashboard | Turns phone into a cycle computer: speed, assist mode, Di2 gear position, battery level & **traveling range**, gear-usage %, assist-usage %, route search on a map, ride logging, **Strava** export. Connects to sensors (HR, power, speed/cadence) over BLE. Requires SHIMANO ID for full features |
| **E-TUBE PROJECT for Windows/Mac** (legacy) | Dealer/service tool | Same config as mobile but via the **SM-PCE1 USB dongle** wired into the bus |

Connectivity to the bike is via the **EW-WU111 / EW-WU101 wireless unit** (ANT+ and Bluetooth LE), which bridges the bike's internal proprietary wired bus to the phone. Regional restrictions apply (SHIMANO ID availability, speed-limit settings).

Ratings: E-TUBE RIDE ~4.0★, 100k+ installs. Common complaints — telemetry only exposed on certain displays (E7000/E6100/EN100), **not** the most common E8000; clunky UX; limited dashboard customization. That gap is exactly why community apps exist.

## 2. How the system talks (the hard part)

There is **no public API or SDK** from Shimano. Everything below comes from community reverse-engineering.

Two distinct communication layers:

1. **Internal bike bus (E-TUBE / "Di2 bus")** — proprietary **power-line communication**: data is modulated on the DC supply line (~1 MHz carrier on EP800). This is what motor ↔ display ↔ battery ↔ shifters use. Physically it's the EW-SDxx cables. Sniffing needs an ADC at 3–4 MSps (scope/SDR) or a tap on an EW-SD300/SD50 cable with DC-blocking cap.
2. **Battery ↔ charger / motor UART** — a separate, lower-level framed UART protocol with addressed frames, CRCs, auth handshake, and telemetry polling (documented for BT-E6000).
3. **Phone ↔ bike BLE** — the EW-WU111 exposes a Bluetooth LE interface. This is the layer our own app would most realistically target (read telemetry, and — where the display exposes it — gear/assist data).

### Notable community / reverse-engineering projects
- **ottelo9/Shimano-Steps-Simulator-BT-E6000** — the most detailed public work. ESP32 (Tasmota TinyC) that **simulates battery/motor/charger**, with a documented UART protocol (frame addresses 0x00/0x40/0x80/0xC0, auth cmd 0x30, specs 0x31/0x32, telemetry polling, inter-byte ~2.5 ms timing quirk the BMS enforces). Verified to release charge/discharge MOSFETs without the real bike/charger.
- **CapnDeCode/shimano-steps-ep8-canbus-messages-analysis-data** + `multican-sniffer-bridge` — CAN-bus captures/analysis for EP8, 3D-printable EP8 battery breakout connector, dual USB-CAN sniffer bench setup.
- **palosaari/epike_bus_dump** — SDR/ADC demodulator+decoder for the EP800 power-line bus.
- **rolandvs/shimano** (archived) — early hardware exploration, patents, SM-PCE1/EW-WU111 notes, display teardown (Renesas R5F100GJA MCU).
- **ST Ride app** (EMTB forums, on App Store/Play) — a solo dev's alternative dashboard/logger for STEPS motors: speed/cadence/assist/Di2 + GPS + external HR sensors, circumference correction. Proves a third-party ride app is viable on the BLE layer.

## 3. Two ways to "build our own version"

The phrase splits into two very different products. Decide which we want:

### Option A — A ride/dashboard + logging app (recommended first target)
Re-create **E-TUBE RIDE**: connect over BLE to the EW-WU111 (or standard BLE fitness profiles), show live speed / assist mode / gear / battery / range, record GPS tracks, export to Strava/GPX.
- **Feasibility: high.** Standard-profile data (Cycling Power, Speed/Cadence, Heart Rate) is straightforward. Shimano-specific telemetry (assist %, Di2 gear) needs the reverse-engineered BLE characteristics and only works on displays that expose it.
- **Risk: low-to-medium.** Read-only, no safety-critical writes. Main risk is protocol coverage across motor/display generations.
- **Stack:** Flutter or React Native + a BLE plugin (`flutter_blue_plus` / `react-native-ble-plx`), or native Swift/Kotlin. Map + GPS + Strava OAuth.

### Option B — A configuration/tuning app (E-TUBE PROJECT clone)
Write settings: assist profiles, shift timing, **firmware updates**, speed-limit / wheel-circumference.
- **Feasibility: low, and risky.** Requires the authenticated write protocol, signed firmware, and can brick hardware / void warranty / break road-legal (pedelec) limits. Firmware is signed — we can't produce our own.
- **Recommendation:** avoid firmware writes entirely; at most expose the documented safe settings, and only after thorough bench validation with a simulator (see ottelo9's rig) — never on a bike being ridden.

## 4. Suggested build plan (Option A)

1. **Bench setup / legal check** — acquire an EW-WU111 + a STEPS display that exposes telemetry (E7000/E6100/EN100), or an ESP32 bus simulator for safe offline dev. Confirm intended use is legal (don't defeat speed limits on public roads).
2. **BLE discovery** — use nRF Connect / Wireshark BLE + the community captures to map services/characteristics the wireless unit advertises; capture E-TUBE RIDE's own traffic for reference.
3. **Protocol library** — a small, well-tested decoding library (frames, CRC, telemetry fields) that we own and unit-test against recorded captures. Reuse insights from ottelo9 / palosaari (mind their licenses).
4. **App MVP** — connect + live dashboard (speed, assist, battery, gear) + GPS track record + GPX/Strava export. Cross-platform (Flutter) for one codebase.
5. **Iterate** — support more motor/display generations, offline maps, custom dashboard widgets (the top community feature request).

## 5. Key risks & open questions
- **No official API**; everything relies on reverse engineering that varies by generation (E6000 vs E7000/E8000 vs EP8/EP800). Coverage is our biggest unknown.
- **Legal/safety:** tuning speed limits on pedelecs is illegal for road use in the EU; firmware is signed. Keep our product **read/log-only** unless we deliberately scope a bench/off-road tuning tool with disclaimers.
- **Licensing:** community repos have varying licenses — audit before reusing code.
- **Hardware access:** we need at least one compatible bike/motor + EW-WU111, or a simulator, to develop and test.

## 6. Recommendation
Start with **Option A (read-only ride/dashboard app)** — high value, low risk, proven viable by ST Ride. Treat Option B (config/firmware) as a later, carefully-scoped, bench-only effort if at all. I can scaffold a Flutter BLE app skeleton (scan → connect → subscribe → dashboard) and a protocol-decoder module with a test harness fed by recorded captures whenever you're ready.
