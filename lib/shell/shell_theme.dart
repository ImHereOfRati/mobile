import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShellTheme {
  const ShellTheme._();

  // Toss-like service blue: clear, calm, and readable on both surfaces.
  static const primaryBlue = Color(0xFF3182F6);
  static const primaryBlueDark = Color(0xFF4593FF);
  static const lightBackground = Color(0xFFF7F8FA);
  static const darkBackground = Color(0xFF101114);
  static const lightForeground = Color(0xFF191F28);
  static const secondaryForeground = Color(0xFF6B7684);
  static const divider = Color(0xFFE5E8EB);

  static final light = _theme(
    brightness: Brightness.light,
    surface: lightBackground,
    foreground: lightForeground,
  );

  static final dark = _theme(
    brightness: Brightness.dark,
    surface: darkBackground,
    foreground: Colors.white,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color surface,
    required Color foreground,
  }) {
    final seededScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: brightness,
      surface: surface,
    );
    final scheme = seededScheme.copyWith(
      primary: brightness == Brightness.dark ? primaryBlueDark : primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: brightness == Brightness.dark
          ? const Color(0xFF123A70)
          : const Color(0xFFE8F3FF),
      onPrimaryContainer: brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF0B5BD3),
      surface: surface,
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF24262B)
          : Colors.white,
      outline: brightness == Brightness.dark
          ? const Color(0xFF3A3D44)
          : divider,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
          systemNavigationBarColor: surface,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF18191D)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 23,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark ? scheme.outline : divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? const Color(0xFF1C1D21)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: brightness == Brightness.dark ? scheme.outline : divider,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF1C1D21)
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: brightness == Brightness.dark ? scheme.outline : divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: foreground,
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: brightness == Brightness.light
              ? secondaryForeground
              : foreground.withValues(alpha: 0.68),
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}
