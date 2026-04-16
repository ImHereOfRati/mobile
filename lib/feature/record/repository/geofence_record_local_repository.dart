import 'package:iamhere/core/database/local_database_service.dart';
import 'package:injectable/injectable.dart';

import 'geofence_record_entity.dart';
import 'geofence_record_repository.dart';

@lazySingleton
class GeofenceRecordLocalRepository implements GeofenceRecordRepository {
  final LocalDatabaseService _database;
  GeofenceRecordLocalRepository(this._database);

  @override
  Future<List<GeofenceRecordEntity>> findAll() async {
    return await _database.findAllGeofenceRecords();
  }

  @override
  Future<List<GeofenceRecordEntity>> findAllOrderByCreatedAtDesc() async {
    return await _database.findAllGeofenceRecords();
  }

  @override
  Future<GeofenceRecordEntity> save(GeofenceRecordEntity entity) async {
    return await _database.saveGeofenceRecord(entity);
  }

  @override
  Future<void> delete(int id) async {
    await _database.deleteGeofenceRecord(id);
  }

  @override
  Future<void> deleteAll() async {
    await _database.deleteAllGeofenceRecords();
  }
}
