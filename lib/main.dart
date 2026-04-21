import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/media/media_controller.dart';
import 'core/navigation/nav_controller.dart';
import 'core/settings/settings_controller.dart';
import 'core/vehicle/vehicle_bus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
        ChangeNotifierProvider<VehicleBus>(create: (_) => SimulatedVehicleBus()),
        ChangeNotifierProvider(create: (_) => MediaController()),
        ChangeNotifierProvider(create: (_) => NavController()),
      ],
      child: const AuroraApp(),
    ),
  );
}
