import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/firebase_options.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/integration/firebase/firebase_remote_service.dart';

bool _backgroundRuntimeBootstrapped = false;

@pragma('vm:entry-point')
Future<void> bootstrapBackgroundRuntime() async {
  if (_backgroundRuntimeBootstrapped) return;

  WidgetsFlutterBinding.ensureInitialized();
  ui.DartPluginRegistrant.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (!GetIt.instance.isRegistered<String>(instanceName: 'baseUrl')) {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
      await remoteConfig.fetchAndActivate();
    } catch (e, st) {
      AppLogger.error('백그라운드 Remote Config fetch 실패', e, st);
    }

    final remoteBaseUrl = remoteConfig.getString(FirebaseRemoteService.baseUrl);
    final baseUrl = remoteBaseUrl.trim().isEmpty
        ? 'https://fortuneki.site'
        : remoteBaseUrl;

    await enrollBaseUrlGlobally(baseUrl: baseUrl);
  }

  _backgroundRuntimeBootstrapped = true;
}
