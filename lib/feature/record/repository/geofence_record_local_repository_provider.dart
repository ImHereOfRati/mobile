import 'package:iamhere/core/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'geofence_record_local_repository.dart';

part 'geofence_record_local_repository_provider.g.dart';

@riverpod
GeofenceRecordLocalRepository geofenceRecordLocalRepository(Ref ref) {
  return getIt<GeofenceRecordLocalRepository>();
}
