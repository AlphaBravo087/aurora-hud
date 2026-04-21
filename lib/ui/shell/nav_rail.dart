import 'package:flutter/material.dart';

class AuroraNavRail extends StatelessWidget {
  const AuroraNavRail({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final List<NavDestination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 108,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        children: [
          _Logo(color: scheme.primary),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.separated(
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final d = destinations[i];
                final isActive = i == selected;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? scheme.primary.withOpacity(0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? scheme.primary.withOpacity(0.4) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          d.icon,
                          size: 26,
                          color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d.label,
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavDestination {
  const NavDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _Logo extends StatelessWidget {
  const _Logo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.95), color.withOpacity(0.55)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 18)],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.blur_on, color: Colors.white, size: 28),
    );
  }
}
