import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() => ThemeMode.system;

  void setLight() => state = ThemeMode.light;
  void setDark() => state = ThemeMode.dark;
  void toggle() =>
      state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

  bool get isDark => state == ThemeMode.dark;
}
