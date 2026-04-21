import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/theme/aurora_theme.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: GlassCard(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Theme'),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: [
                        for (final m in AuroraThemeMode.values)
                          _ThemeSwatch(mode: m, selected: s.themeMode == m, onTap: () => s.setThemeMode(m)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader('Accent colour'),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: [
                        for (final sw in AccentPalette.swatches)
                          _AccentSwatch(
                            name: sw.$1,
                            color: sw.$2,
                            selected: s.accent.value == sw.$2.value,
                            onTap: () => s.setAccent(sw.$2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader('Display'),
                    Row(
                      children: [
                        const Icon(Icons.brightness_medium),
                        const SizedBox(width: 8),
                        const Text('Brightness'),
                        Expanded(
                          child: Slider(
                            value: s.brightness,
                            min: 0.2, max: 1.0,
                            onChanged: s.setBrightness,
                          ),
                        ),
                        Text('${(s.brightness * 100).round()}%'),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-dim at night'),
                      subtitle: const Text('Dim the display when headlights turn on'),
                      value: s.autoDim,
                      onChanged: s.setAutoDim,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show nav alongside music'),
                      value: s.navDuringMusic,
                      onChanged: s.setNavDuringMusic,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reduce motion'),
                      value: s.reduceMotion,
                      onChanged: s.setReduceMotion,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('GPS chip in status bar'),
                      value: s.showGpsInStatus,
                      onChanged: s.setShowGpsInStatus,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Metric units (km, °C)'),
                      subtitle: const Text('Turn off for mph, °F'),
                      value: s.useMetric,
                      onChanged: s.setUseMetric,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GlassCard(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader('Home screen widgets'),
                          ..._allHomeWidgets.map((w) {
                            final active = s.homeWidgets.contains(w.$1);
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(w.$3, color: active ? scheme.primary : null),
                              title: Text(w.$2),
                              value: active,
                              onChanged: (_) => s.toggleHomeWidget(w.$1),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Driver'),
                      TextFormField(
                        initialValue: s.driverName,
                        decoration: const InputDecoration(labelText: 'Name on greeting'),
                        onChanged: s.setDriverName,
                      ),
                      const SizedBox(height: 12),
                      const SectionHeader('Vehicle profile'),
                      DropdownButtonFormField<String>(
                        value: s.vehicleProfile,
                        items: const [
                          DropdownMenuItem(value: 'toyota_generic', child: Text('Toyota (generic)')),
                          DropdownMenuItem(value: 'toyota_camry', child: Text('Toyota Camry 2018+')),
                          DropdownMenuItem(value: 'toyota_rav4',  child: Text('Toyota RAV4 2019+')),
                          DropdownMenuItem(value: 'toyota_hilux', child: Text('Toyota Hilux 2016+')),
                          DropdownMenuItem(value: 'obd_only',     child: Text('Generic OBD-II only')),
                        ],
                        onChanged: (v) => v == null ? null : s.setVehicleProfile(v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GlassCard(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('About Aurora HUD'),
                    Text('Aurora HUD', style: Theme.of(context).textTheme.headlineSmall),
                    const Text('Version 0.1.0'),
                    const SizedBox(height: 10),
                    const Text(
                      'A Flutter-based IVI shell for aftermarket head units.\n\n'
                      'Runs on Linux desktop for design preview and on embedded '
                      'Linux (Rockchip RK3588, Raspberry Pi CM4) for real vehicle '
                      'installs. Apple CarPlay is provided via an MFi-licensed '
                      'wireless dongle (Carlinkit CPC200 or similar).',
                    ),
                    const SizedBox(height: 14),
                    const SectionHeader('Required components'),
                    const _BomLine('SBC', 'Rockchip RK3588 (Radxa Rock 5B) or Pi CM4'),
                    const _BomLine('Display', '10.1" 1280×800 capacitive touchscreen'),
                    const _BomLine('CAN adapter', 'Waveshare RS485-CAN-HAT or PiCAN2'),
                    const _BomLine('CarPlay dongle', 'Carlinkit CPC200-CCPA'),
                    const _BomLine('GPS', 'u-blox NEO-M9N on USB'),
                    const _BomLine('Audio', 'USB DAC + TPA3255 class-D amp'),
                    const _BomLine('Power', '12 V → 5 V / 3 A step-down with ignition sense'),
                    const SizedBox(height: 14),
                    Text(
                      'CarPlay licensing: Apple gates CarPlay behind the MFi '
                      'program. Aurora HUD does not ship a CarPlay receiver — '
                      'pair a licensed wireless dongle instead.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<(String, String, IconData)> _allHomeWidgets = [
    ('clock',     'Greeting',     Icons.waving_hand),
    ('next_turn', 'Next turn',    Icons.near_me),
    ('media',     'Now playing',  Icons.play_circle_filled),
    ('gauges',    'Drive gauges', Icons.speed),
    ('climate',   'Climate',      Icons.ac_unit),
    ('trip',      'Trip & odo',   Icons.timeline),
    ('weather',   'Weather',      Icons.wb_sunny),
  ];
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.mode, required this.selected, required this.onTap});
  final AuroraThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 136,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: mode.baseBackground,
          border: Border.all(
            color: selected ? mode.defaultAccent : Colors.white24,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: mode.defaultAccent.withOpacity(0.4), blurRadius: 20)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: mode.defaultAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(mode.label,
                    style: TextStyle(color: mode.isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [mode.defaultAccent.withOpacity(0.5), mode.defaultAccent]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({required this.name, required this.color, required this.selected, required this.onTap});
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 3 : 1,
            ),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14)],
          ),
        ),
      ),
    );
  }
}

class _BomLine extends StatelessWidget {
  const _BomLine(this.what, this.value);
  final String what;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(what,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
