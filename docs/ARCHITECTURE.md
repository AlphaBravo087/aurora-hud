# Aurora HUD — Architecture

## Layers

```
┌──────────────────────────────────────────────────────────────┐
│  UI (lib/ui)                                                 │
│  home · drive · media · nav · climate · carplay · settings   │
├──────────────────────────────────────────────────────────────┤
│  State (lib/core/*Controller)                                │
│  Settings · Media · Nav · VehicleBus (ChangeNotifier)        │
│  exposed through `provider` / InheritedWidgets               │
├──────────────────────────────────────────────────────────────┤
│  Hardware abstraction (lib/core/vehicle)                     │
│  - VehicleBus (abstract)                                     │
│    ├── SimulatedVehicleBus  (desktop demo loop)              │
│    ├── ObdBus               (ELM327 over BLE/USB) [planned]  │
│    └── SocketCanBus         (Linux SocketCAN)     [planned]  │
│  - Vehicle profiles (ToyotaCanProfile, …)                    │
├──────────────────────────────────────────────────────────────┤
│  Platform (Linux desktop · RK3588 · Pi CM4 · AGL image)      │
└──────────────────────────────────────────────────────────────┘
```

## Data flow

1. The platform starts Flutter in full-screen kiosk mode.
2. `main.dart` wires up four providers:
   - `SettingsController` — persisted user preferences (SharedPreferences).
   - `VehicleBus` — chosen at runtime. Desktop = simulated; vehicle =
     `SocketCanBus` or `ObdBus`.
   - `MediaController` — playback state (BlueZ on-vehicle, mock on desktop).
   - `NavController` — routing state.
3. All four are `ChangeNotifier`s. UI watches them via `context.watch`.
4. A selected **vehicle profile** (e.g. `ToyotaCanProfile`) maps raw CAN
   frames to `VehicleEvent`s (steering-wheel buttons, gear changes,
   warnings).

## Screens

| Screen     | File                                             | Purpose                                                  |
| ---------- | ------------------------------------------------ | -------------------------------------------------------- |
| Home       | `ui/home/home_screen.dart`                       | User-customisable widget grid                            |
| Drive      | `ui/gauges/gauges_screen.dart`                   | Full cluster — speed, RPM, coolant, powertrain, electrical |
| Media      | `ui/media/media_screen.dart`                     | Album-art player + queue                                 |
| Nav        | `ui/navigation/nav_screen.dart`                  | Map canvas + turn list                                   |
| Climate    | `ui/climate/climate_screen.dart`                 | Driver / passenger zones, vent, fan                      |
| CarPlay    | `ui/carplay/carplay_screen.dart`                 | Dongle passthrough                                       |
| Settings   | `ui/settings/settings_screen.dart`               | Theme, widgets, vehicle profile, driver name             |

## Theming

`AuroraTheme.build(mode, accentOverride)` assembles a `ThemeData` from:

- a **preset** (`AuroraThemeMode` enum) — determines background +
  Brightness.
- an **accent override** — user-chosen swatch.

Colour scheme, sliders, switches, cards and typography are derived from
these two inputs. Changing either in Settings live-rebuilds the entire
app via `AuroraApp.build`.

## Why Flutter?

- Single codebase for the in-vehicle target (Linux ARM64) and the
  desktop design preview (Linux x86_64 / macOS / Windows / web).
- Skia GPU rendering maps well onto the RK3588's Mali-G610.
- Hot-reload drastically cuts dashboard design iteration.
- The Flutter engine ships with OpenGL ES + Vulkan — both work on
  typical automotive-grade SoCs.

Alternative stacks we considered: **Qt/QML** (traditional automotive
choice; heavier, licensing friction); **GTK4** (not enough graphical
oomph on ARM); **React Native** (no mature embedded Linux story yet);
**Web + kiosk browser** (acceptable but higher input latency and no
direct access to SocketCAN/BlueZ).
