import 'dart:async';
import 'dart:developer';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository_provider.dart';
import 'package:iamhere/feature/geofence/service/geocoding_service_provider.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_list_view_model.g.dart';

@riverpod
class GeofenceListViewModel extends _$GeofenceListViewModel {
  late GeofenceLocalRepository _repo;
  late NativeGeofenceRegistrarInterface _registrar;
  Timer? _pollingTimer;

  @override
  Future<List<GeofenceEntity>> build() async {
    _repo = ref.watch(geofenceLocalRepositoryProvider);
    _registrar = getIt<NativeGeofenceRegistrarInterface>();
    
    final list = await _repo.findAll();
    _syncWithOs(list);
    _fillMissingAddresses(list);

    // 활성화된 지오펜스가 있다면 폴링 시작
    _startPollingIfNecessary(list);

    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return list;
  }

  void _startPollingIfNecessary(List<GeofenceEntity> list) {
    _pollingTimer?.cancel();
    final hasActive = list.any((g) => g.isActive);
    if (hasActive) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final newList = await _repo.findAll();
        final anyChanged = _checkIfStatusChanged(state.value, newList);
        if (anyChanged) {
          log('GeofenceListViewModel: Status change detected via polling, updating UI');
          state = AsyncValue.data(newList);
          if (!newList.any((g) => g.isActive)) {
            _pollingTimer?.cancel();
          }
        }
      });
    }
  }

  bool _checkIfStatusChanged(List<GeofenceEntity>? oldList, List<GeofenceEntity> newList) {
    if (oldList == null || oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].isActive != newList[i].isActive) return true;
    }
    return false;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final list = await _repo.findAll();
      _syncWithOs(list);
      _startPollingIfNecessary(list);
      return list;
    });
  }

  void _syncWithOs(List<GeofenceEntity> list) async {
    try {
      await _registrar.syncAll(list.where((g) => g.isActive).toList());
    } on MissingBackgroundLocationException catch (e) {
      // 권한 미획득은 정상 시나리오: 토글/저장 시점에 사용자에게 가이드 뷰가 노출된다.
      log('OS sync skipped: missing background location permission (${e.state.name})');
    } catch (e) {
      log('OS sync failed: $e');
    }
  }

  void _fillMissingAddresses(List<GeofenceEntity> list) {
    for (final g in list) {
      if (g.address.isEmpty && g.id != null) {
        ref.read(geocodingServiceProvider).reverseGeocode(g.lat, g.lng).then((addr) async {
          await _repo.updateAddress(g.id!, addr);
          if (state.hasValue) {
            state = AsyncValue.data(state.value!.map((e) => e.id == g.id ? e.copyWith(address: addr) : e).toList());
          }
        });
      }
    }
  }

  Future<void> toggleActive(int id, bool isActive) async {
    if (!state.hasValue) return;
    final prev = state;
    final updatedList = state.value!.map((g) => g.id == id ? g.copyWith(isActive: isActive) : g).toList();
    state = AsyncValue.data(updatedList);
    try {
      await _repo.updateActiveStatus(id, isActive);
      final target = updatedList.firstWhere((g) => g.id == id);
      isActive ? await _registrar.register(target) : await _registrar.unregister(id);
      
      // 토글 후 활성 상태라면 폴링 시작 (백그라운드 비활성화 감지용)
      _startPollingIfNecessary(updatedList);
    } catch (e) {
      state = prev;
      log('toggleActive failed: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    if (!state.hasValue) return;
    final prev = state;
    state = AsyncValue.data(state.value!.where((g) => g.id != id).toList());
    try {
      await _repo.delete(id);
      await _registrar.unregister(id);
    } catch (e) {
      state = prev;
      log('delete failed: $e');
      rethrow;
    }
  }
}
