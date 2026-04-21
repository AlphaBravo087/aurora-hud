import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular gauge rendered with CustomPainter. Designed to read well at a
/// glance on a dashboard in direct sunlight: wide arc, bright accent, soft
/// shadow, large numeric callout.
class CircularGauge extends StatelessWidget {
  const CircularGauge({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    required this.unit,
    this.min = 0,
    this.caution,
    this.danger,
    this.size = 200,
    this.formatter,
    this.accent,
  });

  final double value;
  final double min;
  final double max;
  final double? caution;
  final double? danger;
  final String label;
  final String unit;
  final double size;
  final String Function(double)? formatter;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = formatter ?? (v) => v.round().toString();
    final accentColor = accent ?? scheme.primary;
    final clamped = value.clamp(min, max);
    Color ringColor = accentColor;
    if (danger != null && clamped >= danger!) {
      ringColor = const Color(0xFFFF5470);
    } else if (caution != null && clamped >= caution!) {
      ringColor = const Color(0xFFFFB020);
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          value: clamped,
          min: min,
          max: max,
          ring: ringColor,
          trackColor: scheme.outlineVariant,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(fmt(clamped),
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        fontWeight: FontWeight.w300,
                        color: scheme.onSurface,
                      )),
              const SizedBox(height: 2),
              Text(unit, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.ring,
    required this.trackColor,
  });

  final double value;
  final double min;
  final double max;
  final Color ring;
  final Color trackColor;

  static const double _sweep = math.pi * 1.5; // 270°
  static const double _start = math.pi * 0.75; // start at lower-left

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, trackPaint);

    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final valuePaint = Paint()
      ..shader = SweepGradient(
        startAngle: _start,
        endAngle: _start + _sweep,
        colors: [ring.withOpacity(0.6), ring],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep * t, false, valuePaint);

    // Tick marks at 0, 25, 50, 75, 100%.
    final tickPaint = Paint()
      ..color = trackColor.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i <= 4; i++) {
      final angle = _start + _sweep * (i / 4);
      final p1 = Offset(
        center.dx + math.cos(angle) * (radius - 22),
        center.dy + math.sin(angle) * (radius - 22),
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * (radius - 30),
        center.dy + math.sin(angle) * (radius - 30),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.ring != ring || old.trackColor != trackColor;
}

/// A compact horizontal bar gauge (for secondary readings like fuel, boost).
class BarGauge extends StatelessWidget {
  const BarGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    this.valueText,
    this.accent,
  });

  final double value;
  final double min;
  final double max;
  final String label;
  final String? valueText;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = accent ?? scheme.primary;
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall),
            Text(valueText ?? value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                height: 10,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 10,
                width: constraints.maxWidth * t,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.withOpacity(0.7), c],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: c.withOpacity(0.35), blurRadius: 8),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
