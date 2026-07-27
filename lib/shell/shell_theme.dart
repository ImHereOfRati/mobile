import 'package:flutter/material.dart';

class ShellTheme {
  const ShellTheme._();

  static const _blue = Color(0xFF0071E3);

  static final light = _theme(
    brightness: Brightness.light,
    surface: Colors.white,
    foreground: const Color(0xFF1D1D1F),
  );

  static final dark = _theme(
    brightness: Brightness.dark,
    surface: const Color(0xFF1C1C1E),
    foreground: Colors.white,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color surface,
    required Color foreground,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: foreground,
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: foreground.withValues(alpha: 0.68),
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}
