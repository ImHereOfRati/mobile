import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 알림 플러그인 인스턴스
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// FCM 백그라운드 메시지 핸들러
///
/// 이 함수는 앱이 백그라운드에 있을 때 FCM 메시지를 처리합니다.
/// - 최상위 함수여야 합니다
/// - 익명 함수가 아니어야 합니다
/// - @pragma('vm:entry-point')로 주석 처리되어야 합니다
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase를 초기화합니다 (백그라운드에서 다른 Firebase 서비스 사용 시 필요)
  await Firebase.initializeApp();

  debugPrint('백그라운드 메시지 수신: ${message.messageId}');
  debugPrint('제목: ${message.notification?.title}');
  debugPrint('내용: ${message.notification?.body}');
  debugPrint('데이터: ${message.data}');
}

/// 로컬 알림 플러그인을 초기화합니다.
Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// FCM 포그라운드 메시지 리스너를 설정합니다.
///
/// 앱이 포그라운드에 있을 때 메시지를 수신하면 호출됩니다.
Future<void> setupForegroundMessageListener() async {
  // 로컬 알림 초기화
  await initializeLocalNotifications();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('포그라운드 메시지 수신: ${message.messageId}');
    debugPrint('제목: ${message.notification?.title}');
    debugPrint('내용: ${message.notification?.body}');
    debugPrint('데이터: ${message.data}');

    // 포그라운드에서 로컬 알림 표시
    if (message.notification != null) {
      await _showNotification(
        title: message.notification!.title ?? '알림',
        body: message.notification!.body ?? '',
      );
    }
  });
}

/// 로컬 알림을 표시합니다.
Future<void> _showNotification({
  required String title,
  required String body,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel', // MainActivity에서 생성한 채널 ID와 동일
    'High Importance Notifications',
    channelDescription: '앱의 중요한 알림을 표시하는 채널입니다',
    importance: Importance.max,
    priority: Priority.high,
    enableVibration: true,
    enableLights: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0, // 알림 ID
    title,
    body,
    notificationDetails,
  );
}

/// 메시지 탭 이벤트를 처리
void setupMessageTapHandler() {
  // 앱이 종료된 상태에서 알림을 탭하여 앱을 열었을 때
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('앱 종료 상태에서 메시지 탭: ${message.messageId}');
    }
  });

  // 앱이 백그라운드 상태에서 알림을 탭하여 앱을 열었을 때
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('백그라운드 상태에서 메시지 탭: ${message.messageId}');
    // 여기서 특정 화면으로 이동하는 등의 처리를 할 수 있습니다
  });
}
