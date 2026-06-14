import 'dart:convert';
import 'dart:developer';

import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/record/model/activity_record_error_normalizer.dart';
import 'package:iamhere/feature/record/model/activity_record_status.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/repository/geofence_record_local_repository.dart';
import 'package:injectable/injectable.dart';

/// Record persistence for geofence entries
@injectable
class RecordService {
  final GeofenceRecordLocalRepository _recordRepository;

  RecordService(this._recordRepository);

  Future<void> markGeofenceRecordPending({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    int retryCount = 0,
    String lastError = '',
  }) async {
    await _upsertGeofenceRecord(
      geofence: geofence,
      recipientNames: recipientNames,
      deliveryKey: deliveryKey,
      message: message,
      deliveryEventType: deliveryEventType,
      status: ActivityRecordStatus.pending,
      retryCount: retryCount,
      lastError: lastError,
    );
  }

  Future<void> markGeofenceRecordCompleted({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    int retryCount = 0,
  }) async {
    await _upsertGeofenceRecord(
      geofence: geofence,
      recipientNames: recipientNames,
      deliveryKey: deliveryKey,
      message: message,
      deliveryEventType: deliveryEventType,
      status: ActivityRecordStatus.completed,
      retryCount: retryCount,
    );
  }

  Future<void> markGeofenceRecordFailed({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    required int retryCount,
    required String lastError,
  }) async {
    await _upsertGeofenceRecord(
      geofence: geofence,
      recipientNames: recipientNames,
      deliveryKey: deliveryKey,
      message: message,
      deliveryEventType: deliveryEventType,
      status: ActivityRecordStatus.failed,
      retryCount: retryCount,
      lastError: lastError,
    );
  }

  /// Save or update a geofence entry record.
  Future<void> _upsertGeofenceRecord({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
    required String deliveryKey,
    required String message,
    required String deliveryEventType,
    required ActivityRecordStatus status,
    int retryCount = 0,
    String lastError = '',
  }) async {
    try {
      if (geofence.id == null) {
        log('Cannot save record: geofence has no ID');
        return;
      }

      final existing = await _recordRepository.findByDeliveryKey(deliveryKey);
      final normalizedError = ActivityRecordErrorNormalizer.normalize(
        lastError,
      );
      final record = GeofenceRecordEntity(
        id: existing?.id,
        geofenceId: geofence.id!,
        geofenceName: geofence.name,
        message: message,
        recipients: jsonEncode(recipientNames),
        createdAt: existing?.createdAt ?? DateTime.now(),
        sendMachine: SendMachine.mobile,
        status: status,
        deliveryKey: deliveryKey,
        retryCount: retryCount,
        lastError: normalizedError,
        deliveryEventType: deliveryEventType,
      );

      if (existing == null) {
        await _recordRepository.save(record);
      } else {
        await _recordRepository.update(record);
      }
      log('Geofence record saved: ${geofence.name} ($status)');
    } catch (e) {
      log('Error saving geofence record: $e');
    }
  }
}
