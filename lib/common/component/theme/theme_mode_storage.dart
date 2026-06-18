import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeStorage {
  static const _themeModeKey = 'app_theme_mode';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<ThemeMode> load() async {
    try {
      final raw = await _storage.read(key: _themeModeKey);
      return switch (raw) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.light,
      };
    } catch (_) {
      return ThemeMode.light;
    }
  }

  static Future<void> save(ThemeMode mode) async {
    try {
      await _storage.write(key: _themeModeKey, value: mode.name);
    } catch (_) {
      // 테마 저장 실패는 앱 동작을 막지 않는다.
    }
  }
}
