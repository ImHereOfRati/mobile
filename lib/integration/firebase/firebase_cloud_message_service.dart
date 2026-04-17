import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';

class FirebaseCloudMessageService {
  Future<void> initialize() async {
    await _requestNotificationPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    setupForegroundMessageListener();
    setupMessageTapHandler();
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('알림 권한 상태: ${settings.authorizationStatus}');
  }
}
