import 'geofence_entity.dart';

abstract class GeofenceRepository {
  Future<GeofenceEntity> save(GeofenceEntity entity);

  Future<List<GeofenceEntity>> findAll();

  Future<void> delete(int id);

  Future<void> updateActiveStatus(int id, bool isActive);
}
