import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/record/repository/geofence_record_local_repository.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';

final geofenceRecordLocalRepositoryProvider =
    Provider<GeofenceRecordLocalRepository>((ref) {
      return getIt<GeofenceRecordLocalRepository>();
    });
