import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/integration/fcm/fcm_notification_policy.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

GoRouter? _messageTapRouter;
String? _pendingNotificationPath;
final List<_PendingForegroundBanner> _pendingForegroundBanners = [];

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ui.DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  AppLogger.debug('Background FCM message received: ${message.messageId}');

  final String title =
      message.notification?.title ?? message.data['title'] ?? 'ImHere 알림';
  final String body = message.notification?.body ?? message.data['body'] ?? '';
  final String? path = extractNotificationPath(message.data);
  final String channelId = resolveFcmChannelId(message.data['type'] as String?);

  if (body.isNotEmpty) {
    await _showNotification(title: title, body: body, payload: path, channelId: channelId);
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

  await _ensureAndroidNotificationChannels();
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

    await _saveNotificationToLocal(message, title, body, path);
    await _showForegroundBanner(title: title, body: body, path: path);
  });
}

Future<void> _saveNotificationToLocal(
  RemoteMessage message,
  String title,
  String body,
  String? path,
) async {
  try {
    final repository = getIt<NotificationLocalRepository>();
    final entity = NotificationEntity(
      title: title,
      body: body,
      senderNickname: message.data['senderNickname'] ?? '',
      senderEmail: message.data['senderEmail'] ?? '',
      path: path ?? '',
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
  required String channelId,
}) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    _channelName(channelId),
    channelDescription: _channelDescription(channelId),
    importance: _channelImportance(channelId),
    priority: _channelPriority(channelId),
    enableVibration: channelId != silentChannelId,
    enableLights: channelId != silentChannelId,
  );

  final NotificationDetails notificationDetails = NotificationDetails(
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

Future<void> _showForegroundBanner({
  required String title,
  required String body,
  String? path,
}) async {
  final context = _messageTapRouter?.routerDelegate.navigatorKey.currentContext;
  if (context == null) {
    _pendingForegroundBanners.add(_PendingForegroundBanner(title: title, body: body, path: path));
    return;
  }

  _showBanner(context, title: title, body: body, path: path);
}

void _showBanner(
  BuildContext context, {
  required String title,
  required String body,
  String? path,
}) {
  AppSnackBar.showNotificationBanner(context, title: title, message: body);

  if (path != null) {
    AppLogger.debug('Foreground FCM banner queued with path: $path');
  }
}

String _channelName(String channelId) {
  switch (channelId) {
    case criticalChannelId:
      return '중요 알림';
    case highChannelId:
      return '중요한 알림';
    case normalChannelId:
      return '일반 알림';
    case silentChannelId:
      return '조용한 알림';
    default:
      return '알림';
  }
}

String _channelDescription(String channelId) {
  switch (channelId) {
    case criticalChannelId:
      return '도착, 출발 등 즉시 확인이 필요한 알림';
    case highChannelId:
      return '친구 요청, 위치 공유 알림';
    case normalChannelId:
      return '일반적인 상태 변경 알림';
    case silentChannelId:
      return '결과 확인용 알림';
    default:
      return 'Notification channel';
  }
}

Importance _channelImportance(String channelId) {
  switch (channelId) {
    case criticalChannelId:
      return Importance.max;
    case highChannelId:
      return Importance.high;
    case normalChannelId:
      return Importance.defaultImportance;
    case silentChannelId:
      return Importance.low;
    default:
      return Importance.defaultImportance;
  }
}

Priority _channelPriority(String channelId) {
  switch (channelId) {
    case criticalChannelId:
    case highChannelId:
    case normalChannelId:
      return Priority.high;
    case silentChannelId:
      return Priority.low;
    default:
      return Priority.defaultPriority;
  }
}

Future<void> _ensureAndroidNotificationChannels() async {
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin == null) return;

  const channels = <AndroidNotificationChannel>[
    AndroidNotificationChannel(
      criticalChannelId,
      '중요 알림',
      description: '도착, 출발 등 즉시 확인이 필요한 알림',
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      highChannelId,
      '중요한 알림',
      description: '친구 요청, 위치 공유 알림',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      normalChannelId,
      '일반 알림',
      description: '일반적인 상태 변경 알림',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      silentChannelId,
      '조용한 알림',
      description: '결과 확인용 알림',
      importance: Importance.low,
    ),
  ];

  for (final channel in channels) {
    await androidPlugin.createNotificationChannel(channel);
  }
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

  _drainPendingForegroundBanners();
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

void _drainPendingForegroundBanners() {
  final context = _messageTapRouter?.routerDelegate.navigatorKey.currentContext;
  if (context == null || _pendingForegroundBanners.isEmpty) return;

  for (final banner in List<_PendingForegroundBanner>.from(_pendingForegroundBanners)) {
    _showBanner(context, title: banner.title, body: banner.body, path: banner.path);
  }
  _pendingForegroundBanners.clear();
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

String composeForegroundNotificationMessage(String title, String body) {
  if (body.trim().isEmpty) return title;
  return '$title\n$body';
}

class _PendingForegroundBanner {
  final String title;
  final String body;
  final String? path;

  _PendingForegroundBanner({required this.title, required this.body, required this.path});
}
