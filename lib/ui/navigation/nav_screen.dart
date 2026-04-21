import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/nav_controller.dart';
import '../../core/settings/settings_controller.dart';
import '../../widgets/glass_card.dart';

class NavScreen extends StatelessWidget {
  const NavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final s = context.watch<SettingsController>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _MapPainter(color: Theme.of(context).colorScheme.primary)),
                    Positioned(
                      top: 16, left: 16, right: 16,
                      child: Row(
                        children: [
                          const AuroraChip(label: 'North up', icon: Icons.navigation),
                          const SizedBox(width: 8),
                          const AuroraChip(label: 'Traffic', icon: Icons.traffic),
                          const Spacer(),
                          FilledButton.tonal(
                            onPressed: nav.route == null ? nav.startDemoRoute : nav.clearRoute,
                            child: Text(nav.route == null ? 'Start demo route' : 'Cancel route'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader('Route', trailing: nav.route == null
                      ? null
                      : AuroraChip(label: '${nav.eta.inMinutes} min ETA', icon: Icons.schedule)),
                  if (nav.route == null) ...[
                    const SizedBox(height: 24),
                    Text('No active route', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Tap "Start demo route" to simulate turn-by-turn guidance.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ] else ...[
                    Text(nav.route!.label,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(nav.route!.destination,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text('${nav.distanceRemainingKm.toStringAsFixed(1)} ${s.distUnit} remaining',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: nav.route!.steps.length,
                        separatorBuilder: (_, __) => Divider(color: Theme.of(context).colorScheme.outlineVariant),
                        itemBuilder: (context, i) {
                          final step = nav.route!.steps[i];
                          final active = step == nav.nextStep;
                          return Row(
                            children: [
                              Icon(_iconFor(step.maneuver),
                                  size: 32,
                                  color: active
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(step.primary,
                                        style: active
                                            ? Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.primary)
                                            : Theme.of(context).textTheme.titleMedium),
                                    Text(step.secondary,
                                        style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              if (step.distanceKm > 0)
                                Text('${step.distanceKm.toStringAsFixed(1)} ${s.distUnit}',
                                    style: Theme.of(context).textTheme.labelMedium),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(Maneuver m) {
    switch (m) {
      case Maneuver.left: return Icons.turn_left;
      case Maneuver.right: return Icons.turn_right;
      case Maneuver.slightLeft: return Icons.turn_slight_left;
      case Maneuver.slightRight: return Icons.turn_slight_right;
      case Maneuver.uturn: return Icons.u_turn_left;
      case Maneuver.roundabout: return Icons.roundabout_left;
      case Maneuver.arrive: return Icons.flag;
      case Maneuver.start: return Icons.play_arrow;
      case Maneuver.straight: return Icons.arrow_upward;
    }
  }
}

/// A stylised topographic map painter. Not a real map — just evocative
/// artwork so the Nav screen looks alive in the desktop preview.
class _MapPainter extends CustomPainter {
  _MapPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0B1219);
    canvas.drawRect(Offset.zero & size, bg);

    // Subtle contour lines
    final contour = Paint()
      ..color = color.withOpacity(0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
      final path = Path();
      final y = size.height * (i / 12);
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 6) {
        path.lineTo(x,
            y + 10 * math.sin((x + i * 30) / 40) + 5 * math.cos(x / 80));
      }
      canvas.drawPath(path, contour);
    }

    // Road network (simplified paths)
    final road = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadBg = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minor = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.5,
          size.width * 0.6, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.73,
          size.width * 0.95, size.height * 0.35);
    canvas.drawPath(minor, roadBg);
    canvas.drawPath(minor, road);

    final grid = Paint()
      ..color = color.withOpacity(0.18)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 6; i++) {
      final x = size.width * (0.1 + i * 0.16);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int i = 0; i < 6; i++) {
      final y = size.height * (0.1 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Route line
    final route = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..cubicTo(size.width * 0.35, size.height * 0.55,
          size.width * 0.55, size.height * 0.9,
          size.width * 0.78, size.height * 0.2);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, route);

    // Vehicle marker
    final centerOffset = Offset(size.width * 0.18, size.height * 0.82);
    canvas.drawCircle(centerOffset, 12,
        Paint()..color = color.withOpacity(0.4));
    canvas.drawCircle(centerOffset, 7, Paint()..color = Colors.white);

    // Destination marker
    final destOffset = Offset(size.width * 0.78, size.height * 0.2);
    canvas.drawCircle(destOffset, 10, Paint()..color = color);
    canvas.drawCircle(destOffset, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.color != color;
}
