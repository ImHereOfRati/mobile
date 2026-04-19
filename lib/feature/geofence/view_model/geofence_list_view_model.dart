import 'dart:developer';

import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository_provider.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_list_view_model.g.dart';

@riverpod
class GeofenceListViewModel extends _$GeofenceListViewModel {
  late GeofenceLocalRepository _geofenceRepository;
  late NativeGeofenceRegistrarInterface _registrar;

  @override
  Future<List<GeofenceEntity>> build() async {
    _geofenceRepository = ref.watch(geofenceLocalRepositoryProvider);
    _registrar = getIt<NativeGeofenceRegistrarInterface>();
    return await _geofenceRepository.findAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _geofenceRepository.findAll();
    });
  }

  Future<void> toggleActive(int id, bool isActive) async {
    if (!state.hasValue) return;

    final previousState = state;
    final originalList = state.value!;

    try {
      // 낙관적 업데이트: 새로운 리스트 생성하여 상태 업데이트
      final updatedList = originalList.map((geofence) {
        if (geofence.id == id) {
          return geofence.copyWith(isActive: isActive);
        }
        return geofence;
      }).toList();

      state = AsyncValue.data(List.from(updatedList));
      await _geofenceRepository.updateActiveStatus(id, isActive);

      // OS 지오펜스 등록/해제
      if (isActive) {
        final target = updatedList.firstWhere((g) => g.id == id);
        try {
          await _registrar.register(target);
        } catch (e) {
          log('list.toggleActive register failed (id=$id): $e');
        }
      } else {
        try {
          await _registrar.unregister(id);
        } catch (e) {
          log('list.toggleActive unregister failed (id=$id): $e');
        }
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    if (!state.hasValue) return;

    final previousState = state;
    final originalList = state.value!;

    try {
      final updatedList = originalList
          .where((geofence) => geofence.id != id)
          .toList();
      state = AsyncValue.data(updatedList);

      await _geofenceRepository.delete(id);

      try {
        await _registrar.unregister(id);
      } catch (e) {
        log('list.delete unregister failed (id=$id): $e');
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
