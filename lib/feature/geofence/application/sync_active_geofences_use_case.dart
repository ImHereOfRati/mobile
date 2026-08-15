import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';

enum GeofenceSyncStatus { synced, missingBackgroundLocation, failed }

class GeofenceSyncResult {
  final GeofenceSyncStatus status;
  final MissingBackgroundLocationException? missingPermission;
  final Object? error;

  const GeofenceSyncResult._({
    required this.status,
    this.missingPermission,
    this.error,
  });

  const GeofenceSyncResult.synced() : this._(status: GeofenceSyncStatus.synced);

  const GeofenceSyncResult.missingBackgroundLocation(
    MissingBackgroundLocationException exception,
  ) : this._(
        status: GeofenceSyncStatus.missingBackgroundLocation,
        missingPermission: exception,
      );

  const GeofenceSyncResult.failed(Object error)
    : this._(status: GeofenceSyncStatus.failed, error: error);
}

class SyncActiveGeofencesUseCase {
  final NativeGeofenceRegistrarInterface _registrar;

  const SyncActiveGeofencesUseCase(this._registrar);

  Future<GeofenceSyncResult> execute(List<GeofenceEntity> geofences) async {
    try {
      await _registrar.syncAll(
        geofences.where((geofence) => geofence.isActive).toList(),
      );
      return const GeofenceSyncResult.synced();
    } on MissingBackgroundLocationException catch (e) {
      return GeofenceSyncResult.missingBackgroundLocation(e);
    } catch (e) {
      return GeofenceSyncResult.failed(e);
    }
  }
}
