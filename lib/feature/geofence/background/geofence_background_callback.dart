import 'package:get_it/get_it.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_background_runtime.dart';
import 'package:iamhere/feature/geofence/background/geofence_event_filter.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
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
  final repo = getIt<GeofenceLocalRepository>();
  final pipeline = getIt<GeofenceDeliveryPipeline>();

  final all = await repo.findAll();
  final geofence = all.where((g) => g.id == geofenceId).firstOrNull;

  if (geofence == null) {
    AppLogger.warning('BG_PROCESS: Geofence not found (id=$geofenceId)');
    return;
  }

  if (!geofence.isActive) {
    AppLogger.debug(
      'BG_PROCESS: Geofence already inactive ("${geofence.name}")',
    );
    return;
  }

  final eventType = EventType.fromName(geofence.eventType);
  if (!_shouldHandleEvent(geofence, eventType, deliveryEvent)) {
    AppLogger.debug(
      'BG_PROCESS: Ignored ${deliveryEvent.name} for "${geofence.name}"',
    );
    return;
  }

  AppLogger.debug(
    'BG_PROCESS: Queueing "${geofence.name}" from ${nativeEvent.name}/${deliveryEvent.name}',
  );
  await pipeline.enqueueTriggeredGeofence(geofence: geofence, event: deliveryEvent);
  await _applyGeofenceStateAfterQueueAccepted(
    repo: repo,
    geofence: geofence,
    eventType: eventType,
    deliveryEvent: deliveryEvent,
  );
}

bool _shouldHandleEvent(
  GeofenceEntity geofence,
  EventType eventType,
  DeliveryEvent deliveryEvent,
) => GeofenceEventFilter.shouldHandle(geofence, eventType, deliveryEvent);

Future<void> _applyGeofenceStateAfterQueueAccepted({
  required GeofenceLocalRepository repo,
  required GeofenceEntity geofence,
  required EventType eventType,
  required DeliveryEvent deliveryEvent,
}) async {
  if (geofence.id == null) return;

  if (eventType == EventType.both && deliveryEvent == DeliveryEvent.arrival) {
    await repo.updateAwaitingDeparture(geofence.id!, true);
    return;
  }

  await repo.updateActiveStatus(geofence.id!, false);
}
