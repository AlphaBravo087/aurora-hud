import 'dart:async';

import 'package:flutter/foundation.dart';

/// Simple media playback state. On a real head unit this would be wired to
/// BlueZ A2DP/AVRCP, a local library indexer, and network streaming
/// services. On desktop it simulates playback so the UI is demo-able.
class MediaController extends ChangeNotifier {
  MediaController() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), _tick);
  }

  Timer? _timer;

  final List<Track> queue = [
    const Track('Redshift', 'Aerium', 'Galactic Voyages', Duration(minutes: 4, seconds: 28), 0xFF1E3A8A),
    const Track('Ultraviolet', 'Chromeface', 'Neon Atlas', Duration(minutes: 3, seconds: 42), 0xFF7E22CE),
    const Track('Highway Hymn', 'Long Road Stereo', 'After the Rain', Duration(minutes: 5, seconds: 12), 0xFF0F766E),
    const Track('Momentum', 'Kalea', 'Inertia', Duration(minutes: 3, seconds: 58), 0xFFB45309),
    const Track('Soft Fracture', 'Liminal', 'Static Bloom', Duration(minutes: 4, seconds: 9), 0xFF9F1239),
  ];

  int _index = 0;
  Duration _position = const Duration(seconds: 45);
  bool _playing = true;
  double _volume = 0.65;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;

  Track get current => queue[_index];
  Duration get position => _position;
  bool get playing => _playing;
  double get volume => _volume;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;

  void togglePlay() { _playing = !_playing; notifyListeners(); }
  void setVolume(double v) { _volume = v.clamp(0.0, 1.0); notifyListeners(); }
  void toggleShuffle() { _shuffle = !_shuffle; notifyListeners(); }
  void cycleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }
  void seek(Duration d) {
    _position = d;
    notifyListeners();
  }
  void next() {
    _index = (_index + 1) % queue.length;
    _position = Duration.zero;
    notifyListeners();
  }
  void previous() {
    if (_position.inSeconds > 3) {
      _position = Duration.zero;
    } else {
      _index = (_index - 1 + queue.length) % queue.length;
      _position = Duration.zero;
    }
    notifyListeners();
  }

  void _tick(Timer _) {
    if (!_playing) return;
    _position += const Duration(milliseconds: 250);
    if (_position >= current.duration) {
      next();
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

enum RepeatMode { off, all, one }

class Track {
  const Track(this.title, this.artist, this.album, this.duration, this.artColor);
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int artColor;
}
