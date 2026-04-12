import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iamhere/fcm/fcm_message_handler.dart';

class FirebaseCloudMessageService {
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    setupForegroundMessageListener();
    setupMessageTapHandler();
  }
}