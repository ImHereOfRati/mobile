import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository.dart';

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

    // 알림을 로컬 DB에 저장
    await _saveNotificationToLocal(message);

    // 포그라운드에서 로컬 알림 표시
    if (message.notification != null) {
      await _showNotification(
        title: message.notification!.title ?? '알림',
        body: message.notification!.body ?? '',
      );
    }
  });
}

/// FCM 메시지를 로컬 DB에 저장합니다.
Future<void> _saveNotificationToLocal(RemoteMessage message) async {
  try {
    final repository = getIt<NotificationLocalRepository>();
    final entity = NotificationEntity(
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      senderNickname: message.data['senderNickname'] ?? '',
      senderEmail: message.data['senderEmail'] ?? '',
      createdAt: DateTime.now(),
    );
    await repository.save(entity);
    debugPrint('알림 로컬 DB 저장 완료');
  } catch (e) {
    debugPrint('알림 로컬 DB 저장 실패: $e');
  }
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

/// 알림 탭 시 `data['path']`를 읽어 GoRouter로 이동시킨다.
///
/// - 백그라운드 상태에서 탭: `onMessageOpenedApp` 스트림 사용
/// - 종료 상태에서 탭하여 앱 콜드 스타트: `getInitialMessage()` 사용
///
/// 인증 상태는 `RouterLogic.handleRedirect`가 자동 처리하므로
/// 로그인이 안 된 사용자는 자동으로 `/auth`로 리다이렉트된다.
void setupMessageTapHandler(GoRouter router) {
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('앱 종료 상태에서 메시지 탭: ${message.messageId}');
      _handleNavigation(router, message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('백그라운드 상태에서 메시지 탭: ${message.messageId}');
    _handleNavigation(router, message);
  });
}

void _handleNavigation(GoRouter router, RemoteMessage message) {
  final raw = message.data['path'];
  if (raw is! String) return;

  final path = raw.trim();
  if (path.isEmpty || !path.startsWith('/')) {
    debugPrint('알림 path 형식 오류: "$raw"');
    return;
  }

  try {
    router.push(path);
  } catch (e) {
    debugPrint('알림 네비게이션 실패 (path=$path): $e');
  }
}
