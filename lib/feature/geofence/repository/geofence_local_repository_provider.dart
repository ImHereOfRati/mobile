import 'package:iamhere/core/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'geofence_local_repository.dart';

part 'geofence_local_repository_provider.g.dart';

@riverpod
GeofenceLocalRepository geofenceLocalRepository(Ref ref) {
  return getIt<GeofenceLocalRepository>();
}
