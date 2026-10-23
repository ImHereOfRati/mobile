import 'package:get_it/get_it.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/application/handle_geofence_trigger_use_case.dart';
import 'package:iamhere/feature/geofence/background/geofence_background_runtime.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';

/// OS 가 지오펜스 진입 이벤트를 발생시키면 호출되는 최상위 함수.
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  try {
    AppLogger.debug('BG_EVENT: ${params.event}');
    await bootstrapBackgroundRuntime();

    final deliveryEvent = DeliveryEvent.fromNativeEvent(params.event);
    if (deliveryEvent == null) {
      AppLogger.debug('BG_EVENT: Ignored (${params.event})');
      return;
    }

    for (final zone in params.geofences) {
      final id = int.tryParse(zone.id);
      if (id != null) {
        await _dispatchTriggeredEvent(id, params.event, deliveryEvent);
      }
    }
  } catch (e, st) {
    AppLogger.error('BG_CRITICAL: Error in geofenceTriggered', e, st);
  }
}

Future<void> _dispatchTriggeredEvent(
  int geofenceId,
  GeofenceEvent nativeEvent,
  DeliveryEvent deliveryEvent,
) async {
  final getIt = GetIt.instance;
  final result = await HandleGeofenceTriggerUseCase(
    repo: getIt<GeofenceLocalRepository>(),
    pipeline: getIt<GeofenceDeliveryPipeline>(),
  ).execute(geofenceId: geofenceId, deliveryEvent: deliveryEvent);

  switch (result.status) {
    case GeofenceTriggerStatus.queued:
      AppLogger.debug(
        'BG_PROCESS: Queued "${result.geofence!.name}" from '
        '${nativeEvent.name}/${deliveryEvent.name}',
      );
      break;
    case GeofenceTriggerStatus.notFound:
      AppLogger.warning('BG_PROCESS: Geofence not found (id=$geofenceId)');
      break;
    case GeofenceTriggerStatus.inactive:
      AppLogger.debug(
        'BG_PROCESS: Geofence already inactive ("${result.geofence!.name}")',
      );
      break;
    case GeofenceTriggerStatus.ignored:
      AppLogger.debug(
        'BG_PROCESS: Ignored ${deliveryEvent.name} for '
        '"${result.geofence!.name}"',
      );
      break;
    case GeofenceTriggerStatus.rejected:
      AppLogger.debug(
        'BG_PROCESS: Queue rejected duplicate or invalid event for '
        '"${result.geofence!.name}"',
      );
      break;
  }
}
