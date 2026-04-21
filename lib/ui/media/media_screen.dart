import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/media/media_controller.dart';
import '../../widgets/glass_card.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MediaController>();
    final t = m.current;
    final scheme = Theme.of(context).colorScheme;
    final accent = Color(t.artColor);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GlassCard(
              tint: accent.withOpacity(0.85),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      AuroraChip(label: 'Bluetooth', icon: Icons.bluetooth, color: Colors.white),
                      SizedBox(width: 8),
                      AuroraChip(label: 'High Quality', icon: Icons.graphic_eq, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accent.withOpacity(0.35)],
                        ),
                        boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 40, spreadRadius: -10)],
                      ),
                      child: Center(
                        child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.8), size: 120),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(t.title,
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white)),
                  Text('${t.artist} — ${t.album}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white70)),
                  const SizedBox(height: 22),
                  _Progress(
                    position: m.position,
                    duration: t.duration,
                    onSeek: m.seek,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: m.shuffle ? Colors.white : Colors.white54,
                        ),
                        iconSize: 28,
                        onPressed: m.toggleShuffle,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        iconSize: 44,
                        onPressed: m.previous,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: m.togglePlay,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 30)],
                          ),
                          child: Icon(
                            m.playing ? Icons.pause : Icons.play_arrow,
                            color: accent,
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        iconSize: 44,
                        onPressed: m.next,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(_repeatIcon(m.repeat),
                            color: m.repeat == RepeatMode.off ? Colors.white54 : Colors.white),
                        iconSize: 28,
                        onPressed: m.cycleRepeat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.white70),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(value: m.volume, onChanged: m.setVolume),
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white70),
                    ],
                  ),
                ],
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
                  const SectionHeader('Up next', trailing: Icon(Icons.queue_music, size: 20)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: m.queue.length,
                      separatorBuilder: (_, __) => Divider(color: scheme.outlineVariant),
                      itemBuilder: (context, i) {
                        final track = m.queue[i];
                        final active = track == m.current;
                        return Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(track.artColor),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.music_note, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(track.title,
                                      style: active
                                          ? Theme.of(context).textTheme.titleMedium!.copyWith(color: scheme.primary)
                                          : Theme.of(context).textTheme.titleMedium),
                                  Text(track.artist,
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Text(_fmt(track.duration),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _repeatIcon(RepeatMode r) {
    switch (r) {
      case RepeatMode.off: return Icons.repeat;
      case RepeatMode.all: return Icons.repeat_on;
      case RepeatMode.one: return Icons.repeat_one_on;
    }
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.position, required this.duration, required this.onSeek});
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            trackHeight: 3,
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble(),
            onChanged: (v) => onSeek(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(MediaScreen._fmt(position), style: const TextStyle(color: Colors.white70)),
              Text(MediaScreen._fmt(duration), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}
