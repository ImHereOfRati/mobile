import 'package:iamhere/feature/geofence/application/geofence_command_result.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';

class SetGeofenceActiveUseCase {
  final GeofenceLocalRepository _repo;
  final NativeGeofenceRegistrarInterface _registrar;

  const SetGeofenceActiveUseCase({
    required GeofenceLocalRepository repo,
    required NativeGeofenceRegistrarInterface registrar,
  }) : _repo = repo,
       _registrar = registrar;

  Future<GeofenceCommandResult> execute({
    required int id,
    required bool isActive,
  }) async {
    try {
      await _repo.updateActiveStatus(id, isActive);
      if (isActive) {
        final all = await _repo.findAll();
        final geofence = all.firstWhere((g) => g.id == id);
        await _registrar.register(geofence.copyWith(isActive: true));
      } else {
        await _registrar.unregister(id);
      }
      return const GeofenceCommandResult.success();
    } catch (e) {
      return GeofenceCommandResult.failure(e);
    }
  }
}
