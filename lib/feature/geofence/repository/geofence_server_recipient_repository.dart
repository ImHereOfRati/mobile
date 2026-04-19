import 'geofence_server_recipient_entity.dart';

abstract class GeofenceServerRecipientRepository {
  Future<GeofenceServerRecipientEntity> save(
    GeofenceServerRecipientEntity entity,
  );

  Future<List<GeofenceServerRecipientEntity>> findByGeofenceId(int geofenceId);

  Future<void> deleteByGeofenceId(int geofenceId);
}
