import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'geofence_server_recipient_local_repository.dart';

part 'geofence_server_recipient_local_repository_provider.g.dart';

@riverpod
GeofenceServerRecipientLocalRepository geofenceServerRecipientLocalRepository(
  Ref ref,
) {
  return getIt<GeofenceServerRecipientLocalRepository>();
}
