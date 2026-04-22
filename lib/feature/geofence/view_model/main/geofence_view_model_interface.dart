import 'package:iamhere/feature/geofence/view_model/dto/save_geofence_request.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

abstract class GeofenceViewModelInterface {
  Future<GeofenceEntity> saveGeofence(SaveGeofenceRequest request);

  Future<List<GeofenceEntity>> findAllGeofences();

  Future<void> toggleGeofenceActive(int id, bool isActive);
}
