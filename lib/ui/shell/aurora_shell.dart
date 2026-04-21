import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../carplay/carplay_screen.dart';
import '../climate/climate_screen.dart';
import '../gauges/gauges_screen.dart';
import '../home/home_screen.dart';
import '../media/media_screen.dart';
import '../navigation/nav_screen.dart';
import '../settings/settings_screen.dart';
import 'nav_rail.dart';
import 'status_bar.dart';

class AuroraShell extends StatefulWidget {
  const AuroraShell({super.key});

  @override
  State<AuroraShell> createState() => _AuroraShellState();
}

class _AuroraShellState extends State<AuroraShell> {
  int _selected = 0;

  final List<_Section> _sections = const [
    _Section('Home',     Icons.home_filled,            HomeScreen()),
    _Section('Drive',    Icons.speed,                  GaugesScreen()),
    _Section('Media',    Icons.play_circle_filled,     MediaScreen()),
    _Section('Nav',      Icons.near_me,                NavScreen()),
    _Section('Climate',  Icons.ac_unit,                ClimateScreen()),
    _Section('CarPlay',  Icons.phone_iphone,           CarPlayScreen()),
    _Section('Settings', Icons.settings_suggest,       SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final brightness = settings.brightness;
    return Opacity(
      opacity: brightness,
      child: Scaffold(
        body: Column(
          children: [
            const StatusBar(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuroraNavRail(
                    destinations: [
                      for (final s in _sections) NavDestination(s.label, s.icon),
                    ],
                    selected: _selected,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 20, 20),
                      child: _sections[_selected].screen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}
