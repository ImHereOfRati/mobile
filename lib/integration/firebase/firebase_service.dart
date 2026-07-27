import 'package:firebase_core/firebase_core.dart';
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    crashlyticsService = FirebaseCrashlyticsService();
    fcmService = FirebaseCloudMessageService();
    remoteConfig = FirebaseRemoteService();

    await crashlyticsService.initialize();
    await fcmService.initialize();
    try {
      await remoteConfig.initialize();
    } catch (_) {
      // Remote Config is an optional rollout source. Callers use build-time
      // fallbacks when the latest values cannot be fetched.
    }
  }
}
