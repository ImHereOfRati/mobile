import 'package:iamhere/core/database/local_database_exception.dart';
import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:injectable/injectable.dart';

import 'abstract_local_database_engine.dart';

@singleton
class GeofenceServerRecipientDatabaseService
    extends AbstractLocalDatabaseService {
  GeofenceServerRecipientDatabaseService(super.database);

  Future<GeofenceServerRecipientEntity> save(
    GeofenceServerRecipientEntity entity,
  ) => executeInsert(
    entityName: 'geofence_server_recipient',
    table: LocalDatabaseProperties.geofenceServerRecipientTableName,
    values: entity.toMap(),
    createEntity: (id) => entity.copyWith(id: id),
    entityDetails:
        'GeofenceServerRecipient: geofenceId=${entity.geofenceId}, email=${entity.friendEmail}',
  );

  Future<List<GeofenceServerRecipientEntity>> findByGeofenceId(
    int geofenceId,
  ) async {
    try {
      final rows = await database.query(
        LocalDatabaseProperties.geofenceServerRecipientTableName,
        where: 'geofence_id = ?',
        whereArgs: [geofenceId],
      );
      return rows.map(GeofenceServerRecipientEntity.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to fetch geofence_server_recipient',
        details: 'geofenceId: $geofenceId',
        originalError: e,
      );
    }
  }

  Future<void> deleteByGeofenceId(int geofenceId) async {
    try {
      await database.delete(
        LocalDatabaseProperties.geofenceServerRecipientTableName,
        where: 'geofence_id = ?',
        whereArgs: [geofenceId],
      );
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to delete geofence_server_recipient',
        details: 'geofenceId: $geofenceId',
        originalError: e,
      );
    }
  }
}
