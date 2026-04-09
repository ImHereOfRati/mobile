import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/geofence/repository/geofence_local_repository.dart';

final geofenceLocalRepositoryProvider = Provider<GeofenceLocalRepository>((ref) {
  return getIt<GeofenceLocalRepository>();
});
