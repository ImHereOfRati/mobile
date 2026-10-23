import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/application/drain_delivery_queue_use_case.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:iamhere/feature/geofence/model/delivery_event.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

void main() {
  test('processPending 이후 retry scheduler 를 호출한다', () async {
    final pipeline = _FakePipeline();
    final scheduler = _FakeRetryScheduler();
    final useCase = DrainDeliveryQueueUseCase(
      pipeline: pipeline,
      retryScheduler: scheduler,
    );

    await useCase.execute(limit: 3, replaceExistingSchedule: false);

    expect(pipeline.processedLimits, [3]);
    expect(scheduler.replaceExistingValues, [false]);
  });
}

class _FakePipeline implements GeofenceDeliveryPipeline {
  final processedLimits = <int>[];

  @override
  Future<bool> enqueueTriggeredGeofence({
    required GeofenceEntity geofence,
    required DeliveryEvent event,
  }) async => true;

  @override
  Future<void> processPending({int limit = 10}) async {
    processedLimits.add(limit);
  }
}

class _FakeRetryScheduler implements GeofenceRetryScheduler {
  final replaceExistingValues = <bool>[];

  @override
  Future<void> scheduleNextIfNeeded({bool replaceExisting = true}) async {
    replaceExistingValues.add(replaceExisting);
  }
}
