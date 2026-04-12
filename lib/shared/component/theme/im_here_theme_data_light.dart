import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF007AFF),
    primary: const Color(0xFF007AFF),
    onPrimary: Colors.white,
    secondary: const Color(0xFF1F2937),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    tertiary: const Color(0xFFE6EDF6),
    error: const Color(0xFFBA1A1A),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1F2937),
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFF007AFF),
    unselectedItemColor: Color(0xFF9CA3AF),
    elevation: 8,
    type: BottomNavigationBarType.fixed,
  ),
  fontFamily: 'BMHANNAAir',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w700,
      color: Color(0xFF007AFF),
      fontSize: 28,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'BMJUA',
      fontWeight: FontWeight.w400,
      color: Color(0xFF1F2937),
      fontSize: 22,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 16,
      color: Color(0xFF1F2937),
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 14,
      color: Color(0xFF4B5563),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF007AFF),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontFamily: 'BMJUA', fontSize: 18),
    ),
  ),
);
