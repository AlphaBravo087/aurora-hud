import 'package:aurora_hud/core/media/media_controller.dart';
import 'package:aurora_hud/core/navigation/nav_controller.dart';
import 'package:aurora_hud/core/settings/settings_controller.dart';
import 'package:aurora_hud/core/theme/aurora_theme.dart';
import 'package:aurora_hud/core/vehicle/vehicle_bus.dart';
import 'package:aurora_hud/core/vehicle/vehicle_state.dart';
import 'package:aurora_hud/ui/four_wd/four_wd_screen.dart';
import 'package:aurora_hud/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every preset theme declares a non-null accent', () {
    for (final mode in AuroraThemeMode.values) {
      expect(mode.defaultAccent.alpha, 0xFF);
    }
  });

  test('Accent palette exposes a non-empty swatch list', () {
    expect(AccentPalette.swatches, isNotEmpty);
    for (final s in AccentPalette.swatches) {
      expect(s.$1.isNotEmpty, isTrue);
    }
  });

  test('SettingsController round-trips values through SharedPreferences',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsController(prefs);

    expect(s.themeMode, AuroraThemeMode.midnight);
    expect(s.useMetric, isFalse);

    s.setThemeMode(AuroraThemeMode.oled);
    s.setUseMetric(true);
    s.setDriverName('Bosco');
    s.setBrightness(0.7);

    final reloaded = SettingsController(prefs);
    expect(reloaded.themeMode, AuroraThemeMode.oled);
    expect(reloaded.useMetric, isTrue);
    expect(reloaded.driverName, 'Bosco');
    expect(reloaded.brightness, closeTo(0.7, 1e-9));
  });

  test('Toggling a home widget id adds or removes it from the list', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsController(prefs);

    expect(s.homeWidgets.contains('weather'), isFalse);
    s.toggleHomeWidget('weather');
    expect(s.homeWidgets.contains('weather'), isTrue);
    s.toggleHomeWidget('weather');
    expect(s.homeWidgets.contains('weather'), isFalse);
  });

  test('SimulatedVehicleBus produces varying state over time', () async {
    final bus = SimulatedVehicleBus();
    final first = bus.state;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final later = bus.state;
    expect(later.speedKph, isNot(first.speedKph));
    bus.dispose();
  });

  test('MediaController cycles through tracks', () {
    final m = MediaController();
    final initial = m.current;
    m.next();
    expect(m.current, isNot(initial));
    m.previous();
    expect(m.current, initial);
    m.dispose();
  });

  testWidgets('HomeScreen renders all default tiles', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(prefs);
    final bus = SimulatedVehicleBus();
    final media = MediaController();
    final nav = NavController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settings),
          ChangeNotifierProvider<VehicleBus>.value(value: bus),
          ChangeNotifierProvider<MediaController>.value(value: media),
          ChangeNotifierProvider<NavController>.value(value: nav),
        ],
        child: MaterialApp(
          theme: AuroraTheme.build(AuroraThemeMode.midnight),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('GREETING'), findsOneWidget);
    expect(find.text('NEXT TURN'), findsOneWidget);
    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('DRIVE'), findsOneWidget);
    expect(find.text('CLIMATE'), findsOneWidget);
    expect(find.text('TRIP COMPUTER'), findsOneWidget);

    bus.dispose();
    media.dispose();
    nav.dispose();
  });

  test('NavController starts and clears demo route', () {
    final n = NavController();
    expect(n.route, isNull);
    n.startDemoRoute();
    expect(n.route, isNotNull);
    expect(n.route!.steps, isNotEmpty);
    n.clearRoute();
    expect(n.route, isNull);
    n.dispose();
  });

  test('SimulatedVehicleBus exposes 4WD controls that update state', () {
    final bus = SimulatedVehicleBus();
    expect(bus.state.transferCase, TransferCaseMode.twoHi);
    expect(bus.state.rearDiffLocked, isFalse);
    bus.setTransferCase(TransferCaseMode.fourLo);
    bus.setRearDiffLocked(true);
    bus.setHillDescentAssist(true);
    expect(bus.state.transferCase, TransferCaseMode.fourLo);
    expect(bus.state.rearDiffLocked, isTrue);
    expect(bus.state.hillDescentAssist, isTrue);
    bus.dispose();
  });

  test('SimulatedVehicleBus updates pitch/roll/heading/altitude on tick',
      () async {
    final bus = SimulatedVehicleBus();
    final first = bus.state;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final later = bus.state;
    // At least one of the attitude channels must have moved.
    final moved = later.pitchDeg != first.pitchDeg ||
        later.rollDeg != first.rollDeg ||
        later.headingDeg != first.headingDeg ||
        later.altitudeM != first.altitudeM ||
        later.latitude != first.latitude;
    expect(moved, isTrue);
    bus.dispose();
  });

  testWidgets('FourWheelDriveScreen toggles diff-lock state via tap',
      (tester) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(prefs);
    final bus = SimulatedVehicleBus();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settings),
          ChangeNotifierProvider<VehicleBus>.value(value: bus),
        ],
        child: MaterialApp(
          theme: AuroraTheme.build(AuroraThemeMode.midnight),
          home: const Scaffold(body: FourWheelDriveScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ATTITUDE'), findsOneWidget);
    expect(find.text('DRIVETRAIN'), findsOneWidget);
    expect(find.text('TYRE PRESSURE'), findsOneWidget);
    expect(find.text('COMPASS'), findsOneWidget);

    // Front diff is off initially — toggle it on by tapping the 'F' pill.
    expect(bus.state.frontDiffLocked, isFalse);
    await tester.tap(find.text('F'));
    await tester.pump();
    expect(bus.state.frontDiffLocked, isTrue);

    bus.dispose();
  });
}
