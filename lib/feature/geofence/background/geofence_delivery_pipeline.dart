import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/delivery_dispatcher.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_ports.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_policy.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';

class GeofenceDeliveryPipeline {
  final DeliveryQueueStore _queue;
  final GeofenceRecipientResolver _recipientResolver;
  final GeofenceLifecycleStore _geofenceLifecycleStore;
  final NativeGeofenceRegistrarInterface _registrar;
  final GeofenceDeliveryRecordStore _recordStore;
  final RetrySchedulerPort _retryScheduler;
  final DeliveryDispatcher _dispatcher;
  final DeliverySuccessPolicy _successPolicy;
  final DeliveryRetryPolicy _retryPolicy;
  final DedupePolicy _dedupePolicy;
  final Clock _clock;
  final GeofenceLifecyclePolicy _lifecyclePolicy;
  Future<void>? _drainInFlight;

  GeofenceDeliveryPipeline(
    this._queue,
    this._recipientResolver,
    this._geofenceLifecycleStore,
    this._registrar,
    SmsNotificationService smsNotificationService,
    FcmArrivalService fcmArrivalService,
    this._recordStore,
    this._retryScheduler, {
    DeliverySuccessPolicy successPolicy = const DeliverySuccessPolicy(),
    DeliveryRetryPolicy retryPolicy = const DeliveryRetryPolicy(),
    DedupePolicy dedupePolicy = const DedupePolicy(),
    Clock clock = const SystemClock(),
    GeofenceLifecyclePolicy lifecyclePolicy = const GeofenceLifecyclePolicy(),
    DeliveryDispatcher? dispatcher,
  }) : _successPolicy = successPolicy,
       _retryPolicy = retryPolicy,
       _dedupePolicy = dedupePolicy,
       _clock = clock,
       _lifecyclePolicy = lifecyclePolicy,
       _dispatcher =
           dispatcher ??
           DeliveryDispatcher(smsNotificationService, fcmArrivalService);

  Future<bool> enqueueTriggeredGeofence({
    required GeofenceEntity geofence,
    required DeliveryEvent event,
  }) async {
    if (geofence.id == null) return false;

    final localRecipients = await _recipientResolver.resolveContacts(geofence);
    final serverRecipients = await _recipientResolver.resolveServerRecipients(
      geofence,
    );

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
      smsPhoneNumbers: _recipientResolver.extractPhoneNumbers(localRecipients),
      serverUserIds: _recipientResolver.extractServerUserIds(serverRecipients),
      deliveryEventType: event.name,
    );

    final body = _buildMessageBody(snapshot);
    final now = _clock.nowUtc();
    final entity = GeofenceDeliveryQueueEntity(
      dedupeKey: _dedupePolicy.buildKey(
        geofenceId: geofence.id!,
        event: event,
        nowUtc: now,
      ),
      snapshotJson: snapshot.toJson(),
      status: GeofenceDeliveryQueueEntity.pending,
      retryCount: 0,
      nextAttemptAt: now,
      lastError: '',
      createdAt: now,
      updatedAt: now,
    );

    final queued = await _queue.enqueue(entity);
    if (queued == null) {
      AppLogger.debug(
        'BG_QUEUE: duplicate geofence delivery skipped (${entity.dedupeKey})',
      );
      return false;
    }

    await _recordStore.markGeofenceRecordPending(
      geofence: geofence,
      recipientNames: snapshot.recipientNames,
      deliveryKey: queued.dedupeKey,
      message: body,
      deliveryEventType: event.name,
    );
    await processPending();
    await _retryScheduler.scheduleNextIfNeeded();
    return true;
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
      final anySuccess = await _dispatcher.send(snapshot, body: body);
      if (_successPolicy.shouldComplete(
        snapshot: snapshot,
        anyChannelSucceeded: anySuccess,
      )) {
        await _recordStore.markGeofenceRecordCompleted(
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

    if (_retryPolicy.isTerminalFailure(nextRetryCount)) {
      await _recordStore.markGeofenceRecordFailed(
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

    await _recordStore.markGeofenceRecordPending(
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

  String _buildMessageBody(GeofenceDeliverySnapshot snapshot) {
    return composeSmsBody(
      eventType: EventType.fromName(snapshot.deliveryEventType),
      message: snapshot.geofence.message,
      location: snapshot.geofence.name,
    );
  }

  Future<void> _completeLifecycleAfterSuccess(
    GeofenceDeliverySnapshot snapshot,
  ) async {
    final geofenceId = snapshot.geofence.id;
    if (geofenceId == null) return;

    switch (_lifecyclePolicy.afterSuccessfulDelivery(snapshot)) {
      case GeofenceLifecycleAction.markAwaitingDeparture:
        await _geofenceLifecycleStore.updateAwaitingDeparture(geofenceId, true);
      case GeofenceLifecycleAction.deactivate:
        await _deactivateGeofence(geofenceId);
      case GeofenceLifecycleAction.clearAwaitingDeparture:
      case GeofenceLifecycleAction.restoreActive:
      case GeofenceLifecycleAction.none:
        return;
    }
  }

  Future<void> _rollbackLifecycleAfterTerminalFailure(
    GeofenceDeliverySnapshot snapshot,
  ) async {
    final geofenceId = snapshot.geofence.id;
    if (geofenceId == null) return;

    switch (_lifecyclePolicy.afterTerminalFailure(snapshot)) {
      case GeofenceLifecycleAction.clearAwaitingDeparture:
        await _geofenceLifecycleStore.updateAwaitingDeparture(
          geofenceId,
          false,
        );
      case GeofenceLifecycleAction.restoreActive:
        await _restoreActiveGeofence(snapshot, geofenceId);
      case GeofenceLifecycleAction.markAwaitingDeparture:
      case GeofenceLifecycleAction.deactivate:
      case GeofenceLifecycleAction.none:
        return;
    }
  }

  Future<void> _restoreActiveGeofence(
    GeofenceDeliverySnapshot snapshot,
    int geofenceId,
  ) async {
    try {
      await _geofenceLifecycleStore.updateActiveStatus(geofenceId, true);
      await _registrar.register(snapshot.geofence.copyWith(isActive: true));
    } catch (e) {
      AppLogger.error('BG_QUEUE: failed to restore geofence $geofenceId', e);
    }
  }

  Future<void> _deactivateGeofence(int geofenceId) async {
    try {
      await _geofenceLifecycleStore.updateActiveStatus(geofenceId, false);
    } catch (e) {
      AppLogger.error('BG_QUEUE: failed to deactivate geofence $geofenceId', e);
    }

    try {
      await _registrar.unregister(geofenceId);
    } catch (e) {
      AppLogger.error('BG_QUEUE: failed to unregister geofence $geofenceId', e);
    }
  }

  // ignore: unused_element
  Future<void> _promoteForegroundServiceIfNeeded() async {
    // TODO: start a short-lived foreground service here when delivery
    // latency exceeds a threshold. Requires flutter_foreground_task or
    // equivalent. The NativeGeofenceForegroundService is already declared
    // in AndroidManifest.xml with foregroundServiceType="location".
  }
}
