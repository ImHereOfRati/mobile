import 'package:dio/dio.dart';
import 'package:iamhere/core/api_response/slice_response.dart';
import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/feature/friend/model/dto/friend_request_dto.dart';
import 'package:iamhere/feature/friend/model/dto/friend_restriction_dto.dart';
import 'package:iamhere/feature/friend/model/dto/friend_user_dto.dart';
import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/friend_repository.dart';
import 'package:iamhere/feature/friend/model/type/friend_relation.dart';
import 'package:iamhere/feature/friend/model/type/friend_request_view_type.dart';
import 'package:iamhere/feature/record/model/service/server_notification_service.dart';
import 'package:injectable/injectable.dart';

/// 검색 결과 한 사람과 그 사람에 대한 나의 관계.
class FriendCandidate {
  final FriendUserDto user;
  final FriendRelation relation;

  const FriendCandidate(this.user, this.relation);
}

@injectable
class FriendService {
  final FriendRepository _repository;
  final ServerNotificationService _notifications;

  FriendService(this._repository, this._notifications);

  /// 일부 서버 배포는 친구가 없는 계정에 404를 준다. 로드 실패가 아니라 빈 목록으로
  /// 본다.
  Future<PagedItems<FriendshipDto>> loadFriendships(int page) async {
    try {
      return _paged(await _repository.fetchFriendships(page));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const PagedItems.empty();
      rethrow;
    }
  }

  Future<FriendshipDto> friendship(String id) =>
      _repository.fetchFriendship(id);

  Future<FriendshipDto> updateAlias(String id, String alias) =>
      _repository.updateAlias(id, alias);

  Future<void> deleteFriend(String id) => _repository.deleteFriendship(id);

  Future<void> block(String targetUserId) => _repository.block(targetUserId);

  Future<void> notifyArrival(String targetUserId) =>
      _notifications.sendArrival(targetUserId);

  /// 검색 결과만으로는 이미 친구인지, 내가 차단한 상대인지 알 수 없다. 상대 기준으로
  /// 서버에 되물어 관계를 붙인다. 실패한 항목은 관계 없음으로 두고 검색 자체를 막지
  /// 않는다.
  Future<List<FriendCandidate>> search(String keyword) async {
    final page = await _repository.searchUsers(keyword.trim());
    return Future.wait(
      page.content.map(
        (user) async => FriendCandidate(user, await _relation(user)),
      ),
    );
  }

  Future<void> sendRequest(String targetId, String message) =>
      _repository.sendRequest(targetId, message);

  Future<PagedItems<FriendRequestDto>> loadRequests(
    int page,
    FriendRequestViewType type,
  ) async => _paged(await _repository.fetchRequests(page, type));

  Future<FriendRequestDto> request(String id) => _repository.fetchRequest(id);

  Future<void> accept(String id) => _repository.acceptRequest(id);

  Future<void> reject(String id) => _repository.rejectRequest(id);

  Future<void> discardRequest(String id, FriendRequestViewType type) =>
      _repository.discardRequest(id, type);

  Future<PagedItems<FriendRestrictionDto>> loadRestrictions(int page) async =>
      _paged(await _repository.fetchRestrictions(page));

  Future<void> unblock(String targetUserId) =>
      _repository.unblock(targetUserId);

  Future<FriendRelation> _relation(FriendUserDto user) async {
    final results = await Future.wait([
      _repository
          .isFriend(user.id)
          .then<bool?>((v) => v)
          .catchError((_) => null),
      _repository
          .isRestricted(user.id)
          .then<bool?>((v) => v)
          .catchError((_) => null),
    ]);
    if (results[0] == true) return FriendRelation.friend;
    if (results[1] == true) return FriendRelation.restricted;
    return FriendRelation.none;
  }

  static PagedItems<T> _paged<T>(SliceResponse<T> slice) =>
      PagedItems(items: slice.content, hasNext: slice.hasNext);
}
