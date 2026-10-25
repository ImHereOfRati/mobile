import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/friend/model/dto/friend_restriction_dto.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_restrictions_view_model.g.dart';

@riverpod
class FriendRestrictionsViewModel extends _$FriendRestrictionsViewModel {
  late FriendService _friends;

  @override
  Future<PagedItems<FriendRestrictionDto>> build(FriendService friendService) {
    _friends = friendService;
    return friendService.loadRestrictions(0);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final nextPage = current.page + 1;
    try {
      final next = await _friends.loadRestrictions(nextPage);
      if (ref.mounted) state = AsyncData(current.append(next, nextPage));
    } catch (error, stack) {
      AppLogger.error('Restriction page load failed', error, stack);
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> unblock(FriendRestrictionDto item) async {
    try {
      await _friends.unblock(item.restricted.id);
      final current = state.value;
      if (current != null && ref.mounted) {
        state = AsyncData(current.removeWhere((value) => value.id == item.id));
      }
      return null;
    } catch (error, stack) {
      AppLogger.error('Unblock failed', error, stack);
      return '제한을 해제하지 못했어요';
    }
  }
}
