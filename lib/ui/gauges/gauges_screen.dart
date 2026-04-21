import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/vehicle/vehicle_bus.dart';
import '../../core/vehicle/vehicle_state.dart';
import '../../widgets/gauge.dart';
import '../../widgets/glass_card.dart';

class GaugesScreen extends StatelessWidget {
  const GaugesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.watch<VehicleBus>().state;
    final s = context.watch<SettingsController>();
    final speed = s.useMetric ? v.speedKph : v.speedKph * 0.6213711922;
    final coolant = s.useMetric ? v.coolantC : (v.coolantC * 9 / 5 + 32);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BigClusterRow(speed: speed, rpm: v.rpm, gear: v.gear, units: s),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Powertrain'),
                      BarGauge(
                        value: v.throttlePct * 100,
                        min: 0, max: 100, label: 'Throttle',
                        valueText: '${(v.throttlePct * 100).round()}%',
                      ),
                      const SizedBox(height: 14),
                      BarGauge(
                        value: v.brakePct * 100,
                        min: 0, max: 100, label: 'Brake',
                        valueText: '${(v.brakePct * 100).round()}%',
                        accent: const Color(0xFFFF5470),
                      ),
                      const SizedBox(height: 14),
                      BarGauge(
                        value: v.boostKpa,
                        min: -40, max: 200, label: 'Boost',
                        valueText: '${v.boostKpa.toStringAsFixed(0)} kPa',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Thermals / Electrical'),
                      BarGauge(
                        value: coolant,
                        min: s.useMetric ? 40 : 100,
                        max: s.useMetric ? 110 : 230,
                        label: 'Coolant',
                        valueText: '${coolant.toStringAsFixed(0)} ${s.tempUnit}',
                      ),
                      const SizedBox(height: 14),
                      BarGauge(
                        value: v.intakeC,
                        min: 0, max: 60, label: 'Intake Air',
                        valueText: '${v.intakeC.toStringAsFixed(0)} °C',
                      ),
                      const SizedBox(height: 14),
                      BarGauge(
                        value: v.voltage,
                        min: 11, max: 15, label: 'Battery',
                        valueText: '${v.voltage.toStringAsFixed(1)} V',
                        accent: const Color(0xFFFFB020),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigClusterRow extends StatelessWidget {
  const _BigClusterRow({required this.speed, required this.rpm, required this.gear, required this.units});
  final double speed;
  final double rpm;
  final Gear gear;
  final SettingsController units;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircularGauge(
            value: rpm,
            max: 8000,
            label: 'RPM',
            unit: 'x1000',
            caution: 6000,
            danger: 7000,
            size: 280,
            formatter: (x) => (x / 1000).toStringAsFixed(1),
          ),
          Column(
            children: [
              Text(speed.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontSize: 180,
                        height: 1.0,
                        fontWeight: FontWeight.w200,
                        color: Theme.of(context).colorScheme.primary,
                      )),
              Text(units.speedUnit,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                ),
                child: Text('Gear ${gear.short}',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          CircularGauge(
            value: context.watch<VehicleBus>().state.coolantC,
            max: 110,
            caution: 95,
            danger: 104,
            label: 'Coolant',
            unit: '°C',
            size: 280,
          ),
        ],
      ),
    );
  }
}
