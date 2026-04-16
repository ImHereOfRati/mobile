import 'package:iamhere/core/database/local_database_service.dart';
import 'package:injectable/injectable.dart';

import 'geofence_entity.dart';
import 'geofence_repository.dart';

@lazySingleton
class GeofenceLocalRepository implements GeofenceRepository {
  final LocalDatabaseService _database;
  GeofenceLocalRepository(this._database);

  @override
  Future<List<GeofenceEntity>> findAll() async {
    return await _database.findAllGeofences();
  }

  @override
  Future<GeofenceEntity> save(GeofenceEntity entity) async {
    return await _database.saveGeofence(entity);
  }

  @override
  Future<void> delete(int id) async {
    await _database.deleteGeofence(id);
  }

  @override
  Future<void> updateActiveStatus(int id, bool isActive) async {
    await _database.updateGeofenceActiveStatus(id, isActive);
  }
}
