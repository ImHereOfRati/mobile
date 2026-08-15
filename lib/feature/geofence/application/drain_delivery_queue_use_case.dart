import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';

class DrainDeliveryQueueUseCase {
  final GeofenceDeliveryPipeline _pipeline;
  final GeofenceRetryScheduler _retryScheduler;

  const DrainDeliveryQueueUseCase({
    required GeofenceDeliveryPipeline pipeline,
    required GeofenceRetryScheduler retryScheduler,
  }) : _pipeline = pipeline,
       _retryScheduler = retryScheduler;

  Future<void> execute({
    int limit = 10,
    bool replaceExistingSchedule = false,
  }) async {
    await _pipeline.processPending(limit: limit);
    await _retryScheduler.scheduleNextIfNeeded(
      replaceExisting: replaceExistingSchedule,
    );
  }
}
