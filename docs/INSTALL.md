# Install on a real head unit

These instructions target a **Radxa Rock 5B** running Debian Bookworm
(`rock-5b_debian_bookworm_xfce`). Pi CM4 + Bullseye is almost identical
— just substitute apt packages and GPIO configuration where noted.

## 1. Base OS

```bash
sudo apt update
sudo apt install -y \
  clang cmake ninja-build pkg-config libgtk-3-dev \
  can-utils bluez pulseaudio pulseaudio-module-bluetooth \
  gpsd gpsd-clients
```

Enable the CAN HAT (Waveshare RS485-CAN-HAT — adjust DT overlay for
your board):

```bash
# /boot/firmware/config.txt (Rock 5B)
dtoverlay=mcp251xfd,spi0-0,interrupt=25,oscillator=40000000
```

```bash
sudo ip link set can0 up type can bitrate 500000
# verify
candump can0
```

## 2. Install Flutter

```bash
sudo mkdir -p /opt && cd /opt
sudo curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz \
  -o /tmp/flutter.tar.xz
sudo tar xf /tmp/flutter.tar.xz
echo 'export PATH=/opt/flutter/bin:$PATH' | sudo tee /etc/profile.d/flutter.sh
source /etc/profile.d/flutter.sh
flutter config --enable-linux-desktop
```

## 3. Build Aurora HUD

```bash
git clone <repo-url> /opt/aurora-hud
cd /opt/aurora-hud
flutter pub get
flutter build linux --release
```

## 4. Kiosk auto-start

Create a systemd unit so the shell launches full-screen on boot:

```ini
# /etc/systemd/system/aurora-hud.service
[Unit]
Description=Aurora HUD shell
After=graphical.target

[Service]
User=pi
Environment=DISPLAY=:0
ExecStart=/opt/aurora-hud/build/linux/arm64/release/bundle/aurora_hud
Restart=always

[Install]
WantedBy=graphical.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now aurora-hud
```

## 5. CarPlay dongle

Plug the **Carlinkit CPC200-CCPA** dongle into a USB-C HDMI capture
card, then the capture card into the SBC's USB 3.0 port. It appears
as a standard UVC device (usually `/dev/video0`).

Future work: the `CarPlayScreen` will read this UVC device and composite
it into the pane. Today it shows a stylised placeholder.

## 6. Reverse camera auto-switch

Subscribe to the vehicle's gear-position CAN frame (Toyota: `0x3BC`).
When it transitions to reverse, `VehicleBus.events` emits
`VehicleEvent.gearChange(Gear.reverse)` and the shell swaps to the
reverse-camera pane. Aurora HUD doesn't yet own this behaviour — it's
the next milestone.
