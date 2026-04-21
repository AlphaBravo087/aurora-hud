import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/vehicle/vehicle_bus.dart';
import '../../widgets/glass_card.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  double _driverTarget = 22;
  double _passengerTarget = 22;
  double _fan = 4;
  bool _ac = true;
  bool _auto = true;
  bool _recirc = false;
  bool _rear = false;
  bool _heatedDriver = false;
  bool _heatedPassenger = false;
  _Vent _vent = _Vent.faceFeet;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final v = context.watch<VehicleBus>().state;
    final cabin = s.useMetric ? v.cabinC : (v.cabinC * 9 / 5 + 32);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _ZoneCard(
                    title: 'Driver',
                    target: _driverTarget,
                    heated: _heatedDriver,
                    useMetric: s.useMetric,
                    onChange: (v) => setState(() => _driverTarget = v),
                    onHeatedChange: (v) => setState(() => _heatedDriver = v),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _ZoneCard(
                    title: 'Passenger',
                    target: _passengerTarget,
                    heated: _heatedPassenger,
                    useMetric: s.useMetric,
                    onChange: (v) => setState(() => _passengerTarget = v),
                    onHeatedChange: (v) => setState(() => _heatedPassenger = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SectionHeader('Cabin'),
                      const Spacer(),
                      Text('Currently ${cabin.toStringAsFixed(1)}${s.tempUnit}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.ac_unit, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fan speed', style: Theme.of(context).textTheme.labelMedium),
                            Slider(
                              value: _fan,
                              min: 0, max: 7, divisions: 7,
                              label: _fan.round().toString(),
                              onChanged: (v) => setState(() => _fan = v),
                            ),
                          ],
                        ),
                      ),
                      Text(_fan.round().toString(),
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Toggle(label: 'A/C', icon: Icons.ac_unit, value: _ac, onChanged: (v) => setState(() => _ac = v)),
                      _Toggle(label: 'Auto', icon: Icons.auto_mode, value: _auto, onChanged: (v) => setState(() => _auto = v)),
                      _Toggle(label: 'Recirculate', icon: Icons.loop, value: _recirc, onChanged: (v) => setState(() => _recirc = v)),
                      _Toggle(label: 'Rear defog', icon: Icons.grid_on, value: _rear, onChanged: (v) => setState(() => _rear = v)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('VENT DIRECTION', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<_Vent>(
                    segments: const [
                      ButtonSegment(value: _Vent.face, label: Text('Face'), icon: Icon(Icons.face)),
                      ButtonSegment(value: _Vent.faceFeet, label: Text('Face + Feet'), icon: Icon(Icons.swap_vert)),
                      ButtonSegment(value: _Vent.feet, label: Text('Feet'), icon: Icon(Icons.airline_seat_legroom_normal)),
                      ButtonSegment(value: _Vent.feetDefog, label: Text('Feet + Defog'), icon: Icon(Icons.ac_unit)),
                      ButtonSegment(value: _Vent.defog, label: Text('Defog'), icon: Icon(Icons.blur_on)),
                    ],
                    selected: {_vent},
                    onSelectionChanged: (s) => setState(() => _vent = s.first),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Vent { face, faceFeet, feet, feetDefog, defog }

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.title,
    required this.target,
    required this.heated,
    required this.useMetric,
    required this.onChange,
    required this.onHeatedChange,
  });

  final String title;
  final double target; // always stored in celsius
  final bool heated;
  final bool useMetric;
  final ValueChanged<double> onChange;
  final ValueChanged<bool> onHeatedChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = useMetric ? target : (target * 9 / 5 + 32);
    const minC = 16.0;
    const maxC = 30.0;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionHeader(title),
              const Spacer(),
              _Toggle(
                  label: 'Heated',
                  icon: Icons.chair,
                  value: heated,
                  onChanged: onHeatedChange),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(display.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontWeight: FontWeight.w200,
                        color: scheme.primary,
                      )),
              const SizedBox(width: 4),
              Text(useMetric ? '°C' : '°F',
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              IconButton.outlined(
                onPressed: target > minC
                    ? () => onChange((target - 0.5).clamp(minC, maxC))
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  value: target,
                  min: minC, max: maxC, divisions: (maxC - minC).round() * 2,
                  onChanged: onChange,
                ),
              ),
              IconButton.outlined(
                onPressed: target < maxC
                    ? () => onChange((target + 0.5).clamp(minC, maxC))
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.icon, required this.value, required this.onChanged});
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? scheme.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? scheme.primary.withOpacity(0.5) : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: value ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: value ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
