import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/application/handle_geofence_trigger_use_case.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';

void main() {
  GeofenceEntity geofence({
    int id = 1,
    bool isActive = true,
    String eventType = 'arrival',
    bool awaitingDeparture = false,
  }) {
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
      eventType: eventType,
      awaitingDeparture: awaitingDeparture,
    );
  }

  test('허용된 trigger 를 queue 에 넣고 단일 이벤트는 비활성화한다', () async {
    final repo = _FakeGeofenceRepository([geofence()]);
    final pipeline = _FakeDeliveryPipeline(accepted: true);
    final useCase = HandleGeofenceTriggerUseCase(
      repo: repo,
      pipeline: pipeline,
    );

    final result = await useCase.execute(
      geofenceId: 1,
      deliveryEvent: DeliveryEvent.arrival,
    );

    expect(result.status, GeofenceTriggerStatus.queued);
    expect(pipeline.enqueuedEvents, [DeliveryEvent.arrival]);
    expect(repo.activeUpdates, {1: false});
    expect(repo.awaitingUpdates, isEmpty);
  });

  test('both + arrival trigger 는 awaitingDeparture=true 로 전이한다', () async {
    final repo = _FakeGeofenceRepository([
      geofence(eventType: 'both', awaitingDeparture: false),
    ]);
    final useCase = HandleGeofenceTriggerUseCase(
      repo: repo,
      pipeline: _FakeDeliveryPipeline(accepted: true),
    );

    final result = await useCase.execute(
      geofenceId: 1,
      deliveryEvent: DeliveryEvent.arrival,
    );

    expect(result.status, GeofenceTriggerStatus.queued);
    expect(repo.awaitingUpdates, {1: true});
    expect(repo.activeUpdates, isEmpty);
  });

  test('필터에서 무시된 trigger 는 queue 와 상태를 변경하지 않는다', () async {
    final repo = _FakeGeofenceRepository([
      geofence(eventType: 'arrival'),
    ]);
    final pipeline = _FakeDeliveryPipeline(accepted: true);
    final useCase = HandleGeofenceTriggerUseCase(
      repo: repo,
      pipeline: pipeline,
    );

    final result = await useCase.execute(
      geofenceId: 1,
      deliveryEvent: DeliveryEvent.departure,
    );

    expect(result.status, GeofenceTriggerStatus.ignored);
    expect(pipeline.enqueuedEvents, isEmpty);
    expect(repo.activeUpdates, isEmpty);
    expect(repo.awaitingUpdates, isEmpty);
  });

  test('queue 가 중복으로 거절하면 상태를 변경하지 않는다', () async {
    final repo = _FakeGeofenceRepository([geofence()]);
    final useCase = HandleGeofenceTriggerUseCase(
      repo: repo,
      pipeline: _FakeDeliveryPipeline(accepted: false),
    );

    final result = await useCase.execute(
      geofenceId: 1,
      deliveryEvent: DeliveryEvent.arrival,
    );

    expect(result.status, GeofenceTriggerStatus.rejected);
    expect(repo.activeUpdates, isEmpty);
    expect(repo.awaitingUpdates, isEmpty);
  });
}

class _FakeGeofenceRepository implements GeofenceLocalRepository {
  final List<GeofenceEntity> rows;
  final activeUpdates = <int, bool>{};
  final awaitingUpdates = <int, bool>{};

  _FakeGeofenceRepository(this.rows);

  @override
  Future<List<GeofenceEntity>> findAll() async => [...rows];

  @override
  Future<GeofenceEntity> save(GeofenceEntity entity) async => entity;

  @override
  Future<void> update(GeofenceEntity entity) async {}

  @override
  Future<void> delete(int id) async {}

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
  ) async {
    awaitingUpdates[id] = awaitingDeparture;
  }
}

class _FakeDeliveryPipeline implements GeofenceDeliveryPipeline {
  final bool accepted;
  final enqueuedEvents = <DeliveryEvent>[];

  _FakeDeliveryPipeline({required this.accepted});

  @override
  Future<bool> enqueueTriggeredGeofence({
    required GeofenceEntity geofence,
    required DeliveryEvent event,
  }) async {
    enqueuedEvents.add(event);
    return accepted;
  }

  @override
  Future<void> processPending({int limit = 10}) async {}
}
