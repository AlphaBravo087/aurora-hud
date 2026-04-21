import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/media/media_controller.dart';
import '../../core/navigation/nav_controller.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/vehicle/vehicle_bus.dart';
import '../../core/vehicle/vehicle_state.dart';
import '../../widgets/gauge.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final ids = settings.homeWidgets;
    final tiles = [
      for (final id in ids)
        if (_tileFor(id) case final t?) t,
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        const gap = 16.0;
        const cellCount = 6;
        const pad = 12.0;
        final boardW = c.maxWidth - pad * 2;
        final cellW = (boardW - gap * (cellCount - 1)) / cellCount;
        final sized = <Widget>[];
        for (final t in tiles) {
          final w = cellW * t.cells + gap * (t.cells - 1);
          sized.add(SizedBox(width: w, height: t.height, child: t.child));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(pad),
          child: Wrap(spacing: gap, runSpacing: gap, children: sized),
        );
      },
    );
  }

  static _Tile? _tileFor(String id) {
    switch (id) {
      case 'clock':     return const _Tile(2, 260, _ClockTile());
      case 'next_turn': return const _Tile(2, 260, _NextTurnTile());
      case 'media':     return const _Tile(2, 260, _MediaTile());
      case 'gauges':    return const _Tile(4, 360, _MiniGaugesTile());
      case 'climate':   return const _Tile(2, 260, _ClimateTile());
      case 'trip':      return const _Tile(2, 260, _TripTile());
      case 'weather':   return const _Tile(2, 260, _WeatherTile());
    }
    return null;
  }
}

class _Tile {
  const _Tile(this.cells, this.height, this.child);
  final int cells;
  final double height;
  final Widget child;
}

// ----- Individual tiles --------------------------------------------------

class _ClockTile extends StatelessWidget {
  const _ClockTile();
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Greeting'),
          Text('Welcome, ${settings.driverName}.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Aurora HUD ready. '
            '${settings.useMetric ? 'Metric' : 'Imperial'} units, '
            '${settings.themeMode.label} theme.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          const Row(
            children: [
              AuroraChip(label: 'Aurora', icon: Icons.auto_awesome),
              SizedBox(width: 8),
              AuroraChip(label: 'v0.1'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextTurnTile extends StatelessWidget {
  const _NextTurnTile();
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final settings = context.watch<SettingsController>();
    final step = nav.nextStep;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            'Next turn',
            trailing: nav.route == null
                ? null
                : AuroraChip(
                    label: '${nav.eta.inMinutes} min',
                    icon: Icons.schedule,
                  ),
          ),
          if (step == null) ...[
            const SizedBox(height: 8),
            Text('No active route',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Open the Nav screen to start a demo route.',
                style: Theme.of(context).textTheme.bodySmall),
          ] else ...[
            Row(
              children: [
                Icon(_iconFor(step.maneuver.toString().split('.').last),
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.primary,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(step.secondary,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(nav.route!.destination,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              '${nav.distanceRemainingKm.toStringAsFixed(1)} ${settings.distUnit} remaining',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String m) {
    switch (m) {
      case 'left': return Icons.turn_left;
      case 'right': return Icons.turn_right;
      case 'slightLeft': return Icons.turn_slight_left;
      case 'slightRight': return Icons.turn_slight_right;
      case 'uturn': return Icons.u_turn_left;
      case 'roundabout': return Icons.roundabout_left;
      case 'arrive': return Icons.flag;
      default: return Icons.arrow_upward;
    }
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile();
  @override
  Widget build(BuildContext context) {
    final m = context.watch<MediaController>();
    final t = m.current;
    return GlassCard(
      tint: Color(t.artColor).withOpacity(0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Now playing'),
          Text(t.title,
              style: Theme.of(context).textTheme.headlineSmall!
                  .copyWith(color: Colors.white)),
          Text(t.artist,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: Colors.white70)),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: m.previous,
              ),
              IconButton(
                iconSize: 48,
                icon: Icon(
                  m.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: m.togglePlay,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: m.next,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniGaugesTile extends StatelessWidget {
  const _MiniGaugesTile();
  @override
  Widget build(BuildContext context) {
    final bus = context.watch<VehicleBus>();
    final settings = context.watch<SettingsController>();
    final v = bus.state;
    final speed = settings.useMetric ? v.speedKph : v.speedKph * 0.621371;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            'Drive',
            trailing: AuroraChip(label: v.gear.short, icon: Icons.commit),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CircularGauge(
                    value: speed,
                    max: settings.useMetric ? 220 : 140,
                    label: 'Speed',
                    unit: settings.speedUnit,
                    size: 150,
                  ),
                ),
                Expanded(
                  child: CircularGauge(
                    value: v.rpm.toDouble(),
                    max: 8000,
                    label: 'RPM',
                    unit: 'x1000',
                    caution: 6500,
                    danger: 7000,
                    size: 150,
                    formatter: (x) => (x / 1000).toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: CircularGauge(
                    value: settings.useMetric ? v.coolantC : v.coolantC * 9 / 5 + 32,
                    min: settings.useMetric ? 40 : 100,
                    max: settings.useMetric ? 120 : 250,
                    label: 'Coolant',
                    unit: settings.tempUnit,
                    caution: settings.useMetric ? 100 : 212,
                    danger: settings.useMetric ? 110 : 230,
                    size: 150,
                  ),
                ),
              ],
            ),
          ),
          BarGauge(
            label: 'Throttle',
            value: v.throttlePct * 100,
            min: 0, max: 100,
            accent: Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          BarGauge(
            label: 'Fuel',
            value: v.fuelPct * 100,
            min: 0, max: 100,
            accent: Colors.amberAccent,
          ),
        ],
      ),
    );
  }
}

class _ClimateTile extends StatelessWidget {
  const _ClimateTile();
  @override
  Widget build(BuildContext context) {
    final bus = context.watch<VehicleBus>();
    final settings = context.watch<SettingsController>();
    final c = bus.state;

    String fmt(double v) => settings.useMetric
        ? '${v.toStringAsFixed(0)}°C'
        : '${(v * 9 / 5 + 32).toStringAsFixed(0)}°F';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Climate'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cabin',
                        style: Theme.of(context).textTheme.labelMedium),
                    Text(fmt(c.cabinC),
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outside',
                        style: Theme.of(context).textTheme.labelMedium),
                    Text(fmt(c.ambientC),
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AuroraChip(label: 'A/C on', icon: Icons.ac_unit),
              AuroraChip(label: 'Auto fan', icon: Icons.air),
              AuroraChip(label: 'Face + feet', icon: Icons.air_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile();
  @override
  Widget build(BuildContext context) {
    final bus = context.watch<VehicleBus>();
    final settings = context.watch<SettingsController>();
    final v = bus.state;
    final trip = settings.useMetric ? v.tripKm : v.tripKm * 0.621371;
    final odo = settings.useMetric ? v.odometerKm : v.odometerKm * 0.621371;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Trip computer'),
          _Stat('Trip', '${trip.toStringAsFixed(1)} ${settings.distUnit}'),
          _Stat('Odometer', '${odo.toStringAsFixed(0)} ${settings.distUnit}'),
          _Stat('Battery', '${v.voltage.toStringAsFixed(1)} V'),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v.fuelPct.clamp(0.0, 1.0),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text('Fuel ${(v.fuelPct * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _WeatherTile extends StatelessWidget {
  const _WeatherTile();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Weather'),
          Row(
            children: [
              Icon(Icons.wb_sunny,
                  size: 54, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('23°C',
                      style: Theme.of(context).textTheme.displaySmall),
                  Text('Partly cloudy',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Humidity 54% · Wind 14 km/h · UV 6',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
        ],
      ),
    );
  }
}
