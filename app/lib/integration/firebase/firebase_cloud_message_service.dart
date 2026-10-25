import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseCloudMessageService {
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    setupForegroundMessageListener();
    // 알림 탭 경로는 ShellApp이 WebView 이벤트 브릿지에 연결한다.
  }
}
