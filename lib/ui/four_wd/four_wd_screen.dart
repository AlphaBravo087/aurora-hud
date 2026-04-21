import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/vehicle/vehicle_bus.dart';
import '../../core/vehicle/vehicle_state.dart';
import '../../widgets/glass_card.dart';

/// The off-road / 4WD dashboard. Groups the attitude indicator, transfer case
/// selector, diff locks, traction aids, TPMS, per-wheel speeds and a compass.
class FourWheelDriveScreen extends StatelessWidget {
  const FourWheelDriveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bus = context.watch<VehicleBus>();
    final st = bus.state;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(
                          'Attitude',
                          trailing: AuroraChip(
                            label: 'LIVE',
                            icon: Icons.explore,
                            color: accent,
                          ),
                        ),
                        Expanded(
                          child: AttitudeIndicator(
                            pitchDeg: st.pitchDeg,
                            rollDeg: st.rollDeg,
                            accent: accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _AttitudeReadouts(state: st),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader('Drivetrain'),
                        _TransferCaseSelector(
                          current: st.transferCase,
                          onSelect: bus.setTransferCase,
                          accent: accent,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _DiffLockDiagram(
                            state: st,
                            onFront: bus.setFrontDiffLocked,
                            onCenter: bus.setCenterDiffLocked,
                            onRear: bus.setRearDiffLocked,
                            accent: accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _TractionAids(
                          state: st,
                          onHillDescent: bus.setHillDescentAssist,
                          onCrawl: bus.setCrawlControl,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader('Tyre pressure'),
                        Expanded(child: _TpmsDiagram(state: st)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader('Wheel slip'),
                        Expanded(child: _WheelSpeeds(state: st)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader('Compass'),
                        Expanded(
                          child: _Compass(
                            headingDeg: st.headingDeg,
                            accent: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Attitude indicator
// =====================================================================

class AttitudeIndicator extends StatelessWidget {
  const AttitudeIndicator({
    super.key,
    required this.pitchDeg,
    required this.rollDeg,
    required this.accent,
  });

  final double pitchDeg;
  final double rollDeg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _AttitudePainter(
                pitchDeg: pitchDeg,
                rollDeg: rollDeg,
                accent: accent,
                onSurface: Theme.of(context).colorScheme.onSurface,
                outline: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttitudePainter extends CustomPainter {
  _AttitudePainter({
    required this.pitchDeg,
    required this.rollDeg,
    required this.accent,
    required this.onSurface,
    required this.outline,
  });

  final double pitchDeg;
  final double rollDeg;
  final Color accent;
  final Color onSurface;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Outer bezel.
    final bezel = Paint()
      ..color = outline.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, bezel);

    // Clip circle for the rotating artificial horizon.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2)));
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rollDeg * math.pi / 180);

    // Sky and ground halves, offset vertically by pitch.
    final pitchPx = pitchDeg * (radius / 30); // 30° across half the circle
    final sky = Paint()..color = const Color(0xFF2A5C8A);
    final ground = Paint()..color = const Color(0xFF5A3A1E);
    canvas.drawRect(
      Rect.fromLTWH(-radius * 2, -radius * 2 + pitchPx, radius * 4, radius * 2),
      sky,
    );
    canvas.drawRect(
      Rect.fromLTWH(-radius * 2, pitchPx, radius * 4, radius * 2),
      ground,
    );

    // Horizon line.
    final horizon = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(-radius * 2, pitchPx), Offset(radius * 2, pitchPx), horizon);

    // Pitch ladder.
    final ladder = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1;
    const ts = TextStyle(color: Colors.white70, fontSize: 9);
    for (int d = -30; d <= 30; d += 10) {
      if (d == 0) continue;
      final y = pitchPx - d * (radius / 30);
      final half = d.abs() >= 20 ? 14.0 : 22.0;
      canvas.drawLine(Offset(-half, y), Offset(half, y), ladder);
      final tp = TextPainter(
        text: TextSpan(text: '$d', style: ts),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(half + 2, y - 5));
    }

    canvas.restore();

    // Fixed aircraft-style reticle + wings.
    final retic = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius * 0.45, center.dy),
      Offset(center.dx - radius * 0.12, center.dy),
      retic,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.12, center.dy),
      Offset(center.dx + radius * 0.45, center.dy),
      retic,
    );
    canvas.drawCircle(center, 3, Paint()..color = accent);

    // Roll tick marks around the top arc.
    final rollTick = Paint()
      ..color = onSurface.withOpacity(0.6)
      ..strokeWidth = 2;
    for (int d = -60; d <= 60; d += 15) {
      final a = -math.pi / 2 + d * math.pi / 180;
      final p1 = Offset(
        center.dx + math.cos(a) * (radius - 2),
        center.dy + math.sin(a) * (radius - 2),
      );
      final p2 = Offset(
        center.dx + math.cos(a) * (radius - (d % 30 == 0 ? 12 : 7)),
        center.dy + math.sin(a) * (radius - (d % 30 == 0 ? 12 : 7)),
      );
      canvas.drawLine(p1, p2, rollTick);
    }

    // Roll pointer (rotates with aircraft).
    final tipAngle = -math.pi / 2 + rollDeg * math.pi / 180;
    final tip = Offset(
      center.dx + math.cos(tipAngle) * (radius - 4),
      center.dy + math.sin(tipAngle) * (radius - 4),
    );
    final tri = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        center.dx + math.cos(tipAngle + 0.06) * (radius - 16),
        center.dy + math.sin(tipAngle + 0.06) * (radius - 16),
      )
      ..lineTo(
        center.dx + math.cos(tipAngle - 0.06) * (radius - 16),
        center.dy + math.sin(tipAngle - 0.06) * (radius - 16),
      )
      ..close();
    canvas.drawPath(tri, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _AttitudePainter old) =>
      old.pitchDeg != pitchDeg ||
      old.rollDeg != rollDeg ||
      old.accent != accent;
}

class _AttitudeReadouts extends StatelessWidget {
  const _AttitudeReadouts({required this.state});
  final VehicleState state;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final alt = s.useMetric ? state.altitudeM : state.altitudeM * 3.2808;
    final altUnit = s.useMetric ? 'm' : 'ft';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Readout('Pitch', '${state.pitchDeg.toStringAsFixed(1)}°'),
        _Readout('Roll', '${state.rollDeg.toStringAsFixed(1)}°'),
        _Readout('Altitude', '${alt.toStringAsFixed(0)} $altUnit'),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: tt.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: tt.titleLarge),
      ],
    );
  }
}

// =====================================================================
// Transfer case selector + diff lock diagram
// =====================================================================

class _TransferCaseSelector extends StatelessWidget {
  const _TransferCaseSelector({
    required this.current,
    required this.onSelect,
    required this.accent,
  });

  final TransferCaseMode current;
  final ValueChanged<TransferCaseMode> onSelect;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransferCaseMode>(
      segments: [
        for (final m in TransferCaseMode.values)
          ButtonSegment(value: m, label: Text(m.short)),
      ],
      selected: {current},
      onSelectionChanged: (s) => onSelect(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: WidgetStatePropertyAll(BorderSide(color: accent.withOpacity(0.3))),
      ),
    );
  }
}

class _DiffLockDiagram extends StatelessWidget {
  const _DiffLockDiagram({
    required this.state,
    required this.onFront,
    required this.onCenter,
    required this.onRear,
    required this.accent,
  });

  final VehicleState state;
  final ValueChanged<bool> onFront;
  final ValueChanged<bool> onCenter;
  final ValueChanged<bool> onRear;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiffLockPainter(
        state: state,
        accent: accent,
        outline: Theme.of(context).colorScheme.outlineVariant,
        onSurface: Theme.of(context).colorScheme.onSurface,
      ),
      child: LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(children: [
          Positioned(
            left: w * 0.15 - 32,
            top: h * 0.5 - 18,
            child: _DiffToggle(
              label: 'F',
              locked: state.frontDiffLocked,
              onTap: () => onFront(!state.frontDiffLocked),
            ),
          ),
          Positioned(
            left: w * 0.5 - 32,
            top: h * 0.5 - 18,
            child: _DiffToggle(
              label: 'C',
              locked: state.centerDiffLocked,
              onTap: () => onCenter(!state.centerDiffLocked),
            ),
          ),
          Positioned(
            left: w * 0.85 - 32,
            top: h * 0.5 - 18,
            child: _DiffToggle(
              label: 'R',
              locked: state.rearDiffLocked,
              onTap: () => onRear(!state.rearDiffLocked),
            ),
          ),
        ]);
      }),
    );
  }
}

class _DiffToggle extends StatelessWidget {
  const _DiffToggle({required this.label, required this.locked, required this.onTap});
  final String label;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = locked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 36,
        decoration: BoxDecoration(
          color: c.withOpacity(0.14),
          border: Border.all(color: c.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          locked ? '$label LOCK' : label,
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DiffLockPainter extends CustomPainter {
  _DiffLockPainter({
    required this.state,
    required this.accent,
    required this.outline,
    required this.onSurface,
  });
  final VehicleState state;
  final Color accent;
  final Color outline;
  final Color onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.5;
    final frontX = size.width * 0.15;
    final centerX = size.width * 0.5;
    final rearX = size.width * 0.85;

    final shaft = Paint()
      ..color = outline
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(frontX, y), Offset(centerX, y), shaft);
    canvas.drawLine(Offset(centerX, y), Offset(rearX, y), shaft);

    // Highlight active shafts when diffs locked.
    final active = Paint()
      ..color = accent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    if (state.centerDiffLocked) {
      canvas.drawLine(Offset(frontX, y), Offset(rearX, y), active);
    }

    // Wheel pairs.
    final wheel = Paint()..color = onSurface.withOpacity(0.78);
    for (final cx in [frontX, rearX]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y - 50), width: 18, height: 28),
          const Radius.circular(4),
        ),
        wheel,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y + 50), width: 18, height: 28),
          const Radius.circular(4),
        ),
        wheel,
      );
      // Axle.
      canvas.drawLine(Offset(cx, y - 36), Offset(cx, y + 36), shaft);
    }

    // Diff housing circles to sit behind the toggle buttons.
    for (final cx in [frontX, centerX, rearX]) {
      canvas.drawCircle(Offset(cx, y), 22, Paint()..color = outline.withOpacity(0.14));
    }

    // Axle lock indicator when front/rear locked.
    if (state.frontDiffLocked) {
      canvas.drawLine(Offset(frontX, y - 36), Offset(frontX, y + 36), active);
    }
    if (state.rearDiffLocked) {
      canvas.drawLine(Offset(rearX, y - 36), Offset(rearX, y + 36), active);
    }

    // Labels: "FRONT" / "REAR".
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = TextStyle(color: onSurface.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700);
    tp.text = TextSpan(text: 'FRONT', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(frontX - tp.width / 2, y + 78));
    tp.text = TextSpan(text: 'REAR', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(rearX - tp.width / 2, y + 78));
  }

  @override
  bool shouldRepaint(covariant _DiffLockPainter old) =>
      old.state.frontDiffLocked != state.frontDiffLocked ||
      old.state.centerDiffLocked != state.centerDiffLocked ||
      old.state.rearDiffLocked != state.rearDiffLocked ||
      old.accent != accent;
}

class _TractionAids extends StatelessWidget {
  const _TractionAids({
    required this.state,
    required this.onHillDescent,
    required this.onCrawl,
  });
  final VehicleState state;
  final ValueChanged<bool> onHillDescent;
  final ValueChanged<bool> onCrawl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: const Text('Hill descent'),
            avatar: const Icon(Icons.trending_down, size: 16),
            selected: state.hillDescentAssist,
            onSelected: onHillDescent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilterChip(
            label: const Text('Crawl control'),
            avatar: const Icon(Icons.terrain, size: 16),
            selected: state.crawlControl,
            onSelected: onCrawl,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// TPMS + wheel slip + compass
// =====================================================================

class _TpmsDiagram extends StatelessWidget {
  const _TpmsDiagram({required this.state});
  final VehicleState state;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    String fmt(double kpa) =>
        s.useMetric ? '${kpa.toStringAsFixed(0)} kPa' : '${(kpa * 0.145038).toStringAsFixed(1)} psi';

    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final cx = w / 2;
      final cy = h / 2;
      return Stack(children: [
        CustomPaint(
          size: Size(w, h),
          painter: _CarSilhouettePainter(outline: Theme.of(context).colorScheme.outlineVariant),
        ),
        _TpmsTag(position: Offset(cx - w * 0.32, cy - h * 0.3), pressure: state.tpmsFlKpa, label: 'FL', text: fmt(state.tpmsFlKpa)),
        _TpmsTag(position: Offset(cx + w * 0.20, cy - h * 0.3), pressure: state.tpmsFrKpa, label: 'FR', text: fmt(state.tpmsFrKpa)),
        _TpmsTag(position: Offset(cx - w * 0.32, cy + h * 0.15), pressure: state.tpmsRlKpa, label: 'RL', text: fmt(state.tpmsRlKpa)),
        _TpmsTag(position: Offset(cx + w * 0.20, cy + h * 0.15), pressure: state.tpmsRrKpa, label: 'RR', text: fmt(state.tpmsRrKpa)),
      ]);
    });
  }
}

class _TpmsTag extends StatelessWidget {
  const _TpmsTag({
    required this.position,
    required this.pressure,
    required this.label,
    required this.text,
  });
  final Offset position;
  final double pressure;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final low = pressure < 200; // 200 kPa ~ 29 psi
    final accent = low
        ? const Color(0xFFFF5470)
        : Theme.of(context).colorScheme.primary;
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.14),
          border: Border.all(color: accent.withOpacity(0.55), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 11)),
            Text(text,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: accent)),
          ],
        ),
      ),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  _CarSilhouettePainter({required this.outline});
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = outline.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width * 0.42,
          height: size.height * 0.78),
      const Radius.circular(20),
    );
    canvas.drawRRect(body, paint);

    // Hood/windshield line.
    final mid = Paint()
      ..color = outline.withOpacity(0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.33, size.height * 0.35),
      Offset(size.width * 0.67, size.height * 0.35),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.33, size.height * 0.62),
      Offset(size.width * 0.67, size.height * 0.62),
      mid,
    );
  }

  @override
  bool shouldRepaint(covariant _CarSilhouettePainter old) => old.outline != outline;
}

class _WheelSpeeds extends StatelessWidget {
  const _WheelSpeeds({required this.state});
  final VehicleState state;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final nominal = state.speedKph;
    final fl = state.wheelSpeedFlKph;
    final fr = state.wheelSpeedFrKph;
    final rl = state.wheelSpeedRlKph;
    final rr = state.wheelSpeedRrKph;
    final maxVal = [fl, fr, rl, rr, nominal.abs() + 5].reduce(math.max);

    double conv(double v) => s.useMetric ? v : v * 0.621371;
    final unit = s.useMetric ? 'km/h' : 'mph';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in [
          ('Front L', fl),
          ('Front R', fr),
          ('Rear  L', rl),
          ('Rear  R', rr),
        ]) ...[
          _WheelSpeedBar(label: row.$1, value: row.$2, max: maxVal, displayUnit: unit, convert: conv),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 4),
        Text(
          'Slip (max Δ): ${(([fl, fr, rl, rr].reduce(math.max) - [fl, fr, rl, rr].reduce(math.min))).toStringAsFixed(1)} $unit',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _WheelSpeedBar extends StatelessWidget {
  const _WheelSpeedBar({
    required this.label,
    required this.value,
    required this.max,
    required this.displayUnit,
    required this.convert,
  });
  final String label;
  final double value;
  final double max;
  final String displayUnit;
  final double Function(double) convert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = (value / (max == 0 ? 1 : max)).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              color: scheme.outlineVariant.withOpacity(0.25),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: t,
                child: Container(color: scheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            '${convert(value).toStringAsFixed(0)} $displayUnit',
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _Compass extends StatelessWidget {
  const _Compass({required this.headingDeg, required this.accent});
  final double headingDeg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final size = math.min(c.maxWidth, c.maxHeight);
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CompassPainter(
              headingDeg: headingDeg,
              accent: accent,
              onSurface: Theme.of(context).colorScheme.onSurface,
              outline: Theme.of(context).colorScheme.outlineVariant,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${headingDeg.toStringAsFixed(0)}°',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(_cardinal(headingDeg),
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  static String _cardinal(double deg) {
    const dirs = ['N','NE','E','SE','S','SW','W','NW'];
    final i = (((deg % 360) + 360) % 360 / 45).round() % 8;
    return dirs[i];
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.headingDeg,
    required this.accent,
    required this.onSurface,
    required this.outline,
  });
  final double headingDeg;
  final Color accent;
  final Color onSurface;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final ring = Paint()
      ..color = outline.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ring);

    // Ticks and cardinal labels, rotated so "N" points to current heading.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingDeg * math.pi / 180);
    final tickPaint = Paint()
      ..color = onSurface.withOpacity(0.6)
      ..strokeWidth = 1.5;
    for (int d = 0; d < 360; d += 15) {
      canvas.save();
      canvas.rotate(d * math.pi / 180);
      final long = d % 90 == 0;
      canvas.drawLine(Offset(0, -radius + 2), Offset(0, -radius + (long ? 12 : 6)), tickPaint);
      canvas.restore();
    }
    const labels = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    for (final e in labels.entries) {
      canvas.save();
      canvas.rotate(e.key * math.pi / 180);
      final tp = TextPainter(
        text: TextSpan(
            text: e.value,
            style: TextStyle(
                color: e.value == 'N' ? accent : onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -radius + 14));
      canvas.restore();
    }
    canvas.restore();

    // North-pointing needle (stays fixed up, because we rotated the rose).
    final needle = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final p = Path()
      ..moveTo(center.dx, center.dy - radius + 18)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();
    canvas.drawPath(p, needle);
    canvas.drawCircle(center, 3, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.headingDeg != headingDeg ||
      old.accent != accent ||
      old.onSurface != onSurface;
}
