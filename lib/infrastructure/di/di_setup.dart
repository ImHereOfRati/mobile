import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_database_service.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/record_service.dart';

import 'di_setup.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // 초기화 함수 이름 (기본값 init)
  preferRelativeImports: true, // 생성된 코드에서 상대 경로 사용
  asExtension: true, // getIt.init() 처럼 확장 함수 형태로 생성
)
Future<void> enrollBaseUrlGlobally({required String baseUrl}) async {
  getIt.registerSingleton<String>(baseUrl, instanceName: "baseUrl");
  await getIt.init();

  if (!getIt.isRegistered<GeofenceDeliveryQueueDatabaseService>()) {
    getIt.registerLazySingleton<GeofenceDeliveryQueueDatabaseService>(
      () => GeofenceDeliveryQueueDatabaseService(
        getIt<Database>(),
      ),
    );
  }

  if (!getIt.isRegistered<GeofenceDeliveryPipeline>()) {
    getIt.registerLazySingleton<GeofenceDeliveryPipeline>(
      () => GeofenceDeliveryPipeline(
        getIt<GeofenceDeliveryQueueDatabaseService>(),
        getIt<ContactResolutionService>(),
        getIt<GeofenceLocalRepository>(),
        getIt<NativeGeofenceRegistrarInterface>(),
        getIt<SmsNotificationService>(),
        getIt<FcmArrivalService>(),
        getIt<RecordService>(),
      ),
    );
  }
}
