import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/friend/model/dto/friend_request_dto.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/model/type/friend_request_view_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_requests_view_model.g.dart';

@riverpod
class FriendRequestsViewModel extends _$FriendRequestsViewModel {
  late FriendService _friends;
  late FriendRequestViewType _type;

  @override
  Future<PagedItems<FriendRequestDto>> build(
    FriendService friendService,
    FriendRequestViewType type,
  ) {
    _friends = friendService;
    _type = type;
    return friendService.loadRequests(0, type);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final nextPage = current.page + 1;
    try {
      final next = await _friends.loadRequests(nextPage, _type);
      if (ref.mounted) state = AsyncData(current.append(next, nextPage));
    } catch (error, stack) {
      AppLogger.error('Friend request page load failed', error, stack);
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// 성공하면 사용자에게 보여줄 결과 메시지, 실패하면 실패 메시지를 돌려준다.
  Future<String> respond(
    FriendRequestDto request, {
    required bool accept,
  }) async {
    try {
      await (accept
          ? _friends.accept(request.id)
          : _friends.reject(request.id));
      _drop(request);
      return accept ? '친구 요청을 수락했어요' : '친구 요청을 거절했어요';
    } catch (error, stack) {
      AppLogger.error('Friend request response failed', error, stack);
      return '친구 요청을 처리하지 못했어요';
    }
  }

  /// 삭제와 취소는 거절과 다르다. 거절은 상대를 제한 목록에 남기지만 이쪽은 요청
  /// 자체만 지운다.
  Future<String> discard(FriendRequestDto request) async {
    final label = _type == FriendRequestViewType.sent ? '취소' : '삭제';
    try {
      await _friends.discardRequest(request.id, _type);
      _drop(request);
      return '요청을 $label했어요';
    } catch (error, stack) {
      AppLogger.error('Friend request discard failed', error, stack);
      return '요청을 $label하지 못했어요';
    }
  }

  /// 상세를 서버에서 다시 읽는다. 실패하면 null.
  Future<FriendRequestDto?> detail(FriendRequestDto request) async {
    try {
      return await _friends.request(request.id);
    } catch (error, stack) {
      AppLogger.error('Friend request detail failed', error, stack);
      return null;
    }
  }

  void _drop(FriendRequestDto request) {
    final current = state.value;
    if (current == null || !ref.mounted) return;
    state = AsyncData(current.removeWhere((item) => item.id == request.id));
  }
}
