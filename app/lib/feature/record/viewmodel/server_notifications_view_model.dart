import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/record/model/dto/server_notification_dto.dart';
import 'package:iamhere/feature/record/model/service/server_notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_notifications_view_model.g.dart';

@riverpod
class ServerNotificationsViewModel extends _$ServerNotificationsViewModel {
  late ServerNotificationService _service;

  @override
  Future<PagedItems<ServerNotificationDto>> build(
    ServerNotificationService service,
  ) {
    _service = service;
    return service.load(0);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final nextPage = current.page + 1;
    try {
      final next = await _service.load(nextPage);
      if (ref.mounted) state = AsyncData(current.append(next, nextPage));
    } catch (error, stack) {
      AppLogger.error('Notification page load failed', error, stack);
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> markAsRead(ServerNotificationDto item) async {
    try {
      await _service.markAsRead(item.id);
      final current = state.value;
      if (current != null && ref.mounted) {
        state = AsyncData(
          current.replaceWhere((value) => value.id == item.id, item.asRead()),
        );
      }
      return null;
    } catch (error, stack) {
      AppLogger.error('Mark as read failed', error, stack);
      return '읽음으로 표시하지 못했어요';
    }
  }
}
