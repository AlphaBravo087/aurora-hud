import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'vehicle_state.dart';

/// Abstract source of live vehicle state. Concrete implementations:
///   * [SimulatedVehicleBus] — plausible driving loop, used on desktop preview
///   * ObdBus (future) — ELM327 over BLE/USB, reads standard OBD-II PIDs
///   * SocketCanBus (future) — raw CAN via SocketCAN on a real head unit
abstract class VehicleBus extends ChangeNotifier {
  VehicleState get state;

  /// Human-friendly hint shown in Settings ("Simulated", "OBD-II @ /dev/ttyUSB0", ...).
  String get sourceName;

  /// Event stream of discrete vehicle inputs (steering-wheel buttons, gear changes...).
  Stream<VehicleEvent> get events;

  /// Called when the user requests a climate change from the UI. A real
  /// implementation would arbitrate and forward onto the climate CAN bus.
  void setCabinTarget(double celsius);

  /// Indicate a button press propagated back to the car (e.g. to dismiss a
  /// phone call via steering-wheel button feedback).
  void sendSteeringButton(SteeringButton b);

  // --- 4WD / off-road controls -------------------------------------------

  /// Request a transfer-case mode change. Real hardware would forward this to
  /// the transfer-case ECU and the ECU decides whether the shift is permitted
  /// (e.g. 4L requires vehicle stopped + neutral).
  void setTransferCase(TransferCaseMode mode);

  void setFrontDiffLocked(bool locked);
  void setCenterDiffLocked(bool locked);
  void setRearDiffLocked(bool locked);
  void setHillDescentAssist(bool enabled);
  void setCrawlControl(bool enabled);
}

enum SteeringButton {
  volumeUp,
  volumeDown,
  next,
  previous,
  voice,
  phoneAnswer,
  phoneHangup,
  modeToggle,
}

class VehicleEvent {
  VehicleEvent.button(this.button)
      : gear = null,
        warning = null;
  VehicleEvent.gearChange(this.gear)
      : button = null,
        warning = null;
  VehicleEvent.warning(this.warning)
      : button = null,
        gear = null;

  final SteeringButton? button;
  final Gear? gear;
  final String? warning;
}

/// A deterministic-ish driving loop that produces state the dashboards can
/// display without any real hardware.
class SimulatedVehicleBus extends VehicleBus {
  SimulatedVehicleBus() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  Timer? _timer;
  final _events = StreamController<VehicleEvent>.broadcast();
  final _rng = math.Random(42);

  VehicleState _state = const VehicleState(
    speedKph: 0,
    rpm: 780,
    coolantC: 60,
    fuelPct: 0.72,
    odometerKm: 38421,
    tripKm: 42.7,
    voltage: 14.1,
    altitudeM: 42,
    headingDeg: 78,
  );

  double _phase = 0;
  double _targetCabin = 22;

  @override
  VehicleState get state => _state;

  @override
  String get sourceName => 'Simulated drive loop';

  @override
  Stream<VehicleEvent> get events => _events.stream;

  @override
  void setCabinTarget(double celsius) {
    _targetCabin = celsius.clamp(16.0, 30.0);
  }

  @override
  void sendSteeringButton(SteeringButton b) {
    _events.add(VehicleEvent.button(b));
  }

  @override
  void setTransferCase(TransferCaseMode mode) {
    _state = _state.copyWith(transferCase: mode);
    notifyListeners();
  }

  @override
  void setFrontDiffLocked(bool locked) {
    _state = _state.copyWith(frontDiffLocked: locked);
    notifyListeners();
  }

  @override
  void setCenterDiffLocked(bool locked) {
    _state = _state.copyWith(centerDiffLocked: locked);
    notifyListeners();
  }

  @override
  void setRearDiffLocked(bool locked) {
    _state = _state.copyWith(rearDiffLocked: locked);
    notifyListeners();
  }

  @override
  void setHillDescentAssist(bool enabled) {
    _state = _state.copyWith(hillDescentAssist: enabled);
    notifyListeners();
  }

  @override
  void setCrawlControl(bool enabled) {
    _state = _state.copyWith(crawlControl: enabled);
    notifyListeners();
  }

  void _tick(Timer _) {
    _phase += 0.1;

    // Target speed sweeps between 0 and 110 km/h on a slow sinusoid.
    final double targetSpeed = 55 + 55 * math.sin(_phase * 0.03);
    final double speedDelta = targetSpeed - _state.speedKph;
    final double newSpeed = _state.speedKph + speedDelta * 0.03;

    // RPM roughly tracks speed + noise.
    final double gearRatio = newSpeed < 25 ? 120 : newSpeed < 55 ? 70 : 45;
    final double newRpm = (800 + newSpeed * gearRatio / 3.0 +
            60 * math.sin(_phase * 0.7) +
            _rng.nextDouble() * 30)
        .clamp(700.0, 7000.0);

    final double newThrottle = ((speedDelta > 0 ? 0.4 : 0.05) +
            0.3 * math.sin(_phase * 0.5).abs())
        .clamp(0.0, 1.0);
    final double newBrake = speedDelta < -1.5 ? 0.2 + 0.1 * _rng.nextDouble() : 0.0;
    final double newSteer = 8 * math.sin(_phase * 0.15) + _rng.nextDouble() * 1.2;

    final double newBoost = (newThrottle - 0.35) * 180;
    final double newCoolant = (_state.coolantC + (88 - _state.coolantC) * 0.01)
        .clamp(40.0, 110.0);
    final double newCabin = (_state.cabinC + (_targetCabin - _state.cabinC) * 0.02);
    final double newFuel = (_state.fuelPct - newSpeed * 0.000002).clamp(0.0, 1.0);
    final double newTrip = _state.tripKm + newSpeed / 3600 * 0.1;
    final double newOdo = _state.odometerKm + newSpeed / 3600 * 0.1;

    // Attitude (pitch/roll/yaw) — lightly correlated with steering + throttle
    // so the 4WD attitude indicator feels driven rather than random.
    final double newPitch = 6 * math.sin(_phase * 0.08) +
        (newThrottle - 0.3) * 4 -
        (newBrake * 8);
    final double newRoll = newSteer * 0.6 + 3 * math.sin(_phase * 0.11);
    final double newYaw = _state.yawDeg + newSteer * 0.02;
    final double newHeading = ((_state.headingDeg + newSteer * 0.01) % 360 + 360) % 360;
    final double newAlt = (_state.altitudeM + math.sin(_phase * 0.04) * 0.5)
        .clamp(-50.0, 1800.0);

    // Per-wheel speed with small slip when steering.
    final double slip = newSteer.abs() * 0.08;
    final double wFl = (newSpeed - slip).clamp(0.0, 250.0);
    final double wFr = (newSpeed + slip).clamp(0.0, 250.0);
    final double wRl = (newSpeed - slip * 0.6).clamp(0.0, 250.0);
    final double wRr = (newSpeed + slip * 0.6).clamp(0.0, 250.0);

    // TPMS: slow oscillation around a nominal pressure + temperature drift.
    final double ambientKpa = 220 + 4 * math.sin(_phase * 0.02);
    final double flK = (_state.tpmsFlKpa + (ambientKpa - _state.tpmsFlKpa) * 0.05)
        .clamp(140.0, 280.0);
    final double frK = (_state.tpmsFrKpa + (ambientKpa - _state.tpmsFrKpa) * 0.05)
        .clamp(140.0, 280.0);
    final double rlK = (_state.tpmsRlKpa + (ambientKpa + 2 - _state.tpmsRlKpa) * 0.05)
        .clamp(140.0, 280.0);
    final double rrK = (_state.tpmsRrKpa + (ambientKpa + 2 - _state.tpmsRrKpa) * 0.05)
        .clamp(140.0, 280.0);

    // Drift the GPS location a tiny bit so the map feels live.
    final double newLat = _state.latitude + math.sin(_phase * 0.03) * 0.00004;
    final double newLon = _state.longitude + math.cos(_phase * 0.03) * 0.00004;

    _state = _state.copyWith(
      speedKph: newSpeed,
      rpm: newRpm,
      throttlePct: newThrottle,
      brakePct: newBrake,
      steeringDeg: newSteer,
      coolantC: newCoolant,
      intakeC: 22 + newThrottle * 8,
      cabinC: newCabin,
      boostKpa: newBoost,
      fuelPct: newFuel,
      tripKm: newTrip,
      odometerKm: newOdo,
      voltage: 13.9 + 0.3 * math.sin(_phase * 0.2),
      pitchDeg: newPitch,
      rollDeg: newRoll,
      yawDeg: newYaw,
      headingDeg: newHeading,
      altitudeM: newAlt,
      wheelSpeedFlKph: wFl,
      wheelSpeedFrKph: wFr,
      wheelSpeedRlKph: wRl,
      wheelSpeedRrKph: wRr,
      tpmsFlKpa: flK,
      tpmsFrKpa: frK,
      tpmsRlKpa: rlK,
      tpmsRrKpa: rrK,
      latitude: newLat,
      longitude: newLon,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events.close();
    super.dispose();
  }
}
