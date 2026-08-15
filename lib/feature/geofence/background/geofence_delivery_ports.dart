import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';

abstract interface class DeliveryQueueStore {
  Future<GeofenceDeliveryQueueEntity?> enqueue(
    GeofenceDeliveryQueueEntity entity,
  );

  Future<List<GeofenceDeliveryQueueEntity>> takeDue({int limit = 10});

  Future<bool> claim(int id);

  Future<void> complete(int id);

  Future<void> reschedule({
    required int id,
    required int retryCount,
    required String lastError,
  });
}

abstract interface class GeofenceRecipientResolver {
  Future<List<ContactEntity>> resolveContacts(GeofenceEntity geofence);

  Future<List<GeofenceServerRecipientEntity>> resolveServerRecipients(
    GeofenceEntity geofence,
  );

  List<String> extractPhoneNumbers(List<ContactEntity> contacts);

  List<String> extractServerUserIds(
    List<GeofenceServerRecipientEntity> serverRecipients,
  );
}

abstract interface class GeofenceDeliveryRecordStore {
  Future<void> markGeofenceRecordPending({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    int retryCount = 0,
    String lastError = '',
  });

  Future<void> markGeofenceRecordCompleted({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    int retryCount = 0,
  });

  Future<void> markGeofenceRecordFailed({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    required int retryCount,
    required String lastError,
  });
}

abstract interface class GeofenceLifecycleStore {
  Future<void> updateActiveStatus(int id, bool isActive);

  Future<void> updateAwaitingDeparture(int id, bool awaitingDeparture);
}

abstract interface class RetrySchedulerPort {
  Future<void> scheduleNextIfNeeded({bool replaceExisting = true});
}
