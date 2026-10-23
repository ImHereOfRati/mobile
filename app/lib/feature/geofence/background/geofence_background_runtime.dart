import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/common/config/app_env.dart';
import 'package:iamhere/common/config/app_origin.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/firebase_options.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/integration/firebase/firebase_remote_service.dart';

final GeofenceBackgroundRuntime _backgroundRuntime = GeofenceBackgroundRuntime(
  initializeFlutter: _initializeFlutterRuntime,
  registerPlugins: ui.DartPluginRegistrant.ensureInitialized,
  initializeFirebaseIfNeeded: _initializeFirebaseIfNeeded,
  enrollBaseUrlIfNeeded: _enrollBaseUrlIfNeeded,
);

@pragma('vm:entry-point')
Future<void> bootstrapBackgroundRuntime() => _backgroundRuntime.initialize();

class GeofenceBackgroundRuntime {
  GeofenceBackgroundRuntime({
    required FutureOr<void> Function() initializeFlutter,
    required FutureOr<void> Function() registerPlugins,
    required FutureOr<void> Function() initializeFirebaseIfNeeded,
    required FutureOr<void> Function() enrollBaseUrlIfNeeded,
  }) : _initializeFlutter = initializeFlutter,
       _registerPlugins = registerPlugins,
       _initializeFirebaseIfNeeded = initializeFirebaseIfNeeded,
       _enrollBaseUrlIfNeeded = enrollBaseUrlIfNeeded;

  final FutureOr<void> Function() _initializeFlutter;
  final FutureOr<void> Function() _registerPlugins;
  final FutureOr<void> Function() _initializeFirebaseIfNeeded;
  final FutureOr<void> Function() _enrollBaseUrlIfNeeded;

  bool _bootstrapped = false;
  Future<void>? _inFlight;

  Future<void> initialize() {
    if (_bootstrapped) return Future<void>.value();

    final runningInitialization = _inFlight;
    if (runningInitialization != null) {
      return runningInitialization;
    }

    final initialization = _initialize();
    _inFlight = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    try {
      await _initializeFlutter();
      await _registerPlugins();
      await _initializeFirebaseIfNeeded();
      await _enrollBaseUrlIfNeeded();
      _bootstrapped = true;
    } finally {
      _inFlight = null;
    }
  }
}

void _initializeFlutterRuntime() {
  WidgetsFlutterBinding.ensureInitialized();
}

Future<void> _initializeFirebaseIfNeeded() async {
  if (Firebase.apps.isEmpty) {
    // dotenv 상태는 아이솔레이트별로 분리되므로 백그라운드에서도 직접 로드한다.
    await AppEnv.ensureLoaded();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _enrollBaseUrlIfNeeded() async {
  if (!GetIt.instance.isRegistered<String>(instanceName: 'baseUrl')) {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: FirebaseRemoteService.fetchInterval,
        ),
      );
      await remoteConfig.fetchAndActivate();
    } catch (e, st) {
      AppLogger.error('백그라운드 Remote Config fetch 실패', e, st);
    }

    final remoteBaseUrl = remoteConfig.getString(FirebaseRemoteService.baseUrl);
    final baseUrl = remoteBaseUrl.trim().isEmpty
        ? AppOrigin.origin
        : remoteBaseUrl;

    await enrollBaseUrlGlobally(baseUrl: baseUrl);
  }
}
