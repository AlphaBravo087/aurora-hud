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
    this.pitchDeg = 0,
    this.rollDeg = 0,
    this.yawDeg = 0,
    this.headingDeg = 0,
    this.altitudeM = 0,
    this.transferCase = TransferCaseMode.twoHi,
    this.frontDiffLocked = false,
    this.centerDiffLocked = false,
    this.rearDiffLocked = false,
    this.hillDescentAssist = false,
    this.crawlControl = false,
    this.tpmsFlKpa = 220,
    this.tpmsFrKpa = 220,
    this.tpmsRlKpa = 220,
    this.tpmsRrKpa = 220,
    this.wheelSpeedFlKph = 0,
    this.wheelSpeedFrKph = 0,
    this.wheelSpeedRlKph = 0,
    this.wheelSpeedRrKph = 0,
    this.latitude = -12.4634,
    this.longitude = 130.8456,
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

  // Off-road / 4WD telemetry.
  final double pitchDeg; // + = nose up
  final double rollDeg; // + = right side down
  final double yawDeg;
  final double headingDeg; // 0..360, compass heading
  final double altitudeM;
  final TransferCaseMode transferCase;
  final bool frontDiffLocked;
  final bool centerDiffLocked;
  final bool rearDiffLocked;
  final bool hillDescentAssist;
  final bool crawlControl;
  final double tpmsFlKpa;
  final double tpmsFrKpa;
  final double tpmsRlKpa;
  final double tpmsRrKpa;
  final double wheelSpeedFlKph;
  final double wheelSpeedFrKph;
  final double wheelSpeedRlKph;
  final double wheelSpeedRrKph;

  // GPS (used by the map screen).
  final double latitude;
  final double longitude;

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
    double? pitchDeg,
    double? rollDeg,
    double? yawDeg,
    double? headingDeg,
    double? altitudeM,
    TransferCaseMode? transferCase,
    bool? frontDiffLocked,
    bool? centerDiffLocked,
    bool? rearDiffLocked,
    bool? hillDescentAssist,
    bool? crawlControl,
    double? tpmsFlKpa,
    double? tpmsFrKpa,
    double? tpmsRlKpa,
    double? tpmsRrKpa,
    double? wheelSpeedFlKph,
    double? wheelSpeedFrKph,
    double? wheelSpeedRlKph,
    double? wheelSpeedRrKph,
    double? latitude,
    double? longitude,
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
      pitchDeg: pitchDeg ?? this.pitchDeg,
      rollDeg: rollDeg ?? this.rollDeg,
      yawDeg: yawDeg ?? this.yawDeg,
      headingDeg: headingDeg ?? this.headingDeg,
      altitudeM: altitudeM ?? this.altitudeM,
      transferCase: transferCase ?? this.transferCase,
      frontDiffLocked: frontDiffLocked ?? this.frontDiffLocked,
      centerDiffLocked: centerDiffLocked ?? this.centerDiffLocked,
      rearDiffLocked: rearDiffLocked ?? this.rearDiffLocked,
      hillDescentAssist: hillDescentAssist ?? this.hillDescentAssist,
      crawlControl: crawlControl ?? this.crawlControl,
      tpmsFlKpa: tpmsFlKpa ?? this.tpmsFlKpa,
      tpmsFrKpa: tpmsFrKpa ?? this.tpmsFrKpa,
      tpmsRlKpa: tpmsRlKpa ?? this.tpmsRlKpa,
      tpmsRrKpa: tpmsRrKpa ?? this.tpmsRrKpa,
      wheelSpeedFlKph: wheelSpeedFlKph ?? this.wheelSpeedFlKph,
      wheelSpeedFrKph: wheelSpeedFrKph ?? this.wheelSpeedFrKph,
      wheelSpeedRlKph: wheelSpeedRlKph ?? this.wheelSpeedRlKph,
      wheelSpeedRrKph: wheelSpeedRrKph ?? this.wheelSpeedRrKph,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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

/// Transfer case modes for part-time / full-time 4WD systems.
enum TransferCaseMode { twoHi, fourAuto, fourHi, fourLo, neutral }

extension TransferCaseLabel on TransferCaseMode {
  String get short {
    switch (this) {
      case TransferCaseMode.twoHi: return '2H';
      case TransferCaseMode.fourAuto: return '4A';
      case TransferCaseMode.fourHi: return '4H';
      case TransferCaseMode.fourLo: return '4L';
      case TransferCaseMode.neutral: return 'N';
    }
  }

  String get long {
    switch (this) {
      case TransferCaseMode.twoHi: return '2-Hi  (2WD)';
      case TransferCaseMode.fourAuto: return '4-Auto';
      case TransferCaseMode.fourHi: return '4-Hi  (locked)';
      case TransferCaseMode.fourLo: return '4-Lo  (crawl)';
      case TransferCaseMode.neutral: return 'Neutral';
    }
  }
}
