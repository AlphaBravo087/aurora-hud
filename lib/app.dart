import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/settings/settings_controller.dart';
import 'core/theme/aurora_theme.dart';
import 'ui/shell/aurora_shell.dart';

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = AuroraTheme.build(settings.themeMode, accentOverride: settings.accent);
    return MaterialApp(
      title: 'Aurora HUD',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const AuroraShell(),
    );
  }
}
