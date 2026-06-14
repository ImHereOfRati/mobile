import 'dart:io';

import 'package:iamhere/common/util/app_logger.dart';
import 'package:workmanager/workmanager.dart';

import 'geofence_delivery_queue_database_service.dart';

class GeofenceRetryScheduler {
  static const uniqueWorkName = 'geofence_delivery_retry';
  static const taskName = 'geofence_delivery_retry_task';

  final GeofenceDeliveryQueueDatabaseService _queue;

  GeofenceRetryScheduler(this._queue);

  Future<void> scheduleNextIfNeeded({bool replaceExisting = true}) async {
    if (!Platform.isAndroid) return;

    try {
      final nextAttemptAt = await _queue.findEarliestPendingAttemptAt();
      if (nextAttemptAt == null) {
        await Workmanager().cancelByUniqueName(uniqueWorkName);
        return;
      }

      final delay = nextAttemptAt.toUtc().difference(DateTime.now().toUtc());
      await Workmanager().registerOneOffTask(
        uniqueWorkName,
        taskName,
        existingWorkPolicy: replaceExisting
            ? ExistingWorkPolicy.replace
            : ExistingWorkPolicy.keep,
        initialDelay: delay.isNegative ? Duration.zero : delay,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e, st) {
      AppLogger.error('백그라운드 재시도 스케줄링 실패', e, st);
    }
  }
}
