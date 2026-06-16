import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_policy.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_database_service.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/service/record_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';

class GeofenceDeliveryPipeline {
  final GeofenceDeliveryQueueDatabaseService _queue;
  final ContactResolutionService _contactResolutionService;
  final GeofenceLocalRepository _geofenceRepository;
  final NativeGeofenceRegistrarInterface _registrar;
  final SmsNotificationService _smsNotificationService;
  final FcmArrivalService _fcmArrivalService;
  final RecordService _recordService;
  final GeofenceRetryScheduler _retryScheduler;
  Future<void>? _drainInFlight;

  GeofenceDeliveryPipeline(
    this._queue,
    this._contactResolutionService,
    this._geofenceRepository,
    this._registrar,
    this._smsNotificationService,
    this._fcmArrivalService,
    this._recordService,
    this._retryScheduler,
  );

  Future<void> enqueueTriggeredGeofence({
    required GeofenceEntity geofence,
    required DeliveryEvent event,
  }) async {
    if (geofence.id == null) return;

    final localRecipients = await _contactResolutionService.resolveContacts(
      geofence,
    );
    final serverRecipients = await _contactResolutionService
        .resolveServerRecipients(geofence);

    final snapshot = GeofenceDeliverySnapshot(
      geofence: geofence,
      recipientNames: [
        ...localRecipients.map((contact) => contact.name),
        ...serverRecipients.map(
          (recipient) => recipient.friendAlias.isNotEmpty
              ? recipient.friendAlias
              : recipient.friendEmail,
        ),
      ],
      smsPhoneNumbers: _contactResolutionService.extractPhoneNumbers(
        localRecipients,
      ),
      serverEmails: _contactResolutionService.extractServerEmails(
        serverRecipients,
      ),
      deliveryEventType: event.name,
    );

    final body = _buildMessageBody(snapshot);
    final entity = GeofenceDeliveryQueueEntity(
      dedupeKey: _buildDedupeKey(geofence.id!, event),
      snapshotJson: snapshot.toJson(),
      status: GeofenceDeliveryQueueEntity.pending,
      retryCount: 0,
      nextAttemptAt: DateTime.now().toUtc(),
      lastError: '',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    await _queue.enqueue(entity);
    await _recordService.markGeofenceRecordPending(
      geofence: geofence,
      recipientNames: snapshot.recipientNames,
      deliveryKey: entity.dedupeKey,
      message: body,
      deliveryEventType: event.name,
    );
    await processPending();
    await _retryScheduler.scheduleNextIfNeeded();
  }

  Future<void> processPending({int limit = 10}) {
    final inFlight = _drainInFlight;
    if (inFlight != null) return inFlight;

    final future = _processPendingInternal(limit: limit);
    _drainInFlight = future;
    return future.whenComplete(() => _drainInFlight = null);
  }

  Future<void> _processPendingInternal({int limit = 10}) async {
    while (true) {
      final dueItems = await _queue.takeDue(limit: limit);
      if (dueItems.isEmpty) return;
      for (final item in dueItems) {
        await _processItem(item);
      }
    }
  }

  Future<void> _processItem(GeofenceDeliveryQueueEntity item) async {
    if (!await _queue.claim(item.id!)) return;

    final snapshot = item.snapshot;
    final body = _buildMessageBody(snapshot);
    try {
      final anySuccess = await _sendSnapshot(snapshot, body: body);
      if (anySuccess || _hasNoRecipients(snapshot)) {
        await _recordService.markGeofenceRecordCompleted(
          geofence: snapshot.geofence,
          recipientNames: snapshot.recipientNames,
          deliveryKey: item.dedupeKey,
          message: body,
          deliveryEventType: snapshot.deliveryEventType,
          retryCount: item.retryCount,
        );
        await _queue.complete(item.id!);
        await _completeLifecycleAfterSuccess(snapshot);
        AppLogger.debug('BG_QUEUE: completed geofence delivery ${item.id}');
      } else {
        await _handleRetryFailure(
          item: item,
          snapshot: snapshot,
          body: body,
          lastError: 'All delivery attempts failed',
        );
      }
    } catch (e) {
      await _handleRetryFailure(
        item: item,
        snapshot: snapshot,
        body: body,
        lastError: e.toString(),
      );
      AppLogger.error('BG_QUEUE: processing failed', e);
    }
  }

  Future<void> _handleRetryFailure({
    required GeofenceDeliveryQueueEntity item,
    required GeofenceDeliverySnapshot snapshot,
    required String body,
    required String lastError,
  }) async {
    final nextRetryCount = item.retryCount + 1;

    if (_isTerminalFailure(nextRetryCount)) {
      await _recordService.markGeofenceRecordFailed(
        geofence: snapshot.geofence,
        recipientNames: snapshot.recipientNames,
        deliveryKey: item.dedupeKey,
        message: body,
        deliveryEventType: snapshot.deliveryEventType,
        retryCount: nextRetryCount,
        lastError: lastError,
      );
      await _queue.complete(item.id!);
      await _rollbackLifecycleAfterTerminalFailure(snapshot);
      AppLogger.error(
        'BG_QUEUE: permanently failed geofence delivery ${item.id} ($lastError)',
      );
      return;
    }

    await _recordService.markGeofenceRecordPending(
      geofence: snapshot.geofence,
      recipientNames: snapshot.recipientNames,
      deliveryKey: item.dedupeKey,
      message: body,
      deliveryEventType: snapshot.deliveryEventType,
      retryCount: nextRetryCount,
      lastError: lastError,
    );
    await _queue.reschedule(
      id: item.id!,
      retryCount: nextRetryCount,
      lastError: lastError,
    );
    AppLogger.warning('BG_QUEUE: rescheduled geofence delivery ${item.id}');
  }

  bool _isTerminalFailure(int retryCount) =>
      retryCount > GeofenceDeliveryPolicy.maxRetryCount;

  Future<bool> _sendSnapshot(
    GeofenceDeliverySnapshot snapshot, {
    required String body,
  }) async {
    var anySuccess = false;
    final event = DeliveryEvent.fromStoredName(snapshot.deliveryEventType);

    if (snapshot.smsPhoneNumbers.isNotEmpty) {
      final smsResult = await _smsNotificationService.sendSmsToRecipients(
        phoneNumbers: snapshot.smsPhoneNumbers,
        body: body,
        location: snapshot.geofence.fullLocation,
        type: event.notificationType,
      );
      if (smsResult is Success) anySuccess = true;
    }

    if (snapshot.serverEmails.isNotEmpty) {
      final fcmResult = await _fcmArrivalService.sendGeofenceNotifications(
        receiverEmails: snapshot.serverEmails,
        body: body,
        location: snapshot.geofence.fullLocation,
        type: event.notificationType,
      );
      if (fcmResult is Success) anySuccess = true;
    }

    return anySuccess;
  }

  String _buildMessageBody(GeofenceDeliverySnapshot snapshot) {
    final event = DeliveryEvent.fromStoredName(snapshot.deliveryEventType);
    final template = snapshot.geofence.message.trim().isEmpty
        ? event.defaultMessageTemplate
        : snapshot.geofence.message.trim();
    return template.replaceAll('{location}', snapshot.geofence.fullLocation);
  }

  bool _hasNoRecipients(GeofenceDeliverySnapshot snapshot) =>
      snapshot.smsPhoneNumbers.isEmpty && snapshot.serverEmails.isEmpty;

  Future<void> _completeLifecycleAfterSuccess(
    GeofenceDeliverySnapshot snapshot,
  ) async {
    final geofenceId = snapshot.geofence.id;
    if (geofenceId == null) return;

    final configuredEventType = EventType.fromName(snapshot.geofence.eventType);
    final deliveryEvent = DeliveryEvent.fromStoredName(
      snapshot.deliveryEventType,
    );

    if (configuredEventType == EventType.both &&
        deliveryEvent == DeliveryEvent.arrival) {
      await _geofenceRepository.updateAwaitingDeparture(geofenceId, true);
      return;
    }

    await _deactivateGeofence(geofenceId);
  }

  Future<void> _rollbackLifecycleAfterTerminalFailure(
    GeofenceDeliverySnapshot snapshot,
  ) async {
    final geofenceId = snapshot.geofence.id;
    if (geofenceId == null) return;

    final configuredEventType = EventType.fromName(snapshot.geofence.eventType);
    final deliveryEvent = DeliveryEvent.fromStoredName(
      snapshot.deliveryEventType,
    );

    if (configuredEventType == EventType.both &&
        deliveryEvent == DeliveryEvent.arrival) {
      await _geofenceRepository.updateAwaitingDeparture(geofenceId, false);
      return;
    }

    try {
      await _geofenceRepository.updateActiveStatus(geofenceId, true);
      await _registrar.register(snapshot.geofence.copyWith(isActive: true));
    } catch (e) {
      AppLogger.error('BG_QUEUE: failed to restore geofence $geofenceId', e);
    }
  }

  Future<void> _deactivateGeofence(int geofenceId) async {
    try {
      await _geofenceRepository.updateActiveStatus(geofenceId, false);
    } catch (e) {
      AppLogger.error('BG_QUEUE: failed to deactivate geofence $geofenceId', e);
    }

    try {
      await _registrar.unregister(geofenceId);
    } catch (e) {
      AppLogger.error('BG_QUEUE: failed to unregister geofence $geofenceId', e);
    }
  }

  String _buildDedupeKey(int geofenceId, DeliveryEvent event) {
    final bucket = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 5000;
    return '$geofenceId:${event.name}:$bucket';
  }

  // ignore: unused_element
  Future<void> _promoteForegroundServiceIfNeeded() async {
    // TODO: start a short-lived foreground service here when delivery
    // latency exceeds a threshold. Requires flutter_foreground_task or
    // equivalent. The NativeGeofenceForegroundService is already declared
    // in AndroidManifest.xml with foregroundServiceType="location".
  }
}
