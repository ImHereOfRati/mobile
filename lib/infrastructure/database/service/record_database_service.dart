import 'package:iamhere/infrastructure/database/local_database_properties.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:injectable/injectable.dart';

import 'abstract_local_database_engine.dart';

@singleton
class RecordDatabaseService extends AbstractLocalDatabaseService {
  RecordDatabaseService(super.database);

  Future<GeofenceRecordEntity> save(GeofenceRecordEntity entity) =>
      saveEntity(
        entityName: 'geofence record',
        table: LocalDatabaseProperties.recordTableName,
        values: entity.toMap(),
        createEntity: (id) => entity.copyWith(id: id),
        entityDetails: 'Geofence: ${entity.geofenceName}',
      );

  Future<void> update(GeofenceRecordEntity entity) async {
    await executeUpdate(
      entityName: 'geofence record',
      entityId: entity.id,
      table: LocalDatabaseProperties.recordTableName,
      values: entity.toMap()..remove('id'),
      entityDetails: 'Geofence: ${entity.geofenceName}',
    );
  }

  Future<List<GeofenceRecordEntity>> findAll() => findAllEntities(
    entityName: 'geofence record',
    table: LocalDatabaseProperties.recordTableName,
    fromMap: GeofenceRecordEntity.fromMap,
    orderBy: 'created_at DESC',
  );

  Future<GeofenceRecordEntity?> findByDeliveryKey(String deliveryKey) async {
    final rows = await database.query(
      LocalDatabaseProperties.recordTableName,
      where: 'delivery_key = ?',
      whereArgs: [deliveryKey],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return GeofenceRecordEntity.fromMap(rows.first);
  }

  Future<void> deleteAll() => deleteAllEntities(
    entityName: 'all geofence records',
    table: LocalDatabaseProperties.recordTableName,
    additionalDetails: 'Deleting all records',
  );
}
