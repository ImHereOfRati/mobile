import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseCloudMessageService {
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    setupForegroundMessageListener();
    // Notification taps are routed directly by the native ShellApp.
  }
}
