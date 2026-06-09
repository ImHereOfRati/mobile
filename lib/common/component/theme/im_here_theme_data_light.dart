import 'package:flutter/material.dart';

// ── Apple Design Tokens ──────────────────────────────────────────
const _appleBlue = Color(0xFF0071E3);
const _appleDark = Color(0xFF1D1D1F);
const _appleGray = Color(0xFFF5F5F7);
const _appleSecondaryText = Color(0xFF6E6E73);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: _appleGray,
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,

  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: _appleBlue,
    onPrimary: Colors.white,
    secondary: _appleDark,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: _appleDark,
    error: Color(0xFFFF3B30),
    onError: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: _appleDark,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: _appleBlue,
    unselectedItemColor: _appleSecondaryText,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),

  dividerTheme: const DividerThemeData(
    color: Color(0xFFD2D2D7),
    thickness: 0.5,
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return _appleBlue;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
    side: const BorderSide(color: Color(0xFFD2D2D7), width: 1.5),
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
      textStyle: const TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 14,
        letterSpacing: -0.2,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFD2D2D7), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFD2D2D7), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: _appleBlue, width: 2),
    ),
  ),

  // ── Typography ──
  fontFamily: 'BMHANNAAir',
  textTheme: const TextTheme(
    // Display Hero: 40sp, GmarketSans Bold — Section headings
    displayLarge: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontSize: 40,
      letterSpacing: -0.5,
      height: 1.10,
    ),
    // Section Heading: 28sp
    displayMedium: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _appleDark,
      fontSize: 28,
      letterSpacing: -0.3,
      height: 1.14,
    ),
    // Tile Heading: 21sp
    displaySmall: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w500,
      color: _appleDark,
      fontSize: 21,
      letterSpacing: -0.2,
      height: 1.19,
    ),
    // headlineLarge → Auth / Splash title 34sp
    headlineLarge: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _appleDark,
      fontSize: 34,
      letterSpacing: -0.4,
      height: 1.10,
    ),
    // headlineMedium → Page section title 22sp
    headlineMedium: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: _appleDark,
      fontSize: 22,
      letterSpacing: -0.3,
      height: 1.14,
    ),
    // headlineSmall → Card title 17sp semibold
    headlineSmall: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontWeight: FontWeight.w700,
      color: _appleDark,
      fontSize: 17,
      letterSpacing: -0.374,
      height: 1.24,
    ),
    // bodyLarge → Standard 17sp
    bodyLarge: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 17,
      color: _appleDark,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.374,
      height: 1.47,
    ),
    // bodyMedium → Secondary 14sp
    bodyMedium: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 14,
      color: _appleSecondaryText,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.224,
      height: 1.43,
    ),
    // bodySmall → Caption 12sp
    bodySmall: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 12,
      color: _appleSecondaryText,
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
