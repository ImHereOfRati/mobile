import 'package:iamhere/core/database/local_database_exception.dart';
import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:injectable/injectable.dart';

import 'abstract_local_database_engine.dart';

@singleton
class GeofenceDatabaseService extends AbstractLocalDatabaseService {
  GeofenceDatabaseService(super.database);

  Future<GeofenceEntity> save(GeofenceEntity entity) => executeInsert(
    entityName: 'geofence',
    table: LocalDatabaseProperties.geofenceTableName,
    values: entity.toMap(),
    createEntity: (id) => entity.copyWith(id: id),
    entityDetails: 'Geofence: ${entity.name}',
  );

  Future<int> update(GeofenceEntity entity) => executeUpdate(
    entityName: 'Geofence',
    entityId: entity.id,
    table: LocalDatabaseProperties.geofenceTableName,
    values: entity.toMap(),
    entityDetails: 'Geofence: ${entity.name}',
  );

  Future<List<GeofenceEntity>> findAll() => executeQuery(
    entityName: 'geofence',
    table: LocalDatabaseProperties.geofenceTableName,
    fromMap: GeofenceEntity.fromMap,
    orderBy: 'name ASC',
  );

  Future<void> delete(int id) => executeDelete(
    entityName: 'geofence',
    table: LocalDatabaseProperties.geofenceTableName,
    id: id,
  );

  Future<void> updateActiveStatus(int id, bool isActive) async {
    try {
      await database.update(
        LocalDatabaseProperties.geofenceTableName,
        {'is_active': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to update geofence active status',
        details: 'ID: $id, isActive: $isActive',
        originalError: e,
      );
    }
  }

  Future<void> updateAddress(int id, String address) async {
    try {
      await database.update(
        LocalDatabaseProperties.geofenceTableName,
        {'address': address},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to update geofence address',
        details: 'ID: $id, address: $address',
        originalError: e,
      );
    }
  }
}
