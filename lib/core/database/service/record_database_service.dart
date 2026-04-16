import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:injectable/injectable.dart';

import 'abstract_local_database_engine.dart';

@singleton
class RecordDatabaseService extends AbstractLocalDatabaseService {
  RecordDatabaseService(super.database);

  Future<GeofenceRecordEntity> save(GeofenceRecordEntity entity) =>
      executeInsert(
        entityName: 'geofence record',
        table: LocalDatabaseProperties.RECORD_TABLE_NAME,
        values: entity.toMap(),
        createEntity: (id) => entity.copyWith(id: id),
        entityDetails: 'Geofence: ${entity.geofenceName}',
      );

  Future<List<GeofenceRecordEntity>> findAll() => executeQuery(
    entityName: 'geofence record',
    table: LocalDatabaseProperties.RECORD_TABLE_NAME,
    fromMap: GeofenceRecordEntity.fromMap,
    orderBy: 'created_at DESC',
  );

  Future<void> deleteAll() => executeDelete(
    entityName: 'all geofence records',
    table: LocalDatabaseProperties.RECORD_TABLE_NAME,
    additionalDetails: 'Deleting all records',
  );
}
