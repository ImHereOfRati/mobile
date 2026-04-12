import 'package:iamhere/geofence/view_model/geofence_view_model.dart';
import 'package:iamhere/geofence/view_model/geofence_view_model_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_view_model_provider.g.dart';

@riverpod
GeofenceViewModelInterface geofenceViewModelInterface(Ref ref) {
  return ref.watch(geofenceViewModelProvider.notifier);
}
