import 'package:iamhere/core/database/service/geofence_database_service.dart';
import 'package:injectable/injectable.dart';

import 'geofence_entity.dart';
import 'geofence_repository.dart';

@lazySingleton
class GeofenceLocalRepository implements GeofenceRepository {
  final GeofenceDatabaseService _geofenceDatabaseService;
  GeofenceLocalRepository(this._geofenceDatabaseService);

  @override
  Future<List<GeofenceEntity>> findAll() async {
    return await _geofenceDatabaseService.findAll();
  }

  @override
  Future<GeofenceEntity> save(GeofenceEntity entity) async {
    return await _geofenceDatabaseService.save(entity);
  }

  @override
  Future<void> update(GeofenceEntity entity) async {
    await _geofenceDatabaseService.update(entity);
  }

  @override
  Future<void> delete(int id) async {
    await _geofenceDatabaseService.delete(id);
  }

  @override
  Future<void> updateActiveStatus(int id, bool isActive) async {
    await _geofenceDatabaseService.updateActiveStatus(id, isActive);
  }

  @override
  Future<void> updateAddress(int id, String address) async {
    await _geofenceDatabaseService.updateAddress(id, address);
  }
}
