import 'geofence_record_entity.dart';

abstract class GeofenceRecordRepository {
  Future<GeofenceRecordEntity> save(GeofenceRecordEntity entity);

  Future<void> update(GeofenceRecordEntity entity);

  Future<List<GeofenceRecordEntity>> findAllOrderByCreatedAtDesc();

  Future<GeofenceRecordEntity?> findByDeliveryKey(String deliveryKey);

  Future<void> deleteAll();
}
