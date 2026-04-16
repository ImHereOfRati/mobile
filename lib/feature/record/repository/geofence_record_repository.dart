import 'geofence_record_entity.dart';

abstract class GeofenceRecordRepository {
  Future<GeofenceRecordEntity> save(GeofenceRecordEntity entity);

  Future<List<GeofenceRecordEntity>> findAll();

  Future<List<GeofenceRecordEntity>> findAllOrderByCreatedAtDesc();

  Future<void> delete(int id);

  Future<void> deleteAll();
}
