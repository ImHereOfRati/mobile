import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/application/delete_geofence_use_case.dart';
import 'package:iamhere/feature/geofence/application/set_geofence_active_use_case.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';

void main() {
  GeofenceEntity geofence({int id = 1, bool isActive = false}) {
    return GeofenceEntity(
      id: id,
      name: 'home',
      address: 'Seoul',
      lat: 37.0,
      lng: 127.0,
      radius: 100,
      message: '',
      contactIds: '[]',
      isActive: isActive,
    );
  }

  test('SetGeofenceActiveUseCase 활성화는 DB 갱신 후 OS register 를 호출한다', () async {
    final repo = _FakeRepository([geofence()]);
    final registrar = _FakeRegistrar();
    final useCase = SetGeofenceActiveUseCase(
      repo: repo,
      registrar: registrar,
    );

    final result = await useCase.execute(id: 1, isActive: true);

    expect(result.isSuccess, isTrue);
    expect(repo.activeUpdates, {1: true});
    expect(registrar.registered.single.id, 1);
    expect(registrar.registered.single.isActive, isTrue);
  });

  test('SetGeofenceActiveUseCase 비활성화는 DB 갱신 후 OS unregister 를 호출한다', () async {
    final repo = _FakeRepository([geofence(isActive: true)]);
    final registrar = _FakeRegistrar();
    final useCase = SetGeofenceActiveUseCase(
      repo: repo,
      registrar: registrar,
    );

    final result = await useCase.execute(id: 1, isActive: false);

    expect(result.isSuccess, isTrue);
    expect(repo.activeUpdates, {1: false});
    expect(registrar.unregisteredIds, [1]);
  });

  test('SetGeofenceActiveUseCase 실패는 error 결과로 반환한다', () async {
    final error = StateError('register failed');
    final useCase = SetGeofenceActiveUseCase(
      repo: _FakeRepository([geofence()]),
      registrar: _FakeRegistrar(registerError: error),
    );

    final result = await useCase.execute(id: 1, isActive: true);

    expect(result.isSuccess, isFalse);
    expect(result.error, same(error));
  });

  test('DeleteGeofenceUseCase 는 DB 삭제 후 OS unregister 를 호출한다', () async {
    final repo = _FakeRepository([geofence()]);
    final registrar = _FakeRegistrar();
    final useCase = DeleteGeofenceUseCase(repo: repo, registrar: registrar);

    final result = await useCase.execute(1);

    expect(result.isSuccess, isTrue);
    expect(repo.deletedIds, [1]);
    expect(registrar.unregisteredIds, [1]);
  });
}

class _FakeRepository implements GeofenceLocalRepository {
  final List<GeofenceEntity> rows;
  final activeUpdates = <int, bool>{};
  final deletedIds = <int>[];

  _FakeRepository(this.rows);

  @override
  Future<List<GeofenceEntity>> findAll() async => [...rows];

  @override
  Future<GeofenceEntity> save(GeofenceEntity entity) async => entity;

  @override
  Future<void> update(GeofenceEntity entity) async {}

  @override
  Future<void> delete(int id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> updateActiveStatus(int id, bool isActive) async {
    activeUpdates[id] = isActive;
  }

  @override
  Future<void> updateAddress(int id, String address) async {}

  @override
  Future<void> updateAwaitingDeparture(
    int id,
    bool awaitingDeparture,
  ) async {}
}

class _FakeRegistrar implements NativeGeofenceRegistrarInterface {
  final Object? registerError;
  final registered = <GeofenceEntity>[];
  final unregisteredIds = <int>[];

  _FakeRegistrar({this.registerError});

  @override
  Future<List<String>> getRegisteredIds() async => [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> register(GeofenceEntity geofence) async {
    final error = registerError;
    if (error != null) throw error;
    registered.add(geofence);
  }

  @override
  Future<void> syncAll(List<GeofenceEntity> activeGeofences) async {}

  @override
  Future<void> unregister(int geofenceId) async {
    unregisteredIds.add(geofenceId);
  }
}
