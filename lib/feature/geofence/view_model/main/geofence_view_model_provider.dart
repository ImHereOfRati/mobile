import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'geofence_view_model.dart';
import 'geofence_view_model_interface.dart';

part 'geofence_view_model_provider.g.dart';

@riverpod
GeofenceViewModelInterface geofenceViewModelInterface(Ref ref) {
  return ref.watch(geofenceViewModelProvider.notifier);
}
