import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:iamhere/common/util/app_logger.dart';

class FirebaseCloudMessageService {
  Future<void> initialize() async {
    await _requestNotificationPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    setupForegroundMessageListener();
    // 알림 탭 경로는 ShellApp이 WebView 이벤트 브릿지에 연결한다.
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.debug('알림 권한 상태: ${settings.authorizationStatus}');
  }
}
