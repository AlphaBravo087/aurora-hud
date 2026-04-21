import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Named preset themes for Aurora HUD.
enum AuroraThemeMode {
  midnight('Midnight', Color(0xFF0A0E17), Color(0xFF00C8FF)),
  oled('OLED Black', Color(0xFF000000), Color(0xFF00FFAA)),
  sunset('Sunset', Color(0xFF1A0F1F), Color(0xFFFF7A3D)),
  daylight('Daylight', Color(0xFFF3F5F8), Color(0xFF0066FF)),
  forest('Forest', Color(0xFF0D1612), Color(0xFF7FD67B)),
  cherry('Cherry', Color(0xFF140608), Color(0xFFFF3366));

  const AuroraThemeMode(this.label, this.baseBackground, this.defaultAccent);

  final String label;
  final Color baseBackground;
  final Color defaultAccent;

  bool get isDark {
    // Luminance check
    final l = baseBackground.computeLuminance();
    return l < 0.4;
  }
}

/// Builds a Material ThemeData from the preset and an optional accent override.
class AuroraTheme {
  static ThemeData build(AuroraThemeMode mode, {Color? accentOverride}) {
    final bool dark = mode.isDark;
    final Color accent = accentOverride ?? mode.defaultAccent;
    final Color bg = mode.baseBackground;
    final Color surface = dark
        ? Color.lerp(bg, Colors.white, 0.04)!
        : Color.lerp(bg, Colors.black, 0.03)!;
    final Color surfaceContainer = dark
        ? Color.lerp(bg, Colors.white, 0.08)!
        : Color.lerp(bg, Colors.black, 0.06)!;
    final Color onSurface = dark ? const Color(0xFFE8EAF0) : const Color(0xFF0F1420);
    final Color onSurfaceMuted = dark
        ? const Color(0xFFA0A6B3)
        : const Color(0xFF4A5160);

    final ColorScheme scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: _readableOn(accent),
      primaryContainer: accent.withOpacity(dark ? 0.18 : 0.14),
      onPrimaryContainer: accent,
      secondary: accent,
      onSecondary: _readableOn(accent),
      secondaryContainer: accent.withOpacity(dark ? 0.22 : 0.16),
      onSecondaryContainer: accent,
      tertiary: accent,
      onTertiary: _readableOn(accent),
      error: const Color(0xFFFF5470),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: onSurfaceMuted,
      outline: onSurfaceMuted.withOpacity(0.4),
      outlineVariant: onSurfaceMuted.withOpacity(0.2),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? Colors.white : Colors.black,
      onInverseSurface: dark ? Colors.black : Colors.white,
      inversePrimary: accent,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(onSurface, onSurfaceMuted),
      iconTheme: IconThemeData(color: onSurface, size: 28),
      dividerTheme: DividerThemeData(
        color: onSurfaceMuted.withOpacity(0.18),
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: onSurfaceMuted.withOpacity(0.25),
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.12),
        trackHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : onSurfaceMuted.withOpacity(0.3),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? _readableOn(accent) : Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: _readableOn(accent),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
    return base;
  }

  static Color _readableOn(Color c) {
    return c.computeLuminance() > 0.55 ? const Color(0xFF0A0E17) : Colors.white;
  }

  static TextTheme _textTheme(Color onSurface, Color muted) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 72, fontWeight: FontWeight.w300, color: onSurface, letterSpacing: -2),
      displayMedium: GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w300, color: onSurface, letterSpacing: -1.5),
      displaySmall: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: -1),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w500, color: onSurface),
      headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w500, color: onSurface),
      headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: onSurface),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: muted, letterSpacing: 1.2),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: onSurface),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: onSurface),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: muted),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
      labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: muted, letterSpacing: 1.4),
    );
  }
}

/// Available accent presets the user can pick in Settings.
class AccentPalette {
  static const List<(String, Color)> swatches = [
    ('Aurora Cyan', Color(0xFF00C8FF)),
    ('Emerald', Color(0xFF00E5A0)),
    ('Lava', Color(0xFFFF5530)),
    ('Amber', Color(0xFFFFB020)),
    ('Magenta', Color(0xFFE040FB)),
    ('Violet', Color(0xFF7C5CFF)),
    ('Sky', Color(0xFF3DA9FF)),
    ('Rose', Color(0xFFFF4F88)),
  ];
}
