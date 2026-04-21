# Bill of Materials

Rough cost target for an aftermarket Aurora HUD install: **~US$350–600**.

| Category           | Component                                              | Notes                                                                      | Approx. cost |
| ------------------ | ------------------------------------------------------ | -------------------------------------------------------------------------- | ------------ |
| SBC                | Radxa Rock 5B (Rockchip RK3588, 8 GB) **or** Pi CM4 + IO board | RK3588 preferred — much faster 3D, H.265 decode, dual MIPI-DSI             | $100–180     |
| Storage            | 256 GB NVMe (Rock 5B) or 64 GB eMMC (CM4)              | Fast I/O matters for map tiles and app start                               | $25–50       |
| Display            | 10.1" 1280×800 capacitive touchscreen (MIPI-DSI or LVDS) | Match SBC's native display interface for best latency                     | $90–130      |
| CarPlay / Auto     | **Carlinkit CPC200-CCPA wireless CarPlay + Android Auto dongle** | Apple-MFi licensed. Required — CarPlay cannot be reimplemented legally.   | $80–110      |
| HDMI capture       | USB-C HDMI capture dongle (UVC-compatible)             | Needed to bring the CarPlay dongle's HDMI feed into the SBC                | $25–45       |
| CAN bus adapter    | Waveshare RS485-CAN HAT / PiCAN2 / Innomaker USB2CAN   | For steering-wheel buttons, gear, climate state, warnings                   | $25–55       |
| OBD-II (optional)  | ELM327-based BLE OR USB adapter                         | Fallback data source when no DBC is available                               | $15–30       |
| GPS                | u-blox NEO-M9N on USB                                   | gpsd-compatible; 10 Hz                                                     | $35          |
| Microphone         | 2-mic MEMS array (ReSpeaker or similar)                 | For voice wake-word + hands-free                                           | $15          |
| Audio DAC          | USB DAC (PCM5102 class) → TPA3255 2×150 W class-D amp   | Standalone so the head unit doesn't fight the factory amp                  | $40–70       |
| Power              | 12 V → 5 V / 5 A step-down with ignition-sense input    | Must not drain battery when ACC off                                         | $15–25       |
| Enclosure          | Custom 3D-printed bezel + 2 DIN sleeve                  | Model varies per vehicle                                                   | $15–30       |
| Reverse camera     | Any analog or USB reverse camera                        | Auto-switches the display when CAN reverse gear signal fires               | $20–40       |

**Total** hard-to-pin-down, but most builds land between **US$450 and
US$650**.

## Why these?

- **RK3588** is the current sweet spot for IVI: 8 cores, Mali-G610, dual
  MIPI-DSI, H.265 4K60, mature Linux BSPs.
- **Carlinkit CPC200** is the most reliable aftermarket wireless CarPlay
  dongle; it handles Apple's MFi authentication for us so we don't have
  to license MFi ourselves.
- **Waveshare CAN HAT** lets the SBC appear as a standard SocketCAN
  interface (`can0`), which Aurora HUD reads via `python-can` or
  directly through Dart isolates.
- **u-blox NEO-M9N** vs cheaper NEO-6M: the M9N has concurrent multi-GNSS
  (GPS + GLONASS + Galileo + BeiDou) and performs noticeably better in
  urban canyons.

## Wiring notes

- SBC **GND** must be tied to chassis at a single point to avoid ground
  loops in the audio chain.
- The CAN HAT needs a proper **120 Ω termination** if it's at the end of
  the bus. Check the vehicle FSM — Toyotas generally terminate at the
  ECM and the gateway, so an aftermarket head unit sitting on the body
  CAN usually does **not** need its own terminator.
- The CarPlay dongle draws ~1 A. Power it off the SBC's dedicated 5 V
  rail, not the CM4's USB-A port.
