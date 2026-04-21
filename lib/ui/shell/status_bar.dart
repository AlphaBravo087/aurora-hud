import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/vehicle/vehicle_bus.dart';
import '../../core/vehicle/vehicle_state.dart';
import '../../widgets/glass_card.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  late Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final bus = context.watch<VehicleBus>();
    final state = bus.state;

    final time = DateFormat.jm().format(_now);
    final date = DateFormat('EEE d MMM').format(_now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 4),
      child: Row(
        children: [
          Text(time,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
          const SizedBox(width: 12),
          Text(date, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 16),
          Text('Hi, ${s.driverName}',
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          AuroraChip(
            label: '${state.ambientC.toStringAsFixed(0)}${s.tempUnit.replaceAll('°', '°')}',
            icon: Icons.thermostat,
          ),
          const SizedBox(width: 8),
          AuroraChip(
            label: state.ignition == IgnitionState.running ? 'Running' : 'Ready',
            icon: Icons.key,
            color: state.ignition == IgnitionState.running ? const Color(0xFF00E5A0) : null,
          ),
          if (s.showGpsInStatus) ...[
            const SizedBox(width: 8),
            const AuroraChip(label: 'GPS', icon: Icons.gps_fixed),
          ],
          const SizedBox(width: 8),
          const AuroraChip(label: 'Bluetooth', icon: Icons.bluetooth),
        ],
      ),
    );
  }
}
