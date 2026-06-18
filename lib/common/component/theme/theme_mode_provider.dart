import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'theme_mode_storage.dart';

part 'theme_mode_provider.g.dart';

ThemeMode _initialThemeMode = ThemeMode.light;

void setInitialThemeMode(ThemeMode mode) {
  _initialThemeMode = mode;
}

@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() => _initialThemeMode;

  void setLight() => _setAndPersist(ThemeMode.light);
  void setDark() => _setAndPersist(ThemeMode.dark);
  void toggle() => _setAndPersist(
    state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
  );

  bool get isDark => state == ThemeMode.dark;

  void _setAndPersist(ThemeMode mode) {
    state = mode;
    unawaited(ThemeModeStorage.save(mode));
  }
}
