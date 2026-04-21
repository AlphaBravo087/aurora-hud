import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/vehicle/vehicle_bus.dart';
import '../../widgets/glass_card.dart';

/// Available base map layers.
///
/// * [streets] — OpenStreetMap standard raster tiles (road names, POIs, full
///   street-level detail).
/// * [satellite] — Esri World Imagery (global high-resolution aerial).
/// * [topo] — OpenTopoMap (shaded relief + contours, handy when off-road).
enum MapLayer { streets, satellite, topo }

extension on MapLayer {
  String get label {
    switch (this) {
      case MapLayer.streets:   return 'Streets';
      case MapLayer.satellite: return 'Satellite';
      case MapLayer.topo:      return 'Topographic';
    }
  }

  IconData get icon {
    switch (this) {
      case MapLayer.streets:   return Icons.map;
      case MapLayer.satellite: return Icons.satellite_alt;
      case MapLayer.topo:      return Icons.terrain;
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapLayer.streets:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayer.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayer.topo:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  String get attribution {
    switch (this) {
      case MapLayer.streets:   return '© OpenStreetMap contributors';
      case MapLayer.satellite: return 'Imagery © Esri, Maxar, Earthstar Geographics';
      case MapLayer.topo:      return '© OpenTopoMap (CC-BY-SA) · SRTM';
    }
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  MapLayer _layer = MapLayer.streets;
  bool _followVehicle = true;
  double _zoom = 14;

  @override
  Widget build(BuildContext context) {
    final bus = context.watch<VehicleBus>();
    final s = context.watch<SettingsController>();
    final pos = LatLng(bus.state.latitude, bus.state.longitude);

    if (_followVehicle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _controller.move(pos, _zoom);
        } catch (_) {/* controller not attached yet */}
      });
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final m in MapLayer.values) ...[
                _LayerButton(
                  mode: m,
                  selected: _layer == m,
                  onTap: () => setState(() => _layer = m),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              FilterChip(
                avatar: const Icon(Icons.my_location, size: 16),
                label: const Text('Follow vehicle'),
                selected: _followVehicle,
                onSelected: (v) => setState(() => _followVehicle = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FlutterMap(
                      mapController: _controller,
                      options: MapOptions(
                        initialCenter: pos,
                        initialZoom: _zoom,
                        minZoom: 3,
                        maxZoom: 19,
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture && _followVehicle) {
                            setState(() => _followVehicle = false);
                          }
                          _zoom = position.zoom;
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _layer.urlTemplate,
                          userAgentPackageName: 'com.aurora.hud',
                          tileBuilder: (ctx, child, tile) => child,
                          maxZoom: 19,
                          // Darken satellite/topo slightly for night-drive legibility.
                          tileDisplay: const TileDisplay.fadeIn(),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: pos,
                              width: 44,
                              height: 44,
                              child: _VehicleMarker(
                                heading: bus.state.headingDeg,
                                accent: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _MapOverlayCard(
                        children: [
                          Text(_layer.label, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 2),
                          Text(
                            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            '${_formatSpeed(bus.state.speedKph, s)} · ${bus.state.headingDeg.toStringAsFixed(0)}°',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _MapButtons(
                        onZoomIn: () {
                          _zoom = (_zoom + 1).clamp(3, 19);
                          _controller.move(_controller.camera.center, _zoom);
                        },
                        onZoomOut: () {
                          _zoom = (_zoom - 1).clamp(3, 19);
                          _controller.move(_controller.camera.center, _zoom);
                        },
                        onRecenter: () => setState(() => _followVehicle = true),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _layer.attribution,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
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

  String _formatSpeed(double kph, SettingsController s) {
    final v = s.useMetric ? kph : kph * 0.621371;
    return '${v.toStringAsFixed(0)} ${s.speedUnit}';
  }
}

class _LayerButton extends StatelessWidget {
  const _LayerButton({required this.mode, required this.selected, required this.onTap});
  final MapLayer mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.primary.withOpacity(0.16) : c.surfaceContainerHighest,
          border: Border.all(
            color: selected ? c.primary : c.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 18, color: selected ? c.primary : c.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              mode.label,
              style: TextStyle(
                color: selected ? c.primary : c.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButtons extends StatelessWidget {
  const _MapButtons({required this.onZoomIn, required this.onZoomOut, required this.onRecenter});
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return _MapOverlayCard(
      children: [
        IconButton(icon: const Icon(Icons.add), onPressed: onZoomIn, tooltip: 'Zoom in'),
        IconButton(icon: const Icon(Icons.remove), onPressed: onZoomOut, tooltip: 'Zoom out'),
        IconButton(icon: const Icon(Icons.my_location), onPressed: onRecenter, tooltip: 'Recenter'),
      ],
    );
  }
}

class _MapOverlayCard extends StatelessWidget {
  const _MapOverlayCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.heading, required this.accent});
  final double heading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * 3.1415926 / 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.2),
              border: Border.all(color: accent, width: 2),
            ),
          ),
          Icon(Icons.navigation, size: 22, color: accent),
        ],
      ),
    );
  }
}
