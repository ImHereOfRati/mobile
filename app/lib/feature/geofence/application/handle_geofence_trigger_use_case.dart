import 'package:iamhere/feature/geofence/delivery/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/delivery/geofence_event_filter.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';

enum GeofenceTriggerStatus { queued, notFound, inactive, ignored, rejected }

class GeofenceTriggerResult {
  final GeofenceTriggerStatus status;
  final GeofenceEntity? geofence;

  const GeofenceTriggerResult._(this.status, {this.geofence});

  const GeofenceTriggerResult.queued(GeofenceEntity geofence)
    : this._(GeofenceTriggerStatus.queued, geofence: geofence);

  const GeofenceTriggerResult.notFound()
    : this._(GeofenceTriggerStatus.notFound);

  const GeofenceTriggerResult.inactive(GeofenceEntity geofence)
    : this._(GeofenceTriggerStatus.inactive, geofence: geofence);

  const GeofenceTriggerResult.ignored(GeofenceEntity geofence)
    : this._(GeofenceTriggerStatus.ignored, geofence: geofence);

  const GeofenceTriggerResult.rejected(GeofenceEntity geofence)
    : this._(GeofenceTriggerStatus.rejected, geofence: geofence);
}

class HandleGeofenceTriggerUseCase {
  final GeofenceLocalRepository _repo;
  final GeofenceDeliveryPipeline _pipeline;
  final DateTime Function() _nowLocal;

  HandleGeofenceTriggerUseCase({
    required GeofenceLocalRepository repo,
    required GeofenceDeliveryPipeline pipeline,
    DateTime Function()? nowLocal,
  }) : _repo = repo,
       _pipeline = pipeline,
       _nowLocal = nowLocal ?? DateTime.now;

  Future<GeofenceTriggerResult> execute({
    required int geofenceId,
    required DeliveryEvent deliveryEvent,
  }) async {
    final all = await _repo.findAll();
    final geofence = all.where((g) => g.id == geofenceId).firstOrNull;

    if (geofence == null) {
      return const GeofenceTriggerResult.notFound();
    }

    if (!geofence.isActive) {
      return GeofenceTriggerResult.inactive(geofence);
    }

    final eventType = EventType.fromName(geofence.eventType);
    if (!GeofenceEventFilter.shouldHandle(geofence, eventType, deliveryEvent)) {
      return GeofenceTriggerResult.ignored(geofence);
    }

    final repeat = GeofenceRepeat.fromName(geofence.repeatType);
    final completesBothCycle =
        eventType == EventType.both &&
        deliveryEvent == DeliveryEvent.departure &&
        geofence.awaitingDeparture;
    if (!completesBothCycle &&
        !repeat.allows(_nowLocal(), geofence.customDaysBitmask ?? 0)) {
      return GeofenceTriggerResult.ignored(geofence);
    }

    final accepted = await _pipeline.enqueueTriggeredGeofence(
      geofence: geofence,
      event: deliveryEvent,
    );
    if (!accepted) {
      return GeofenceTriggerResult.rejected(geofence);
    }

    await _applyStateAfterQueueAccepted(
      geofence: geofence,
      eventType: eventType,
      deliveryEvent: deliveryEvent,
    );
    return GeofenceTriggerResult.queued(geofence);
  }

  Future<void> _applyStateAfterQueueAccepted({
    required GeofenceEntity geofence,
    required EventType eventType,
    required DeliveryEvent deliveryEvent,
  }) async {
    if (geofence.id == null) return;

    if (eventType == EventType.both && deliveryEvent == DeliveryEvent.arrival) {
      await _repo.updateAwaitingDeparture(geofence.id!, true);
      return;
    }

    if (GeofenceRepeat.fromName(geofence.repeatType) != GeofenceRepeat.none) {
      if (eventType == EventType.both) {
        await _repo.updateAwaitingDeparture(geofence.id!, false);
      }
      return;
    }

    await _repo.updateActiveStatus(geofence.id!, false);
  }
}
