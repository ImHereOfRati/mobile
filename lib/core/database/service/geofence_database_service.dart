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

  Future<List<GeofenceEntity>> findAll() {
    final gTable = LocalDatabaseProperties.geofenceTableName;
    final rTable = LocalDatabaseProperties.geofenceServerRecipientTableName;

    // 서브쿼리로 서버 친구 숫자(server_recipient_count)까지 한 번에 조회.
    return executeRawQuery<GeofenceEntity>(
      entityName: 'geofence',
      sql: '''
        SELECT g.*,
               (SELECT COUNT(*) FROM $rTable r WHERE r.geofence_id = g.id)
                 as server_recipient_count
        FROM $gTable g
        ORDER BY g.name ASC
      ''',
      fromMap: GeofenceEntity.fromMap,
    );
  }

  Future<void> delete(int id) => executeDelete(
    entityName: 'geofence',
    table: LocalDatabaseProperties.geofenceTableName,
    id: id,
  );

  Future<void> updateActiveStatus(int id, bool isActive) => executePartialUpdate(
    entityName: 'geofence active status',
    table: LocalDatabaseProperties.geofenceTableName,
    values: {'is_active': isActive ? 1 : 0},
    id: id,
    entityDetails: 'ID: $id, isActive: $isActive',
  );

  Future<void> updateAddress(int id, String address) => executePartialUpdate(
    entityName: 'geofence address',
    table: LocalDatabaseProperties.geofenceTableName,
    values: {'address': address},
    id: id,
    entityDetails: 'ID: $id, address: $address',
  );
}
