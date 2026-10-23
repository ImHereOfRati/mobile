import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';
import 'package:iamhere/shell/bridge/generated/bridge_contract.generated.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterAppBridgeHandlers {
  final Future<void> Function()? onExit;
  final ValueNotifier<ThemeMode>? themeMode;
  final Future<void> Function(ThemeMode)? saveTheme;
  final AnalyticsReporter _analytics;

  FlutterAppBridgeHandlers({
    this.onExit,
    this.themeMode,
    this.saveTheme,
    AnalyticsReporter? analytics,
  }) : _analytics = analytics ?? FirebaseAnalyticsReporter();

  Map<String, BridgeMethodHandler> build() {
    return <String, BridgeMethodHandler>{
      'getCapabilities': (_) => _getCapabilities(),
      'getAppInfo': (_) => _getAppInfo(),
      'openExternalUrl': _openExternalUrl,
      'share': _share,
      'haptic': _haptic,
      'setStatusBarStyle': _setStatusBarStyle,
      'setTheme': _setTheme,
      'exitApp': (_) => onExit?.call() ?? SystemNavigator.pop(),
      'setAnalyticsConsent': _setAnalyticsConsent,
      'logEvent': _logEvent,
    };
  }

  Future<Map<String, Object?>> _getCapabilities() async {
    final info = await PackageInfo.fromPlatform();
    return <String, Object?>{
      'bridgeVersion': bridgeContractVersion,
      'appVersion': info.version,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'capabilities': <String>[
        ...bridgeMethodNames.map((name) => 'method:$name'),
        ...bridgeEventNames.map((name) => 'event:$name'),
      ],
    };
  }

  Future<Map<String, Object?>> _getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    return <String, Object?>{
      'appVersion': info.version,
      'buildNumber': info.buildNumber,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'locale': platformDispatcher.locale.toLanguageTag(),
      'theme': _themeName(),
    };
  }

  Future<void> _openExternalUrl(Object? params) async {
    final url = _requiredString(params, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Unable to open external URL.');
    }
  }

  Future<void> _share(Object? params) async {
    final map = _requiredMap(params);
    await SharePlus.instance.share(
      ShareParams(
        text: _requiredString(map, 'text'),
        title: map['title'] as String?,
      ),
    );
  }

  Future<void> _haptic(Object? params) {
    return switch (_requiredString(params, 'style')) {
      'light' => HapticFeedback.lightImpact(),
      'medium' => HapticFeedback.mediumImpact(),
      'heavy' => HapticFeedback.heavyImpact(),
      'selection' => HapticFeedback.selectionClick(),
      final value => throw ArgumentError.value(value, 'style'),
    };
  }

  Future<void> _setStatusBarStyle(Object? params) async {
    final style = _requiredString(params, 'style');
    SystemChrome.setSystemUIOverlayStyle(
      style == 'light' ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  Future<void> _setTheme(Object? params) async {
    final theme = _requiredString(params, 'theme');
    final nextTheme = switch (theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      final value => throw ArgumentError.value(value, 'theme'),
    };
    themeMode?.value = nextTheme;
    await saveTheme?.call(nextTheme);
    SystemChrome.setSystemUIOverlayStyle(
      nextTheme == ThemeMode.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }

  String _themeName() {
    final mode = themeMode?.value ?? ThemeMode.system;
    if (mode == ThemeMode.dark) return 'dark';
    if (mode == ThemeMode.light) return 'light';
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark
        ? 'dark'
        : 'light';
  }

  Future<void> _logEvent(Object? params) async {
    final map = _requiredMap(params);
    final rawParameters = map['parameters'];
    await _analytics.logEvent(
      _requiredString(map, 'name'),
      parameters: rawParameters is Map
          ? rawParameters.map(
              (key, value) => MapEntry(key.toString(), value as Object),
            )
          : null,
    );
  }

  Future<void> _setAnalyticsConsent(Object? params) =>
      _analytics.setConsent(_requiredBool(params, 'granted'));

  static Map<String, Object?> _requiredMap(Object? params) {
    if (params is! Map) throw const FormatException('Expected object params.');
    return params.map((key, value) => MapEntry(key.toString(), value));
  }

  static String _requiredString(Object? params, String key) {
    final value = _requiredMap(params)[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected non-empty string "$key".');
    }
    return value;
  }

  static bool _requiredBool(Object? params, String key) {
    final value = _requiredMap(params)[key];
    if (value is! bool) {
      throw FormatException('Expected boolean "$key".');
    }
    return value;
  }
}
