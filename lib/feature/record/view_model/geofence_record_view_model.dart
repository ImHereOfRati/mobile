import 'dart:async';

import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/repository/geofence_record_local_repository.dart';
import 'package:iamhere/feature/record/repository/geofence_record_local_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_record_view_model.g.dart';

@riverpod
class GeofenceRecordViewModel extends _$GeofenceRecordViewModel {
  late final GeofenceRecordLocalRepository _repository;
  Timer? _pollTimer;

  @override
  Future<List<GeofenceRecordEntity>> build() async {
    _repository = ref.watch(geofenceRecordLocalRepositoryProvider);
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => _silentRefresh(),
    );
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    return await _repository.findAllOrderByCreatedAtDesc();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.findAllOrderByCreatedAtDesc();
    });
  }

  Future<void> _silentRefresh() async {
    final current = state.asData?.value;
    final next = await AsyncValue.guard(
      () => _repository.findAllOrderByCreatedAtDesc(),
    );
    if (next.hasError && current != null) return;
    state = next;
  }

  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await refresh();
  }
}
