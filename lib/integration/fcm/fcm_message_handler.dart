import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_background_runtime.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/integration/fcm/fcm_notification_policy.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

FutureOr<void> Function(String path)? _shellPathHandler;
String? _pendingNotificationPath;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ui.DartPluginRegistrant.ensureInitialized();
  await bootstrapBackgroundRuntime();

  AppLogger.debug('Background FCM message received: ${message.messageId}');

  final String title =
      message.notification?.title ?? message.data['title'] ?? 'ImHere 알림';
  final String body = message.notification?.body ?? message.data['body'] ?? '';
  final String? path = extractNotificationPath(message.data);
  final String channelId = resolveFcmChannelId(_messageType(message));

  await _saveNotificationToLocal(message, title, body, path);

  if (body.isNotEmpty) {
    await _showNotification(
      title: title,
      body: body,
      payload: path,
      channelId: channelId,
      notificationId: _notificationId(message),
    );
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
    if (body.isNotEmpty) {
      await _showNotification(
        title: title,
        body: body,
        payload: path,
        channelId: resolveFcmChannelId(_messageType(message)),
        notificationId: _notificationId(message),
      );
    }
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
      senderAlias: message.data['senderAlias'] ?? '',
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
  required int notificationId,
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
    notificationId,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

String? _messageType(RemoteMessage message) {
  final type = message.data['type'];
  return type is String ? type : null;
}

int _notificationId(RemoteMessage message) {
  final seed = Object.hash(message.messageId, message.sentTime);
  return seed & 0x7fffffff;
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
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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

void setupShellMessageTapHandler(FutureOr<void> Function(String path) onPath) {
  _shellPathHandler = onPath;
  _drainPendingNotificationPath();

  initializeLocalNotifications().then((_) {
    flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((
      details,
    ) {
      _handlePayloadNavigation(details?.notificationResponse?.payload);
    });
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      _dispatchPath(extractNotificationPath(message.data));
    }
  });
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _dispatchPath(extractNotificationPath(message.data));
  });
}

String? extractNotificationPath(Map<String, dynamic> data) {
  final type = data['type'];
  return type is String ? resolveFcmNotificationPath(type) : null;
}

void _handlePayloadNavigation(String? raw) {
  final path = _normalizePath(raw);
  if (path == null) return;

  if (_shellPathHandler != null) {
    _dispatchPath(path);
    return;
  }
  _pendingNotificationPath = path;
}

void _drainPendingNotificationPath() {
  final pendingPath = _pendingNotificationPath;
  if (pendingPath == null) return;

  if (_shellPathHandler != null) {
    _pendingNotificationPath = null;
    _dispatchPath(pendingPath);
    return;
  }
}

void _dispatchPath(String? raw) {
  final path = _normalizePath(raw);
  if (path == null) return;
  final handler = _shellPathHandler;
  if (handler == null) {
    _pendingNotificationPath = path;
    return;
  }
  Future<void>.sync(() => handler(path)).catchError(
    (error, stack) => AppLogger.error(
      'Notification shell navigation failed (path=$path)',
      error,
      stack,
    ),
  );
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
