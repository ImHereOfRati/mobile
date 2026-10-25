import 'package:iamhere/feature/geofence/delivery/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';

class GeofenceDeliveryPolicy {
  const GeofenceDeliveryPolicy._();

  static const int maxRetryCount = 4;
}

class DeliverySuccessPolicy {
  const DeliverySuccessPolicy();

  bool shouldComplete({
    required GeofenceDeliverySnapshot snapshot,
    required bool anyChannelSucceeded,
  }) {
    return anyChannelSucceeded || !hasRecipients(snapshot);
  }

  bool hasRecipients(GeofenceDeliverySnapshot snapshot) {
    return snapshot.smsPhoneNumbers.isNotEmpty ||
        snapshot.serverUserIds.isNotEmpty;
  }
}

class DeliveryRetryPolicy {
  final int maxRetryCount;

  const DeliveryRetryPolicy({
    this.maxRetryCount = GeofenceDeliveryPolicy.maxRetryCount,
  });

  bool isTerminalFailure(int retryCount) => retryCount > maxRetryCount;
}

abstract class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

class DedupePolicy {
  final Duration bucketDuration;

  const DedupePolicy({this.bucketDuration = const Duration(seconds: 5)});

  String buildKey({
    required int geofenceId,
    required DeliveryEvent event,
    required DateTime nowUtc,
  }) {
    final bucket =
        nowUtc.toUtc().millisecondsSinceEpoch ~/ bucketDuration.inMilliseconds;
    return '$geofenceId:${event.name}:$bucket';
  }
}

enum GeofenceLifecycleAction {
  markAwaitingDeparture,
  clearAwaitingDeparture,
  deactivate,
  restoreActive,
  none,
}

class GeofenceLifecyclePolicy {
  const GeofenceLifecyclePolicy();

  GeofenceLifecycleAction afterSuccessfulDelivery(
    GeofenceDeliverySnapshot snapshot,
  ) {
    if (snapshot.geofence.id == null) return GeofenceLifecycleAction.none;

    final configuredEventType = EventType.fromName(snapshot.geofence.eventType);
    final deliveryEvent = DeliveryEvent.fromStoredName(
      snapshot.deliveryEventType,
    );

    if (configuredEventType == EventType.both &&
        deliveryEvent == DeliveryEvent.arrival) {
      return GeofenceLifecycleAction.markAwaitingDeparture;
    }

    if (GeofenceRepeat.fromName(snapshot.geofence.repeatType) !=
        GeofenceRepeat.none) {
      return configuredEventType == EventType.both
          ? GeofenceLifecycleAction.clearAwaitingDeparture
          : GeofenceLifecycleAction.none;
    }

    return GeofenceLifecycleAction.deactivate;
  }

  GeofenceLifecycleAction afterTerminalFailure(
    GeofenceDeliverySnapshot snapshot,
  ) {
    if (snapshot.geofence.id == null) return GeofenceLifecycleAction.none;

    final configuredEventType = EventType.fromName(snapshot.geofence.eventType);
    final deliveryEvent = DeliveryEvent.fromStoredName(
      snapshot.deliveryEventType,
    );

    if (configuredEventType == EventType.both &&
        deliveryEvent == DeliveryEvent.arrival) {
      return GeofenceLifecycleAction.clearAwaitingDeparture;
    }

    if (GeofenceRepeat.fromName(snapshot.geofence.repeatType) !=
        GeofenceRepeat.none) {
      return GeofenceLifecycleAction.none;
    }

    return GeofenceLifecycleAction.restoreActive;
  }
}
