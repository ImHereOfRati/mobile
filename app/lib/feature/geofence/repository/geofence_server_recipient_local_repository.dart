import 'package:iamhere/core/database/service/geofence_server_recipient_database_service.dart';
import 'package:injectable/injectable.dart';

import 'geofence_server_recipient_entity.dart';
import 'geofence_server_recipient_repository.dart';

@lazySingleton
class GeofenceServerRecipientLocalRepository
    implements GeofenceServerRecipientRepository {
  final GeofenceServerRecipientDatabaseService _service;

  GeofenceServerRecipientLocalRepository(this._service);

  @override
  Future<GeofenceServerRecipientEntity> save(
    GeofenceServerRecipientEntity entity,
  ) => _service.save(entity);

  @override
  Future<List<GeofenceServerRecipientEntity>> findByGeofenceId(
    int geofenceId,
  ) => _service.findByGeofenceId(geofenceId);

  @override
  Future<void> deleteByGeofenceId(int geofenceId) =>
      _service.deleteByGeofenceId(geofenceId);
}
