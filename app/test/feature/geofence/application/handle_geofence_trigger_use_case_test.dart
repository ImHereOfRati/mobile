import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/application/handle_geofence_trigger_use_case.dart';
import 'package:iamhere/feature/geofence/delivery/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_local_repository.dart';

void main() {
  GeofenceEntity geofence({
    int id = 1,
    bool isActive = true,
    String eventType = 'arrival',
    String repeatType = 'none',
    int? customDaysBitmask,
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
      repeatType: repeatType,
      customDaysBitmask: customDaysBitmask,
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
    final repo = _FakeGeofenceRepository([geofence(eventType: 'arrival')]);
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

  test('반복 알림은 발송 후에도 장소를 활성 상태로 둔다', () async {
    final repo = _FakeGeofenceRepository([geofence(repeatType: 'daily')]);
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
    expect(repo.activeUpdates, isEmpty);
  });

  test('선택하지 않은 요일에는 반복 알림을 보내지 않는다', () async {
    final repo = _FakeGeofenceRepository([
      geofence(repeatType: 'custom', customDaysBitmask: 1), // 월요일만
    ]);
    final pipeline = _FakeDeliveryPipeline(accepted: true);
    final useCase = HandleGeofenceTriggerUseCase(
      repo: repo,
      pipeline: pipeline,
      nowLocal: () => DateTime(2026, 10, 25), // 일요일
    );

    final result = await useCase.execute(
      geofenceId: 1,
      deliveryEvent: DeliveryEvent.arrival,
    );

    expect(result.status, GeofenceTriggerStatus.ignored);
    expect(pipeline.enqueuedEvents, isEmpty);
  });

  test('선택한 요일에는 반복 알림을 보낸다', () async {
    final repo = _FakeGeofenceRepository([
      geofence(repeatType: 'custom', customDaysBitmask: 1),
    ]);
    final pipeline = _FakeDeliveryPipeline(accepted: true);
    final useCase = HandleGeofenceTriggerUseCase(
      repo: repo,
      pipeline: pipeline,
      nowLocal: () => DateTime(2026, 10, 26), // 월요일
    );

    final result = await useCase.execute(
      geofenceId: 1,
      deliveryEvent: DeliveryEvent.arrival,
    );

    expect(result.status, GeofenceTriggerStatus.queued);
    expect(pipeline.enqueuedEvents, [DeliveryEvent.arrival]);
    expect(repo.activeUpdates, isEmpty);
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
  Future<void> updateAwaitingDeparture(int id, bool awaitingDeparture) async {
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
