import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/repository/geofence_record_local_repository.dart';
import 'package:iamhere/feature/record/repository/geofence_record_local_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_record_view_model.g.dart';

@riverpod
class GeofenceRecordViewModel extends _$GeofenceRecordViewModel {
  late final GeofenceRecordLocalRepository _repository;

  @override
  Future<List<GeofenceRecordEntity>> build() async {
    _repository = ref.watch(geofenceRecordLocalRepositoryProvider);
    return await _repository.findAllOrderByCreatedAtDesc();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.findAllOrderByCreatedAtDesc();
    });
  }

  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await refresh();
  }
}
