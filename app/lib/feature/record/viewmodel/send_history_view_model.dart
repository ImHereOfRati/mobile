import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_history_view_model.g.dart';

@riverpod
class SendHistoryViewModel extends _$SendHistoryViewModel {
  late ActivityLogService _activity;

  @override
  Future<PagedItems<GeofenceRecordEntity>> build(ActivityLogService service) {
    _activity = service;
    return service.records();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final nextPage = current.page + 1;
    try {
      final next = await _activity.records(
        offset: nextPage * ActivityLogService.pageSize,
      );
      if (ref.mounted) state = AsyncData(current.append(next, nextPage));
    } catch (error, stack) {
      AppLogger.error('Send history page load failed', error, stack);
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// 로딩 화면으로 돌아가지 않고 처음부터 다시 읽는다. 앱으로 돌아왔을 때 호출한다.
  Future<void> refresh() async {
    try {
      final first = await _activity.records();
      if (ref.mounted) state = AsyncData(first);
    } catch (error, stack) {
      AppLogger.error('Send history refresh failed', error, stack);
    }
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> delete(GeofenceRecordEntity record) async {
    try {
      await _activity.deleteRecord(record.id!);
      final current = state.value;
      if (current != null && ref.mounted) {
        state = AsyncData(current.removeWhere((item) => item.id == record.id));
      }
      return null;
    } catch (error, stack) {
      AppLogger.error('Record delete failed', error, stack);
      return '전송 기록을 삭제하지 못했어요';
    }
  }

  Future<String?> deleteAll() async {
    try {
      await _activity.deleteAllRecords();
      if (ref.mounted) state = const AsyncData(PagedItems.empty());
      return null;
    } catch (error, stack) {
      AppLogger.error('Record delete all failed', error, stack);
      return '전송 기록을 삭제하지 못했어요';
    }
  }
}
