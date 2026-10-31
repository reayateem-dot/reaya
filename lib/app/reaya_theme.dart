import 'package:flutter/material.dart';

abstract final class ReayaColors {
  static const plum = Color(0xFF684052);
  static const background = Color(0xFFFAF6F5);
  static const blush = Color(0xFFF1E2E8);
  static const muted = Color(0xFF806F78);
  static const ink = Color(0xFF30252C);
  static const border = Color(0xFFE8DCE1);
  static const green = Color(0xFF527A68);
  static const paleGreen = Color(0xFFEAF1EC);
  static const amber = Color(0xFFB8793D);
  static const darkBackground = Color(0xFF181518);
  static const darkSurface = Color(0xFF262026);
  static const darkSoftSurface = Color(0xFF3B3038);
  static const darkInk = Color(0xFFF6F1F3);
  static const darkMuted = Color(0xFFB9ADB2);
  static const darkBorder = Color(0xFF493A43);
}

abstract final class ReayaTheme {
  static ThemeData get light => _build(isDark: false);

  static ThemeData get dark => _build(isDark: true);

  static ThemeData _build({required bool isDark}) {
    final background = isDark
        ? ReayaColors.darkBackground
        : ReayaColors.background;
    final surface = isDark ? ReayaColors.darkSurface : Colors.white;
    final softSurface = isDark
        ? ReayaColors.darkSoftSurface
        : ReayaColors.blush;
    final foreground = isDark ? ReayaColors.darkInk : ReayaColors.ink;
    final muted = isDark ? ReayaColors.darkMuted : ReayaColors.muted;
    final border = isDark ? ReayaColors.darkBorder : ReayaColors.border;
    final scheme = ColorScheme.fromSeed(
      seedColor: ReayaColors.plum,
      primary: ReayaColors.plum,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: surface,
      onSurface: foreground,
      outline: border,
      primaryContainer: softSurface,
      onPrimaryContainer: foreground,
      secondary: const Color(0xFF9A657D),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['Arial'],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: foreground,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          color: foreground,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: foreground,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.55),
        bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ReayaColors.plum, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: softSurface,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : null,
            color: states.contains(WidgetState.selected)
                ? ReayaColors.plum
                : muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: ReayaColors.plum,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
