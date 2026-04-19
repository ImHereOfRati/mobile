import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

abstract class GeofenceViewModelInterface {
  Future<GeofenceEntity> saveGeofence({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required double radius,
    required String message,
    required List<int> contactIds,
    required List<ServerRecipient> serverRecipients,
  });

  Future<List<GeofenceEntity>> findAllGeofences();

  Future<void> toggleGeofenceActive(int id, bool isActive);
}
