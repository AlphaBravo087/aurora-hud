# Aurora HUD

A Flutter-based in-vehicle infotainment (IVI) **head-unit shell** — a
production-quality, heavily user-customisable launcher designed to run on
aftermarket touchscreen head units in real vehicles, with a Linux-desktop
preview for design and development.

> Aurora HUD is a **user-space application**, not a full vehicle OS. The
> expected target is an embedded Linux image (Debian/Yocto/Automotive Grade
> Linux) on a Rockchip RK3588 or Raspberry Pi CM4 SBC, with Aurora HUD
> auto-starting as the full-screen shell.

## Highlights

- **6 preset themes** (Midnight, OLED Black, Sunset, Daylight, Forest, Cherry)
  and 8 accent swatches, live-switchable from Settings.
- **Customisable home screen** — user toggles which widgets appear (Greeting,
  Next Turn, Now Playing, Drive Gauges, Climate, Trip & Odo, Weather).
- **Dashboard cluster screen** with large speed/RPM/coolant circular gauges
  plus live throttle, brake, boost, intake-air and battery-voltage bar
  gauges.
- **Media screen** with album-art-tinted UI, scrubbing, queue, repeat &
  shuffle. On-device intended to wire into BlueZ A2DP + AVRCP.
- **Navigation screen** with stylised map canvas, turn-by-turn list and ETA.
  Real deployments embed OsmAnd / Mapbox / HERE.
- **Three-zone climate control** with fan, vent direction, heated seats,
  A/C, recirculate, rear defog.
- **CarPlay / Android Auto pane** — note that Apple CarPlay itself cannot be
  legally re-implemented; this pane displays the HDMI feed from a **licensed
  wireless CarPlay dongle** (Carlinkit CPC200-CCPA or equivalent).
- **Toyota-flavoured CAN bus profile** (`ToyotaCanProfile`) as a starter,
  with a pluggable abstraction for other vehicles or generic OBD-II.

## Run the desktop preview

```bash
flutter pub get
flutter run -d linux
```

On first launch it runs a simulated drive loop so every dashboard, gauge,
route step and climate readout updates live.

## Real-vehicle installation

Aurora HUD is architected around a pluggable `VehicleBus`:

- `SimulatedVehicleBus` — for desktop preview (default).
- `ObdBus` (planned) — ELM327 over BLE / USB, reads standard OBD-II PIDs.
- `SocketCanBus` (planned) — raw CAN via SocketCAN with per-vehicle DBCs.

See [`docs/BOM.md`](docs/BOM.md) for the recommended bill of materials and
[`docs/INSTALL.md`](docs/INSTALL.md) for install steps on a Rockchip RK3588
/ Raspberry Pi CM4 target.

## Tests

```bash
flutter test
```

## License

MIT. See [LICENSE](LICENSE).
