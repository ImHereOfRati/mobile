import 'package:iamhere/feature/record/model/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/model/repository/notification_entity.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_detail_provider.g.dart';

@riverpod
Future<GeofenceRecordEntity?> sendRecordDetail(
  Ref ref,
  ActivityLogService service,
  int id,
) {
  return service.findRecord(id);
}

@riverpod
Future<NotificationEntity?> notificationDetail(
  Ref ref,
  ActivityLogService service,
  int id,
) {
  return service.findNotification(id);
}
