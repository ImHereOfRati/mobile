import 'package:iamhere/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_local_repository_provider.g.dart';

@riverpod
GeofenceLocalRepository geofenceLocalRepository(Ref ref) {
  return getIt<GeofenceLocalRepository>();
}
