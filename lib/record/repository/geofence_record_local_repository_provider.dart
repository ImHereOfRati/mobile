import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/record/repository/geofence_record_local_repository.dart';

final geofenceRecordLocalRepositoryProvider = Provider<GeofenceRecordLocalRepository>((ref) {
  return getIt<GeofenceRecordLocalRepository>();
});
