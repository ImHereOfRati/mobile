import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:iamhere/common/config/app_env.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/firebase_options.dart';

import 'firebase_cloud_message_service.dart';
import 'firebase_crashlytics_service.dart';
import 'firebase_remote_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseRemoteService remoteConfig;
  late final FirebaseCrashlyticsService crashlyticsService;
  late final FirebaseCloudMessageService fcmService;

  Future<void> initialize() async {
    await AppEnv.ensureLoaded();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    crashlyticsService = FirebaseCrashlyticsService();
    fcmService = FirebaseCloudMessageService();
    remoteConfig = FirebaseRemoteService();

    await crashlyticsService.initialize();
    // Neither notification permission nor remote config should block the
    // first Flutter frame. Both have safe local fallbacks and finish in the
    // background after Firebase itself is ready.
    unawaited(_initializeFcmInBackground());
    unawaited(_initializeRemoteConfigInBackground());
  }

  Future<void> _initializeFcmInBackground() async {
    try {
      await fcmService.initialize();
    } catch (error, stack) {
      AppLogger.error('Firebase Messaging initialization failed', error, stack);
    }
  }

  Future<void> _initializeRemoteConfigInBackground() async {
    try {
      await remoteConfig.initialize();
    } catch (_) {
      // Remote Config is optional; callers use build-time fallbacks.
    }
  }
}
