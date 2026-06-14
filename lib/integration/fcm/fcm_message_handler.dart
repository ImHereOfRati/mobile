import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

GoRouter? _messageTapRouter;
String? _pendingNotificationPath;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ui.DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  AppLogger.debug('Background FCM message received: ${message.messageId}');

  final String title =
      message.notification?.title ?? message.data['title'] ?? 'ImHere 알림';
  final String body = message.notification?.body ?? message.data['body'] ?? '';
  final String? path = extractNotificationPath(message.data);

  if (body.isNotEmpty) {
    await _showNotification(title: title, body: body, payload: path);
  }
}

Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      _handlePayloadNavigation(details.payload);
    },
  );
}

Future<void> setupForegroundMessageListener() async {
  await initializeLocalNotifications();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    AppLogger.debug('Foreground FCM message received: ${message.messageId}');

    final String title =
        message.notification?.title ?? message.data['title'] ?? 'ImHere 알림';
    final String body =
        message.notification?.body ?? message.data['body'] ?? '';
    final String? path = extractNotificationPath(message.data);

    await _saveNotificationToLocal(message, title, body);

    if (body.isNotEmpty) {
      await _showNotification(title: title, body: body, payload: path);
    }
  });
}

Future<void> _saveNotificationToLocal(
  RemoteMessage message,
  String title,
  String body,
) async {
  try {
    final repository = getIt<NotificationLocalRepository>();
    final entity = NotificationEntity(
      title: title,
      body: body,
      senderNickname: message.data['senderNickname'] ?? '',
      senderEmail: message.data['senderEmail'] ?? '',
      createdAt: DateTime.now(),
    );
    await repository.save(entity);
    AppLogger.debug('Notification saved to local DB');
  } catch (e) {
    AppLogger.error('Failed to save notification to local DB: $e');
  }
}

Future<void> _showNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Channel for important notifications',
    importance: Importance.max,
    priority: Priority.high,
    enableVibration: true,
    enableLights: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

void setupMessageTapHandler(GoRouter router) {
  _messageTapRouter = router;
  _drainPendingNotificationPath();

  initializeLocalNotifications().then((_) {
    flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((
      details,
    ) {
      final payload = details?.notificationResponse?.payload;
      _handlePayloadNavigation(payload);
    });
  });

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      AppLogger.debug('Initial FCM tap received: ${message.messageId}');
      _handleNavigation(router, message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    AppLogger.debug('Background tap received: ${message.messageId}');
    _handleNavigation(router, message);
  });
}

void _handleNavigation(GoRouter router, RemoteMessage message) {
  _navigateToPath(router, extractNotificationPath(message.data));
}

String? extractNotificationPath(Map<String, dynamic> data) {
  final candidates = <Object?>[
    data['path'],
    _extractNestedPath(data['extraData']),
    _extractNestedPath(data['extra_data']),
  ];

  for (final candidate in candidates) {
    final path = _normalizePath(candidate as String?);
    if (path != null) return path;
  }

  return null;
}

String? _extractNestedPath(Object? raw) {
  if (raw is Map<String, dynamic>) {
    final nestedPath = raw['path'];
    return nestedPath is String ? nestedPath : null;
  }

  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final nestedPath = decoded['path'];
        return nestedPath is String ? nestedPath : null;
      }
    } catch (_) {
      return trimmed;
    }
  }

  return null;
}

void _handlePayloadNavigation(String? raw) {
  final path = _normalizePath(raw);
  if (path == null) return;

  final router = _messageTapRouter;
  if (router == null) {
    _pendingNotificationPath = path;
    return;
  }

  _navigateToPath(router, path);
}

void _drainPendingNotificationPath() {
  final router = _messageTapRouter;
  final pendingPath = _pendingNotificationPath;
  if (router == null || pendingPath == null) return;

  _pendingNotificationPath = null;
  _navigateToPath(router, pendingPath);
}

void _navigateToPath(GoRouter router, String? raw) {
  final path = _normalizePath(raw);
  if (path == null) return;

  try {
    router.push(path);
  } catch (e) {
    AppLogger.error('Notification navigation failed (path=$path): $e');
  }
}

String? _normalizePath(String? raw) {
  if (raw == null) return null;

  final path = raw.trim();
  if (path.isEmpty || !path.startsWith('/')) {
    AppLogger.error('Invalid notification path: "$raw"');
    return null;
  }

  return path;
}
