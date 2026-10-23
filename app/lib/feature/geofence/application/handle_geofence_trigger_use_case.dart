import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_event_filter.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';

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

  const HandleGeofenceTriggerUseCase({
    required GeofenceLocalRepository repo,
    required GeofenceDeliveryPipeline pipeline,
  }) : _repo = repo,
       _pipeline = pipeline;

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

    await _repo.updateActiveStatus(geofence.id!, false);
  }
}
