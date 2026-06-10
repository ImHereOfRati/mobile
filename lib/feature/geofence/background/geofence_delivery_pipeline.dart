import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_database_service.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/record_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:native_geofence/native_geofence.dart';

class GeofenceDeliveryPipeline {
  final GeofenceDeliveryQueueDatabaseService _queue;
  final ContactResolutionService _contactResolutionService;
  final GeofenceLocalRepository _geofenceRepository;
  final NativeGeofenceRegistrarInterface _registrar;
  final SmsNotificationService _smsNotificationService;
  final FcmArrivalService _fcmArrivalService;
  final RecordService _recordService;

  GeofenceDeliveryPipeline(
    this._queue,
    this._contactResolutionService,
    this._geofenceRepository,
    this._registrar,
    this._smsNotificationService,
    this._fcmArrivalService,
    this._recordService,
  );

  Future<void> enqueueTriggeredGeofence({
    required GeofenceEntity geofence,
    required GeofenceEvent event,
  }) async {
    if (geofence.id == null) return;

    final localRecipients = await _contactResolutionService.resolveContacts(geofence);
    final serverRecipients = await _contactResolutionService.resolveServerRecipients(geofence);

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
      smsPhoneNumbers: _contactResolutionService.extractPhoneNumbers(localRecipients),
      serverEmails: _contactResolutionService.extractServerEmails(serverRecipients),
      eventName: event.name,
    );

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
    await _deactivateGeofence(geofence.id!);
    await processPending();
  }

  Future<void> processPending({int limit = 10}) async {
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
    try {
      final anySuccess = await _sendSnapshot(snapshot);
      if (anySuccess || _hasNoRecipients(snapshot)) {
        await _recordService.saveGeofenceRecord(
          geofence: snapshot.geofence,
          recipientNames: snapshot.recipientNames,
        );
        await _queue.complete(item.id!);
        AppLogger.debug('BG_QUEUE: completed geofence delivery ${item.id}');
      } else {
        await _queue.reschedule(
          id: item.id!,
          retryCount: item.retryCount + 1,
          lastError: 'All delivery attempts failed',
        );
        AppLogger.warning('BG_QUEUE: rescheduled geofence delivery ${item.id}');
      }
    } catch (e) {
      await _queue.reschedule(
        id: item.id!,
        retryCount: item.retryCount + 1,
        lastError: e.toString(),
      );
      AppLogger.error('BG_QUEUE: processing failed', e);
    }
  }

  Future<bool> _sendSnapshot(GeofenceDeliverySnapshot snapshot) async {
    var anySuccess = false;

    if (snapshot.smsPhoneNumbers.isNotEmpty) {
      final smsResult = await _smsNotificationService.sendSmsToRecipients(
        phoneNumbers: snapshot.smsPhoneNumbers,
        location: snapshot.geofence.fullLocation,
      );
      if (smsResult is Success) anySuccess = true;
    }

    if (snapshot.serverEmails.isNotEmpty) {
      final body = snapshot.geofence.message.replaceAll(
        '{location}',
        snapshot.geofence.fullLocation,
      );
      final fcmResult = await _fcmArrivalService.sendArrivalNotifications(
        receiverEmails: snapshot.serverEmails,
        body: body,
        location: snapshot.geofence.fullLocation,
      );
      if (fcmResult is Success) anySuccess = true;
    }

    if (anySuccess) {
      await _fcmArrivalService.notifyDeliveryResultToMe(snapshot.geofence.fullLocation);
    }

    return anySuccess;
  }

  bool _hasNoRecipients(GeofenceDeliverySnapshot snapshot) =>
      snapshot.smsPhoneNumbers.isEmpty && snapshot.serverEmails.isEmpty;

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

  String _buildDedupeKey(int geofenceId, GeofenceEvent event) {
    final bucket = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 5000;
    return '$geofenceId:${event.name}:$bucket';
  }
}
