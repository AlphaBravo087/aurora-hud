import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';

/// Apple CarPlay / Android Auto passthrough pane.
///
/// Apple CarPlay cannot legally be implemented without MFi licensing. In a
/// real Aurora HUD install, this pane displays the HDMI/USB video input from
/// an off-the-shelf **wireless CarPlay dongle** (e.g. Carlinkit CPC200-CCPA,
/// OttoCast P3) that acts as an MFi-authenticated CarPlay receiver. The
/// dongle appears to the SBC as a UVC video capture device; we composite it
/// here with the rest of the UI.
///
/// On desktop preview (no dongle) we show a placeholder + device status.
class CarPlayScreen extends StatefulWidget {
  const CarPlayScreen({super.key});

  @override
  State<CarPlayScreen> createState() => _CarPlayScreenState();
}

class _CarPlayScreenState extends State<CarPlayScreen> {
  bool _connected = false;
  bool _wireless = true;

  @override
  Widget build(BuildContext context) {
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _connected
                      ? const _ConnectedPane()
                      : const _DisconnectedPane(),
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
                  const SectionHeader('Phone projection'),
                  Text('CarPlay / Android Auto',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                      'This pane mirrors your phone via a Carlinkit CPC200 or equivalent MFi-licensed '
                      'wireless CarPlay dongle connected over HDMI + USB. Aurora HUD does not reimplement '
                      'CarPlay itself — Apple requires MFi licensing for that.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wireless'),
                    value: _wireless,
                    onChanged: (v) => setState(() => _wireless = v),
                  ),
                  FilledButton.icon(
                    icon: Icon(_connected ? Icons.link_off : Icons.link),
                    label: Text(_connected ? 'Disconnect' : 'Simulate connect'),
                    onPressed: () => setState(() => _connected = !_connected),
                  ),
                  const Spacer(),
                  const Divider(),
                  Text('PAIRED DEVICES', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const _PairedDevice('Bosco — iPhone 15 Pro', Icons.phone_iphone, true),
                  const _PairedDevice('Family — Galaxy S24',  Icons.phone_android, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedPane extends StatelessWidget {
  const _ConnectedPane();
  @override
  Widget build(BuildContext context) {
    // A stylised CarPlay-like home. Real deployments would show the HDMI feed.
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('2:42', style: TextStyle(color: Colors.white, fontSize: 28)),
              Spacer(),
              Icon(Icons.signal_cellular_alt, color: Colors.white),
              SizedBox(width: 8),
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('82%', style: TextStyle(color: Colors.white)),
              SizedBox(width: 4),
              Icon(Icons.battery_full, color: Colors.white),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              children: const [
                _CarPlayApp('Maps', Icons.map, Color(0xFF34C759)),
                _CarPlayApp('Music', Icons.music_note, Color(0xFFFF2D55)),
                _CarPlayApp('Phone', Icons.phone, Color(0xFF4CD964)),
                _CarPlayApp('Messages', Icons.message, Color(0xFF5AC8FA)),
                _CarPlayApp('Podcasts', Icons.podcasts, Color(0xFFBF5AF2)),
                _CarPlayApp('Spotify', Icons.queue_music, Color(0xFF1DB954)),
                _CarPlayApp('Waze', Icons.near_me, Color(0xFF33CCFF)),
                _CarPlayApp('Audiobooks', Icons.menu_book, Color(0xFFFF9500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarPlayApp extends StatelessWidget {
  const _CarPlayApp(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 74, height: 74,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _DisconnectedPane extends StatelessWidget {
  const _DisconnectedPane();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_iphone, size: 120, color: scheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('CarPlay dongle not connected',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Plug in a Carlinkit CPC200 or equivalent to begin.',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PairedDevice extends StatelessWidget {
  const _PairedDevice(this.name, this.icon, this.active);
  final String name;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: active ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(name),
      trailing: AuroraChip(
        label: active ? 'Active' : 'Paired',
        color: active ? const Color(0xFF00E5A0) : null,
      ),
    );
  }
}
