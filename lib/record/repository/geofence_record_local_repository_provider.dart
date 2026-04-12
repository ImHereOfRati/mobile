import 'package:iamhere/record/repository/geofence_record_local_repository.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_record_local_repository_provider.g.dart';

@riverpod
GeofenceRecordLocalRepository geofenceRecordLocalRepository(Ref ref) {
  return getIt<GeofenceRecordLocalRepository>();
}
