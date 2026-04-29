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
        'GeofenceServerRecipient: geofenceId=${entity.geofenceId}, '
        'email=${entity.friendEmail}',
  );

  Future<List<GeofenceServerRecipientEntity>> findByGeofenceId(int geofenceId) {
    return executeRawQuery<GeofenceServerRecipientEntity>(
      entityName: 'geofence_server_recipient',
      sql:
          'SELECT * FROM '
          '${LocalDatabaseProperties.geofenceServerRecipientTableName} '
          'WHERE geofence_id = ?',
      arguments: [geofenceId],
      fromMap: GeofenceServerRecipientEntity.fromMap,
    );
  }

  Future<void> deleteByGeofenceId(int geofenceId) => executeDelete(
    entityName: 'geofence_server_recipient',
    table: LocalDatabaseProperties.geofenceServerRecipientTableName,
    where: 'geofence_id = ?',
    whereArgs: [geofenceId],
    additionalDetails: 'geofenceId: $geofenceId',
  );
}
