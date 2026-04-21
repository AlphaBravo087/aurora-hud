/// Toyota CAN bus profile starter pack.
///
/// These IDs are drawn from community reverse-engineering of Toyota vehicles
/// (commaai OpenDBC, TunerPro, etc.) and are **best-effort — verify against
/// your specific VIN before sending any frames.**  Aurora HUD treats this
/// profile as a *read-mostly* map: steering-wheel button presses, HVAC state,
/// gear position, and blinkers are read; only non-safety-critical frames
/// (e.g. cabin fan boost, dash brightness) may be written by the user.
///
/// Reference IDs are hex on the vehicle's powertrain or body CAN bus.
class ToyotaCanProfile {
  static const String id = 'toyota_generic';
  static const String displayName = 'Toyota (generic)';

  /// Some common frames. Real deployments should override with a DBC.
  static const Map<int, String> frames = {
    0x025: 'Steering angle',
    0x0B4: 'Wheel speeds',
    0x1C4: 'Engine torque / RPM',
    0x1D2: 'Powertrain 1 (gear, brake)',
    0x224: 'Brake pressure',
    0x260: 'Steering wheel buttons',
    0x2C1: 'HVAC status',
    0x3B7: 'Door ajar / seatbelts',
    0x3BC: 'Gear selector',
    0x620: 'Odometer',
    0x622: 'Ambient temperature',
  };

  /// Bit masks within frame 0x260 (steering-wheel button bus) for the buttons
  /// Aurora HUD reacts to. These happen to match Camry / Corolla / RAV4 from
  /// roughly 2016+; older models differ and need a VIN-specific profile.
  static const Map<String, int> steeringButtonMask = {
    'volume_up':     0x01,
    'volume_down':   0x02,
    'mode':          0x04,
    'next_track':    0x08,
    'prev_track':    0x10,
    'phone_answer':  0x20,
    'phone_hangup':  0x40,
    'voice':         0x80,
  };
}
