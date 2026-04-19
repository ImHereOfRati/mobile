import 'dart:convert';
import 'dart:developer';

import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/repository/geofence_record_local_repository.dart';
import 'package:injectable/injectable.dart';

/// Record persistence for geofence entries
@injectable
class RecordService {
  final GeofenceRecordLocalRepository _recordRepository;

  RecordService(this._recordRepository);

  /// Save a geofence entry record
  Future<void> saveGeofenceRecord({
    required GeofenceEntity geofence,
    required List<String> recipientNames,
  }) async {
    try {
      if (geofence.id == null) {
        log('Cannot save record: geofence has no ID');
        return;
      }

      final record = GeofenceRecordEntity(
        geofenceId: geofence.id!,
        geofenceName: geofence.name,
        message: geofence.message,
        recipients: jsonEncode(recipientNames),
        createdAt: DateTime.now(),
        sendMachine: SendMachine.mobile,
      );

      await _recordRepository.save(record);
      log('Geofence record saved: ${geofence.name}');
    } catch (e) {
      log('Error saving geofence record: $e');
    }
  }
}
