import 'package:iamhere/feature/geofence/application/geofence_command_result.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';

class DeleteGeofenceUseCase {
  final GeofenceLocalRepository _repo;
  final NativeGeofenceRegistrarInterface _registrar;

  const DeleteGeofenceUseCase({
    required GeofenceLocalRepository repo,
    required NativeGeofenceRegistrarInterface registrar,
  }) : _repo = repo,
       _registrar = registrar;

  Future<GeofenceCommandResult> execute(int id) async {
    try {
      await _repo.delete(id);
      await _registrar.unregister(id);
      return const GeofenceCommandResult.success();
    } catch (e) {
      return GeofenceCommandResult.failure(e);
    }
  }
}
