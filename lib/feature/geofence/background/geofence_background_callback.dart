import 'dart:isolate';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/record_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/firebase_options.dart';
import 'package:iamhere/integration/firebase/firebase_service.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:native_geofence/native_geofence.dart';

bool _backgroundIsolateBootstrapped = false;

/// 백그라운드 아이솔레이트에서 DI / Firebase 를 초기화한다.
Future<void> _bootstrapBackgroundIsolate() async {
  if (_backgroundIsolateBootstrapped) return;

  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.debug('BG_BOOT: Starting...');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.debug('BG_BOOT: Firebase Initialized');
    }
  } catch (e) {
    AppLogger.error('BG_BOOT: Firebase Error', e);
  }

  if (!GetIt.instance.isRegistered<String>(instanceName: 'baseUrl')) {
    try {
      final fbs = FirebaseService();
      await fbs.initialize();
      final String baseUrl =
          fbs.remoteConfig.baseUrlOrNull ?? 'https://fortuneki.site';
      await enrollBaseUrlGlobally(baseUrl: baseUrl);
      _backgroundIsolateBootstrapped = true;
      AppLogger.debug('BG_BOOT: DI Initialized ($baseUrl)');
    } catch (e) {
      AppLogger.error('BG_BOOT: DI Error', e);
    }
    return;
  }

  _backgroundIsolateBootstrapped = true;
  AppLogger.debug('BG_BOOT: Already Initialized');
}

Future<String> _resolveBaseUrlInBackground() async {
  const fallback = 'https://fortuneki.site';
  try {
    final fbs = FirebaseService();
    await fbs.initialize();
    return fbs.remoteConfig.baseUrlOrNull ?? fallback;
  } catch (e) {
    AppLogger.warning('BG_BOOT: RemoteConfig unavailable, using fallback');
    return fallback;
  }
}

/// OS 가 지오펜스 진입 이벤트를 발생시키면 호출되는 최상위 함수.
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  try {
    AppLogger.debug('BG_EVENT: ${params.event}');
    await _bootstrapBackgroundIsolate();

    final allowedEvents = {GeofenceEvent.enter, GeofenceEvent.dwell};
    if (!allowedEvents.contains(params.event)) {
      AppLogger.debug('BG_EVENT: Ignored (${params.event})');
      return;
    }

    for (final zone in params.geofences) {
      final id = int.tryParse(zone.id);
      if (id != null) {
        await _dispatchArrival(id);
      }
    }
  } catch (e, st) {
    AppLogger.error('BG_CRITICAL: Error in geofenceTriggered', e, st);
  }
}

Future<void> _dispatchArrival(int geofenceId) async {
  final getIt = GetIt.instance;
  final repo = getIt<GeofenceLocalRepository>();

  final all = await repo.findAll();
  final geofence = all.where((g) => g.id == geofenceId).firstOrNull;

  if (geofence == null) {
    AppLogger.warning('BG_PROCESS: Geofence not found (id=$geofenceId)');
    return;
  }

  if (!geofence.isActive) {
    AppLogger.debug('BG_PROCESS: Geofence already inactive ("${geofence.name}")');
    return;
  }

  AppLogger.debug('BG_PROCESS: Processing "${geofence.name}"');

  final contactResolver = getIt<ContactResolutionService>();
  final smsNotifier = getIt<SmsNotificationService>();
  final fcmArrival = getIt<FcmArrivalService>();
  final recordService = getIt<RecordService>();

  final localRecipients = await contactResolver.resolveContacts(geofence);
  final serverRecipients =
      await contactResolver.resolveServerRecipients(geofence);

  var anySuccess = false;

  // 1. SMS 전송 시도
  if (localRecipients.isNotEmpty) {
    final numbers = contactResolver.extractPhoneNumbers(localRecipients);
    if (numbers.isNotEmpty) {
      AppLogger.debug('BG_NOTIFY: Sending SMS to ${numbers.length} recipients');
      final r = await smsNotifier.sendSmsToRecipients(
        phoneNumbers: numbers,
        location: geofence.fullLocation,
      );
      if (r is Success) {
        anySuccess = true;
      }
    }
  }

  // 2. FCM 전송 시도
  if (serverRecipients.isNotEmpty) {
    final emails = contactResolver.extractServerEmails(serverRecipients);
    if (emails.isNotEmpty) {
      AppLogger.debug('BG_NOTIFY: Sending FCM to ${emails.length} recipients');
      final body =
          geofence.message.replaceAll('{location}', geofence.fullLocation);
      final r = await fcmArrival.sendArrivalNotifications(
        receiverEmails: emails,
        body: body,
        location: geofence.fullLocation,
      );
      if (r is Success) {
        anySuccess = true;
      }
    }
  }

  // 3. 본인 알림
  if (anySuccess) {
    AppLogger.debug('BG_NOTIFY: Attempting self-notification...');
    await fcmArrival.notifyDeliveryResultToMe(geofence.fullLocation);
  }

  if (!anySuccess) {
    AppLogger.warning('BG_NOTIFY: All notification attempts failed');
  }

  // 4. 기록 저장
  await recordService.saveGeofenceRecord(
    geofence: geofence,
    recipientNames: [
      ...localRecipients.map((c) => c.name),
      ...serverRecipients.map(
          (s) => s.friendAlias.isNotEmpty ? s.friendAlias : s.friendEmail),
    ],
  );

  // 5. 비활성화 및 정리
  try {
    await repo.updateActiveStatus(geofenceId, false);
    await NativeGeofenceManager.instance
        .removeGeofenceById(geofenceId.toString());
    AppLogger.debug('BG_PROCESS: "${geofence.name}" COMPLETED');
  } catch (e) {
    AppLogger.error('BG_PROCESS: Post-dispatch cleanup failed', e);
  }
}
