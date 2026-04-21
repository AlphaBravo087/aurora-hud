/// Immutable snapshot of the vehicle's live state.
///
/// Populated by a [VehicleBus] implementation (simulated on desktop, real
/// CAN/OBD-II on a car install).
class VehicleState {
  const VehicleState({
    this.speedKph = 0,
    this.rpm = 0,
    this.throttlePct = 0,
    this.brakePct = 0,
    this.steeringDeg = 0,
    this.coolantC = 80,
    this.intakeC = 25,
    this.ambientC = 22,
    this.cabinC = 22,
    this.fuelPct = 0.65,
    this.boostKpa = 0,
    this.voltage = 13.8,
    this.odometerKm = 0,
    this.tripKm = 0,
    this.gear = Gear.drive,
    this.ignition = IgnitionState.running,
    this.leftBlinker = false,
    this.rightBlinker = false,
    this.headlights = HeadlightState.auto,
    this.reverseCamera = false,
    this.doorsOpen = const [],
    this.sourceName = 'Simulated',
  });

  final double speedKph;
  final double rpm;
  final double throttlePct; // 0..1
  final double brakePct; // 0..1
  final double steeringDeg; // negative = left
  final double coolantC;
  final double intakeC;
  final double ambientC;
  final double cabinC;
  final double fuelPct; // 0..1
  final double boostKpa; // can be negative for vacuum
  final double voltage;
  final double odometerKm;
  final double tripKm;
  final Gear gear;
  final IgnitionState ignition;
  final bool leftBlinker;
  final bool rightBlinker;
  final HeadlightState headlights;
  final bool reverseCamera;
  final List<String> doorsOpen;
  final String sourceName;

  VehicleState copyWith({
    double? speedKph,
    double? rpm,
    double? throttlePct,
    double? brakePct,
    double? steeringDeg,
    double? coolantC,
    double? intakeC,
    double? ambientC,
    double? cabinC,
    double? fuelPct,
    double? boostKpa,
    double? voltage,
    double? odometerKm,
    double? tripKm,
    Gear? gear,
    IgnitionState? ignition,
    bool? leftBlinker,
    bool? rightBlinker,
    HeadlightState? headlights,
    bool? reverseCamera,
    List<String>? doorsOpen,
    String? sourceName,
  }) {
    return VehicleState(
      speedKph: speedKph ?? this.speedKph,
      rpm: rpm ?? this.rpm,
      throttlePct: throttlePct ?? this.throttlePct,
      brakePct: brakePct ?? this.brakePct,
      steeringDeg: steeringDeg ?? this.steeringDeg,
      coolantC: coolantC ?? this.coolantC,
      intakeC: intakeC ?? this.intakeC,
      ambientC: ambientC ?? this.ambientC,
      cabinC: cabinC ?? this.cabinC,
      fuelPct: fuelPct ?? this.fuelPct,
      boostKpa: boostKpa ?? this.boostKpa,
      voltage: voltage ?? this.voltage,
      odometerKm: odometerKm ?? this.odometerKm,
      tripKm: tripKm ?? this.tripKm,
      gear: gear ?? this.gear,
      ignition: ignition ?? this.ignition,
      leftBlinker: leftBlinker ?? this.leftBlinker,
      rightBlinker: rightBlinker ?? this.rightBlinker,
      headlights: headlights ?? this.headlights,
      reverseCamera: reverseCamera ?? this.reverseCamera,
      doorsOpen: doorsOpen ?? this.doorsOpen,
      sourceName: sourceName ?? this.sourceName,
    );
  }
}

enum Gear { park, reverse, neutral, drive, sport, manual1, manual2, manual3, manual4, manual5, manual6 }

extension GearLabel on Gear {
  String get short {
    switch (this) {
      case Gear.park: return 'P';
      case Gear.reverse: return 'R';
      case Gear.neutral: return 'N';
      case Gear.drive: return 'D';
      case Gear.sport: return 'S';
      case Gear.manual1: return 'M1';
      case Gear.manual2: return 'M2';
      case Gear.manual3: return 'M3';
      case Gear.manual4: return 'M4';
      case Gear.manual5: return 'M5';
      case Gear.manual6: return 'M6';
    }
  }
}

enum IgnitionState { off, accessory, ignition, running, cranking }

enum HeadlightState { off, parking, low, high, auto }
