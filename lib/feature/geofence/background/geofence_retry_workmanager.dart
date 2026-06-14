import 'package:get_it/get_it.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_background_runtime.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void geofenceRetryCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await bootstrapBackgroundRuntime();
      await GetIt.instance<GeofenceDeliveryPipeline>().processPending();
      await GetIt.instance<GeofenceRetryScheduler>().scheduleNextIfNeeded(
        replaceExisting: false,
      );
      return true;
    } catch (e, st) {
      AppLogger.error('백그라운드 재시도 워커 실패', e, st);
      return false;
    }
  });
}
