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

  Future<List<GeofenceEntity>> findAll() async {
    final gTable = LocalDatabaseProperties.geofenceTableName;
    final rTable = LocalDatabaseProperties.geofenceServerRecipientTableName;

    // 서브쿼리를 사용하여 서버 친구 숫자를 포함한 목록 조회
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT g.*, 
             (SELECT COUNT(*) FROM $rTable r WHERE r.geofence_id = g.id) as server_recipient_count
      FROM $gTable g
      ORDER BY g.name ASC
    ''');

    return maps.map((map) => GeofenceEntity.fromMap(map)).toList();
  }

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
