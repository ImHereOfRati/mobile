import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';

final geofenceLocalRepositoryProvider = Provider<GeofenceLocalRepository>((
  ref,
) {
  return getIt<GeofenceLocalRepository>();
});
