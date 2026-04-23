import 'dart:developer';

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
import 'package:native_geofence/native_geofence.dart';

bool _backgroundIsolateBootstrapped = false;

/// 백그라운드 아이솔레이트에서 DI / Firebase 를 초기화한다.
/// 아이솔레이트는 독립 컨테이너라 매 호출마다 부팅이 필요할 수 있다.
Future<void> _bootstrapBackgroundIsolate() async {
  if (_backgroundIsolateBootstrapped) return;

  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    log('BG: Firebase init failed: $e');
  }

  // GetIt 은 아이솔레이트별 격리이므로 아직 등록되지 않은 경우 재부팅.
  if (!GetIt.instance.isRegistered<String>(instanceName: 'baseUrl')) {
    try {
      final String baseUrl = await _resolveBaseUrlInBackground();
      await enrollBaseUrlGlobally(baseUrl: baseUrl);
      _backgroundIsolateBootstrapped = true;
    } catch (e) {
      log('BG: GetIt init failed: $e');
    }
  } else {
    _backgroundIsolateBootstrapped = true;
  }
}

Future<String> _resolveBaseUrlInBackground() async {
  const fallback = 'http://10.0.2.2:8080';
  try {
    final fbs = FirebaseService();
    await fbs.initialize();
    return fbs.remoteConfig.baseUrlOrNull ?? fallback;
  } catch (e) {
    log('BG: remote config unavailable, using fallback baseUrl: $e');
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
    await _bootstrapBackgroundIsolate();

    final allowedEvents = {GeofenceEvent.enter, GeofenceEvent.dwell};
    if (!allowedEvents.contains(params.event)) {
      log('BG: event ignored: ${params.event}');
      return;
    }

    for (final zone in params.geofences) {
      final id = int.tryParse(zone.id);
      if (id == null) {
        log('BG: invalid geofence id: ${zone.id}');
        continue;
      }
      await _dispatchArrival(id);
    }
  } catch (e, st) {
    log('BG: geofenceTriggered failed: $e\n$st');
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
    log('BG: geofence not found id=$geofenceId');
    return;
  }
  if (!geofence.isActive) {
    log('BG: geofence inactive, ignore id=$geofenceId');
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

  if (localRecipients.isEmpty && serverRecipients.isEmpty) {
    log('BG: no recipients for ${geofence.name}');
    return;
  }

  var anySuccess = false;

  if (localRecipients.isNotEmpty) {
    final numbers = contactResolver.extractPhoneNumbers(localRecipients);
    if (numbers.isNotEmpty) {
      final r = await smsNotifier.sendSmsToRecipients(
        phoneNumbers: numbers,
        location: geofence.fullLocation,
      );
      if (r is Success) anySuccess = true;
    }
  }

  if (serverRecipients.isNotEmpty) {
    final emails = contactResolver.extractServerEmails(serverRecipients);
    if (emails.isNotEmpty) {
      final body = geofence.message.replaceAll(
        '{location}',
        geofence.fullLocation,
      );
      final r = await fcmArrival.sendArrivalNotifications(
        receiverEmails: emails,
        body: body,
        location: geofence.fullLocation,
      );
      if (r is Success) anySuccess = true;
    }
  }

  if (!anySuccess) {
    log('BG: all notifications failed for ${geofence.name}, but proceeding to deactivate');
  }

  final names = <String>[
    ...localRecipients.map((c) => c.name),
    ...serverRecipients.map(
      (s) => s.friendAlias.isNotEmpty ? s.friendAlias : s.friendEmail,
    ),
  ];
  await recordService.saveGeofenceRecord(
    geofence: geofence,
    recipientNames: names,
  );

  try {
    await repo.updateActiveStatus(geofenceId, false);
    // OS 에서도 제거하여 중복 트리거를 방지.
    await NativeGeofenceManager.instance.removeGeofenceById(
      geofenceId.toString(),
    );
    log('BG: dispatched + deactivated id=$geofenceId');
  } catch (e) {
    log('BG: post-dispatch cleanup failed: $e');
  }
}

