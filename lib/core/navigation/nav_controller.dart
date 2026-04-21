import 'dart:async';

import 'package:flutter/foundation.dart';

/// A very lightweight navigation model. A real integration would embed
/// OsmAnd / Mapbox / HERE but this mock is enough to drive the UI and
/// guidance widgets end-to-end.
class NavController extends ChangeNotifier {
  NavController() {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  Timer? _timer;
  Route? _route;
  int _stepIndex = 0;
  Duration _etaTtl = const Duration(minutes: 18);
  double _distanceRemainingKm = 14.8;

  Route? get route => _route;
  RouteStep? get nextStep => _route == null ? null : _route!.steps[_stepIndex];
  Duration get eta => _etaTtl;
  double get distanceRemainingKm => _distanceRemainingKm;

  void startDemoRoute() {
    _route = const Route(
      'Home',
      '742 Evergreen Terrace, Darwin NT',
      [
        RouteStep(Maneuver.start, 'Depart', 'Head west on Mitchell St', 0.2),
        RouteStep(Maneuver.right, 'Turn right', 'onto Smith St', 0.5),
        RouteStep(Maneuver.left, 'Turn left', 'onto Bennett St', 0.8),
        RouteStep(Maneuver.straight, 'Continue', 'on Tiger Brennan Dr for 6.4 km', 6.4),
        RouteStep(Maneuver.roundabout, 'At roundabout', 'take the 2nd exit', 0.3),
        RouteStep(Maneuver.right, 'Turn right', 'onto Stuart Hwy', 2.1),
        RouteStep(Maneuver.left, 'Turn left', 'onto Evergreen Terrace', 0.5),
        RouteStep(Maneuver.arrive, 'Arrive', 'at destination on the right', 0),
      ],
    );
    _stepIndex = 0;
    _distanceRemainingKm = 14.8;
    _etaTtl = const Duration(minutes: 18);
    notifyListeners();
  }

  void clearRoute() {
    _route = null;
    _stepIndex = 0;
    notifyListeners();
  }

  void _tick(Timer _) {
    if (_route == null) return;
    _distanceRemainingKm = (_distanceRemainingKm - 0.1).clamp(0.0, 999.0);
    if (_etaTtl > Duration.zero) {
      _etaTtl -= const Duration(seconds: 1);
    }
    // Advance step every 15 seconds of demo time.
    if (DateTime.now().second % 15 == 0 && _stepIndex < (_route!.steps.length - 1)) {
      _stepIndex++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class Route {
  const Route(this.label, this.destination, this.steps);
  final String label;
  final String destination;
  final List<RouteStep> steps;
}

class RouteStep {
  const RouteStep(this.maneuver, this.primary, this.secondary, this.distanceKm);
  final Maneuver maneuver;
  final String primary;
  final String secondary;
  final double distanceKm;
}

enum Maneuver { start, straight, left, right, slightLeft, slightRight, roundabout, uturn, arrive }
