import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/record_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';
import 'package:iamhere/firebase_options.dart';
import 'package:iamhere/integration/firebase/firebase_service.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:native_geofence/native_geofence.dart';

bool _backgroundIsolateBootstrapped = false;

/// 백그라운드 아이솔레이트에서 DI / Firebase 를 초기화한다.
/// 아이솔레이트는 독립 컨테이너라 매 호출마다 부팅이 필요할 수 있다.
Future<void> _bootstrapBackgroundIsolate() async {
  if (_backgroundIsolateBootstrapped) return;

  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.debug('BG: Bootstrapping background isolate...');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.debug('BG: Firebase initialized');
    }
  } catch (e) {
    AppLogger.error('BG: Firebase init failed', e);
  }

  // GetIt 은 아이솔레이트별 격리이므로 아직 등록되지 않은 경우 재부팅.
  if (!GetIt.instance.isRegistered<String>(instanceName: 'baseUrl')) {
    try {
      final String baseUrl = await _resolveBaseUrlInBackground();
      await enrollBaseUrlGlobally(baseUrl: baseUrl);
      _backgroundIsolateBootstrapped = true;
      AppLogger.debug('BG: DI (GetIt) initialized with baseUrl: $baseUrl');
    } catch (e) {
      AppLogger.error('BG: GetIt init failed', e);
    }
  } else {
    _backgroundIsolateBootstrapped = true;
    AppLogger.debug('BG: DI already initialized');
  }
}

Future<String> _resolveBaseUrlInBackground() async {
  const fallback = 'http://10.0.2.2:8080';
  try {
    final fbs = FirebaseService();
    await fbs.initialize();
    return fbs.remoteConfig.baseUrlOrNull ?? fallback;
  } catch (e) {
    AppLogger.warning('BG: remote config unavailable, using fallback baseUrl: $e');
    return fallback;
  }
}

/// OS 가 지오펜스 진입 이벤트를 발생시키면 호출되는 최상위 함수.
///
/// - 반드시 `@pragma('vm:entry-point')` 가 부여되어야 AOT 빌드에서 호출 가능.
/// - `native_geofence` 플러그인이 백그라운드 FlutterEngine 을 띄워 호출.
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  try {
    AppLogger.debug('BG: Geofence triggered event: ${params.event}');
    await _bootstrapBackgroundIsolate();

    final allowedEvents = {GeofenceEvent.enter, GeofenceEvent.dwell};
    if (!allowedEvents.contains(params.event)) {
      AppLogger.debug('BG: Event ignored (not enter/dwell): ${params.event}');
      return;
    }

    AppLogger.debug('BG: Number of geofences triggered: ${params.geofences.length}');
    for (final zone in params.geofences) {
      final id = int.tryParse(zone.id);
      if (id == null) {
        AppLogger.warning('BG: Invalid geofence id format: ${zone.id}');
        continue;
      }
      await _dispatchArrival(id);
    }
  } catch (e, st) {
    AppLogger.error('BG: geofenceTriggered critical failure', e, st);
  }
}

Future<void> _dispatchArrival(int geofenceId) async {
  final getIt = GetIt.instance;
  final repo = getIt<GeofenceLocalRepository>();

  final all = await repo.findAll();
  GeofenceEntity? geofence;
  for (final g in all) {
    if (g.id == geofenceId) {
      geofence = g;
      break;
    }
  }

  if (geofence == null) {
    AppLogger.warning('BG: Geofence not found in DB for ID: $geofenceId');
    return;
  }
  
  AppLogger.debug('BG: Processing arrival for "${geofence.name}" (ID: $geofenceId)');

  if (!geofence.isActive) {
    AppLogger.debug('BG: Geofence "${geofence.name}" is already inactive, ignoring');
    return;
  }

  final contactResolver = getIt<ContactResolutionService>();
  final smsNotifier = getIt<SmsNotificationService>();
  final fcmArrival = getIt<FcmArrivalService>();
  final recordService = getIt<RecordService>();

  final localRecipients = await contactResolver.resolveContacts(geofence);
  final serverRecipients = await contactResolver.resolveServerRecipients(
    geofence,
  );

  AppLogger.debug('BG: Resolved recipients - SMS: ${localRecipients.length}, Server: ${serverRecipients.length}');

  if (localRecipients.isEmpty && serverRecipients.isEmpty) {
    AppLogger.warning('BG: No recipients found for "${geofence.name}", skipping notifications');
    return;
  }

  // 알림 전송 시도 (성공 여부에 관계없이 이후 비활성화 진행)
  if (localRecipients.isNotEmpty) {
    final numbers = contactResolver.extractPhoneNumbers(localRecipients);
    if (numbers.isNotEmpty) {
      AppLogger.debug('BG: Sending SMS to ${numbers.length} numbers...');
      final r = await smsNotifier.sendSmsToRecipients(
        phoneNumbers: numbers,
        location: geofence.fullLocation,
      );
      if (r is Success) {
        AppLogger.debug('BG: SMS sent successfully');
      } else {
        AppLogger.error('BG: SMS sending failed: ${(r as Failure).message}');
      }
    }
  }

  if (serverRecipients.isNotEmpty) {
    final emails = contactResolver.extractServerEmails(serverRecipients);
    if (emails.isNotEmpty) {
      AppLogger.debug('BG: Sending FCM notifications to ${emails.length} emails...');
      final body = geofence.message.replaceAll(
        '{location}',
        geofence.fullLocation,
      );
      final r = await fcmArrival.sendArrivalNotifications(
        receiverEmails: emails,
        body: body,
        location: geofence.fullLocation,
      );
      if (r is Success) {
        AppLogger.debug('BG: FCM notifications sent successfully');
      } else {
        AppLogger.error('BG: FCM notifications failed: ${(r as Failure).message}');
      }
    }
  }

  final names = <String>[
    ...localRecipients.map((c) => c.name),
    ...serverRecipients.map(
      (s) => s.friendAlias.isNotEmpty ? s.friendAlias : s.friendEmail,
    ),
  ];
  
  AppLogger.debug('BG: Saving arrival record...');
  await recordService.saveGeofenceRecord(
    geofence: geofence,
    recipientNames: names,
  );

  try {
    AppLogger.debug('BG: Deactivating geofence ID: $geofenceId from DB and OS (Request initiated)');
    await repo.updateActiveStatus(geofenceId, false);
    // OS 에서도 제거하여 중복 트리거를 방지.
    await NativeGeofenceManager.instance.removeGeofenceById(
      geofenceId.toString(),
    );
    AppLogger.debug('BG: Process completed and deactivated for "${geofence.name}"');
  } catch (e) {
    AppLogger.error('BG: Post-dispatch cleanup failed', e);
  }
}

