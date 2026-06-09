import 'package:flutter/material.dart';

// ── Apple Dark Design Tokens ─────────────────────────────────────
const _appleBlue = Color(0xFF0A84FF); // Blue on dark bg (brighter)
const _darkBg = Color(0xFF000000);
const _darkSurface = Color(0xFF1C1C1E);
const _darkText = Color(0xFFFFFFFF);
const _darkSecondaryText = Color(0xFF8E8E93);
const _darkDivider = Color(0xFF38383A);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _darkBg,
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,

  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: _appleBlue,
    onPrimary: Colors.white,
    secondary: Color(0xFF636366),
    onSecondary: Colors.white,
    surface: _darkSurface,
    onSurface: _darkText,
    error: Color(0xFFFF453A),
    onError: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _darkText,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _darkSurface,
    selectedItemColor: _appleBlue,
    unselectedItemColor: _darkSecondaryText,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
  ),

  dividerTheme: const DividerThemeData(
    color: _darkDivider,
    thickness: 0.5,
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return _appleBlue;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
    side: const BorderSide(color: _darkDivider, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _appleBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _appleBlue,
    ),
  ),

  fontFamily: 'BMHANNAAir',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _darkText,
      fontSize: 40,
      letterSpacing: -0.5,
      height: 1.10,
    ),
    displayMedium: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _darkText,
      fontSize: 28,
      letterSpacing: -0.3,
      height: 1.14,
    ),
    displaySmall: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w500,
      color: _darkText,
      fontSize: 21,
      letterSpacing: -0.2,
      height: 1.19,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _darkText,
      fontSize: 34,
      letterSpacing: -0.4,
      height: 1.10,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _darkText,
      fontSize: 22,
      letterSpacing: -0.3,
      height: 1.14,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontWeight: FontWeight.w700,
      color: _darkText,
      fontSize: 17,
      letterSpacing: -0.374,
      height: 1.24,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 17,
      color: _darkText,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.374,
      height: 1.47,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 14,
      color: _darkSecondaryText,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.224,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 12,
      color: _darkSecondaryText,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.12,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 14,
      color: _appleBlue,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.224,
    ),
  ),
);
