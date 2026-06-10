import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/firebase_options.dart';
import 'package:iamhere/integration/firebase/firebase_service.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';

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
        await _dispatchArrival(id, params.event);
      }
    }
  } catch (e, st) {
    AppLogger.error('BG_CRITICAL: Error in geofenceTriggered', e, st);
  }
}

Future<void> _dispatchArrival(int geofenceId, GeofenceEvent event) async {
  final getIt = GetIt.instance;
  final repo = getIt<GeofenceLocalRepository>();
  final pipeline = getIt<GeofenceDeliveryPipeline>();

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

  AppLogger.debug('BG_PROCESS: Queueing "${geofence.name}" from ${event.name}');
  await pipeline.enqueueTriggeredGeofence(geofence: geofence, event: event);
}
