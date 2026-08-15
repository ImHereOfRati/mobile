import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/application/sync_active_geofences_use_case.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';

void main() {
  GeofenceEntity geofence({required int id, required bool isActive}) {
    return GeofenceEntity(
      id: id,
      name: 'place-$id',
      address: 'Seoul',
      lat: 37.0,
      lng: 127.0,
      radius: 100,
      message: '',
      contactIds: '[]',
      isActive: isActive,
    );
  }

  test('활성 geofence 만 OS registrar 에 전달한다', () async {
    final registrar = _FakeRegistrar();
    final useCase = SyncActiveGeofencesUseCase(registrar);

    final result = await useCase.execute([
      geofence(id: 1, isActive: true),
      geofence(id: 2, isActive: false),
      geofence(id: 3, isActive: true),
    ]);

    expect(result.status, GeofenceSyncStatus.synced);
    expect(registrar.syncedIds, [1, 3]);
  });

  test('백그라운드 위치 권한 부족은 missingBackgroundLocation 결과로 반환한다', () async {
    final exception = MissingBackgroundLocationException(
      PermissionState.grantedWhenInUse,
      'always permission required',
    );
    final registrar = _FakeRegistrar(exceptionToThrow: exception);
    final useCase = SyncActiveGeofencesUseCase(registrar);

    final result = await useCase.execute([geofence(id: 1, isActive: true)]);

    expect(result.status, GeofenceSyncStatus.missingBackgroundLocation);
    expect(result.missingPermission, same(exception));
  });

  test('일반 실패는 failed 결과로 반환한다', () async {
    final error = StateError('native unavailable');
    final registrar = _FakeRegistrar(exceptionToThrow: error);
    final useCase = SyncActiveGeofencesUseCase(registrar);

    final result = await useCase.execute([geofence(id: 1, isActive: true)]);

    expect(result.status, GeofenceSyncStatus.failed);
    expect(result.error, same(error));
  });
}

class _FakeRegistrar implements NativeGeofenceRegistrarInterface {
  final Object? exceptionToThrow;
  final syncedIds = <int>[];

  _FakeRegistrar({this.exceptionToThrow});

  @override
  Future<List<String>> getRegisteredIds() async => [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> register(GeofenceEntity geofence) async {}

  @override
  Future<void> syncAll(List<GeofenceEntity> activeGeofences) async {
    final exception = exceptionToThrow;
    if (exception != null) throw exception;
    syncedIds.addAll(activeGeofences.map((geofence) => geofence.id!));
  }

  @override
  Future<void> unregister(int geofenceId) async {}
}
