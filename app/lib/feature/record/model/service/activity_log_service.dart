import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_local_repository.dart';
import 'package:iamhere/feature/record/model/repository/notification_entity.dart';
import 'package:iamhere/feature/record/model/repository/notification_local_repository.dart';
import 'package:injectable/injectable.dart';

/// 이 기기에 쌓인 활동 기록. 자동 전송 결과와 이 기기가 받은 푸시 알림이다.
@injectable
class ActivityLogService {
  static const pageSize = 20;

  final GeofenceRecordLocalRepository _records;
  final NotificationLocalRepository _notifications;

  ActivityLogService(this._records, this._notifications);

  /// 로컬 DB는 한 번에 최신순으로 읽고, 화면은 [offset]부터 [limit]건씩 잘라 쓴다.
  Future<PagedItems<GeofenceRecordEntity>> records({
    int offset = 0,
    int limit = pageSize,
  }) async =>
      _slice(await _records.findAllOrderByCreatedAtDesc(), offset, limit);

  Future<PagedItems<NotificationEntity>> notifications({
    int offset = 0,
    int limit = pageSize,
  }) async =>
      _slice(await _notifications.findAllOrderByCreatedAtDesc(), offset, limit);

  Future<GeofenceRecordEntity?> findRecord(int id) async {
    final all = await _records.findAllOrderByCreatedAtDesc();
    return all.where((item) => item.id == id).firstOrNull;
  }

  Future<NotificationEntity?> findNotification(int id) async {
    final all = await _notifications.findAllOrderByCreatedAtDesc();
    return all.where((item) => item.id == id).firstOrNull;
  }

  Future<void> deleteRecord(int id) => _records.delete(id);

  Future<void> deleteAllRecords() => _records.deleteAll();

  Future<void> deleteAllNotifications() => _notifications.deleteAll();

  static PagedItems<T> _slice<T>(List<T> all, int offset, int limit) {
    final start = offset.clamp(0, all.length);
    final end = (start + limit).clamp(start, all.length);
    return PagedItems(
      items: all.sublist(start, end),
      hasNext: end < all.length,
    );
  }
}
