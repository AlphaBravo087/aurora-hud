import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/aurora_theme.dart';

/// Persisted user settings. Every value here is directly tweakable from the
/// Settings screen — the whole point of Aurora HUD is heavy user
/// customization.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  // Theme ------------------------------------------------------------------
  AuroraThemeMode _themeMode = AuroraThemeMode.midnight;
  Color _accent = AuroraThemeMode.midnight.defaultAccent;

  AuroraThemeMode get themeMode => _themeMode;
  Color get accent => _accent;

  void setThemeMode(AuroraThemeMode m) {
    if (_themeMode == m) return;
    _themeMode = m;
    _accent = m.defaultAccent;
    _prefs.setString('themeMode', m.name);
    _prefs.setInt('accent', _accent.value);
    notifyListeners();
  }

  void setAccent(Color c) {
    if (_accent.value == c.value) return;
    _accent = c;
    _prefs.setInt('accent', c.value);
    notifyListeners();
  }

  // Units ------------------------------------------------------------------
  bool _useMetric = false; // Miles + °F by default. Toggle for km + °C.
  bool get useMetric => _useMetric;
  void setUseMetric(bool v) {
    if (_useMetric == v) return;
    _useMetric = v;
    _prefs.setBool('useMetric', v);
    notifyListeners();
  }

  String get speedUnit => _useMetric ? 'km/h' : 'mph';
  String get tempUnit => _useMetric ? '°C' : '°F';
  String get distUnit => _useMetric ? 'km' : 'mi';

  // Display ----------------------------------------------------------------
  double _brightness = 1.0; // 0.2 .. 1.0
  bool _autoDim = true;
  bool _navDuringMusic = true;
  bool _reduceMotion = false;
  bool _showGpsInStatus = true;

  double get brightness => _brightness;
  bool get autoDim => _autoDim;
  bool get navDuringMusic => _navDuringMusic;
  bool get reduceMotion => _reduceMotion;
  bool get showGpsInStatus => _showGpsInStatus;

  void setBrightness(double v) {
    _brightness = v.clamp(0.2, 1.0);
    _prefs.setDouble('brightness', _brightness);
    notifyListeners();
  }
  void setAutoDim(bool v) { _autoDim = v; _prefs.setBool('autoDim', v); notifyListeners(); }
  void setNavDuringMusic(bool v) { _navDuringMusic = v; _prefs.setBool('navDuringMusic', v); notifyListeners(); }
  void setReduceMotion(bool v) { _reduceMotion = v; _prefs.setBool('reduceMotion', v); notifyListeners(); }
  void setShowGpsInStatus(bool v) { _showGpsInStatus = v; _prefs.setBool('showGpsInStatus', v); notifyListeners(); }

  // Home layout -----------------------------------------------------------
  /// Widget ids shown on the home screen, in order.
  List<String> _homeWidgets = const [
    'clock',
    'next_turn',
    'media',
    'gauges',
    'climate',
    'trip',
  ];
  List<String> get homeWidgets => List.unmodifiable(_homeWidgets);

  void setHomeWidgets(List<String> ids) {
    _homeWidgets = List.of(ids);
    _prefs.setString('homeWidgets', jsonEncode(_homeWidgets));
    notifyListeners();
  }

  void toggleHomeWidget(String id) {
    final list = List.of(_homeWidgets);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    setHomeWidgets(list);
  }

  // Gauge preferences ----------------------------------------------------
  /// IDs of the gauges shown on the dashboard cluster screen.
  List<String> _gauges = const ['speed', 'rpm', 'coolant', 'fuel', 'boost', 'voltage'];
  List<String> get gauges => List.unmodifiable(_gauges);
  void setGauges(List<String> ids) {
    _gauges = List.of(ids);
    _prefs.setString('gauges', jsonEncode(_gauges));
    notifyListeners();
  }

  // Vehicle profile -------------------------------------------------------
  String _vehicleProfile = 'toyota_generic';
  String get vehicleProfile => _vehicleProfile;
  void setVehicleProfile(String id) {
    _vehicleProfile = id;
    _prefs.setString('vehicleProfile', id);
    notifyListeners();
  }

  // Driver name -----------------------------------------------------------
  String _driverName = 'Driver';
  String get driverName => _driverName;
  void setDriverName(String n) {
    _driverName = n;
    _prefs.setString('driverName', n);
    notifyListeners();
  }

  // ---- Loading ----------------------------------------------------------
  void _load() {
    final tmStr = _prefs.getString('themeMode');
    if (tmStr != null) {
      _themeMode = AuroraThemeMode.values.firstWhere(
        (e) => e.name == tmStr,
        orElse: () => AuroraThemeMode.midnight,
      );
    }
    final a = _prefs.getInt('accent');
    if (a != null) _accent = Color(a);

    _useMetric = _prefs.getBool('useMetric') ?? _useMetric;
    _brightness = _prefs.getDouble('brightness') ?? _brightness;
    _autoDim = _prefs.getBool('autoDim') ?? _autoDim;
    _navDuringMusic = _prefs.getBool('navDuringMusic') ?? _navDuringMusic;
    _reduceMotion = _prefs.getBool('reduceMotion') ?? _reduceMotion;
    _showGpsInStatus = _prefs.getBool('showGpsInStatus') ?? _showGpsInStatus;

    final hw = _prefs.getString('homeWidgets');
    if (hw != null) {
      try {
        _homeWidgets = List<String>.from(jsonDecode(hw) as List);
      } catch (_) {
        // ignore malformed settings
      }
    }
    final gs = _prefs.getString('gauges');
    if (gs != null) {
      try {
        _gauges = List<String>.from(jsonDecode(gs) as List);
      } catch (_) {}
    }
    _vehicleProfile = _prefs.getString('vehicleProfile') ?? _vehicleProfile;
    _driverName = _prefs.getString('driverName') ?? _driverName;

    if (kDebugMode) debugPrint('[Settings] loaded');
  }
}
