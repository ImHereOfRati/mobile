import 'package:iamhere/core/database/service/record_database_service.dart';
import 'package:injectable/injectable.dart';

import 'geofence_record_entity.dart';
import 'geofence_record_repository.dart';

@lazySingleton
class GeofenceRecordLocalRepository implements GeofenceRecordRepository {
  final RecordDatabaseService _recordDatabase;
  GeofenceRecordLocalRepository(this._recordDatabase);

  @override
  Future<List<GeofenceRecordEntity>> findAllOrderByCreatedAtDesc() async {
    return await _recordDatabase.findAll();
  }

  @override
  Future<GeofenceRecordEntity> save(GeofenceRecordEntity entity) async {
    return await _recordDatabase.save(entity);
  }

  @override
  Future<void> deleteAll() async {
    await _recordDatabase.deleteAll();
  }
}
