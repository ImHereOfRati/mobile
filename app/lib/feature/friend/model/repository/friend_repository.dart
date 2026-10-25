import 'package:dio/dio.dart';
import 'package:iamhere/core/api_response/api_response_parser.dart';
import 'package:iamhere/core/api_response/slice_response.dart';
import 'package:iamhere/feature/friend/model/dto/friend_request_dto.dart';
import 'package:iamhere/feature/friend/model/dto/friend_restriction_dto.dart';
import 'package:iamhere/feature/friend/model/dto/friend_user_dto.dart';
import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/type/friend_request_view_type.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FriendRepository {
  static const pageSize = 20;
  static const _friendships = '/api/friendships';
  static const _requests = '/api/friends/requests';
  static const _restrictions = '/api/friends/restrictions';
  static const _users = '/api/users';

  final Dio _dio;

  FriendRepository(this._dio);

  static final _authenticated = Options(
    extra: const {'requiresAuthentication': true},
  );

  Future<SliceResponse<FriendshipDto>> fetchFriendships(int page) async {
    final response = await _dio.get(
      _friendships,
      queryParameters: _page(page),
      options: _authenticated,
    );
    return _slice(response.data, FriendshipDto.fromJson);
  }

  Future<FriendshipDto> fetchFriendship(String id) async {
    final response = await _dio.get(
      '$_friendships/$id',
      options: _authenticated,
    );
    return _object(response.data, FriendshipDto.fromJson);
  }

  Future<bool> isFriend(String targetUserId) =>
      _bool('$_friendships/target/$targetUserId');

  Future<bool> isRestricted(String targetUserId) =>
      _bool('$_restrictions/target/$targetUserId');

  Future<FriendshipDto> updateAlias(String id, String alias) async {
    final response = await _dio.patch(
      '$_friendships/$id/alias',
      data: {'alias': alias},
      options: _authenticated,
    );
    return _object(response.data, FriendshipDto.fromJson);
  }

  Future<void> deleteFriendship(String id) async {
    await _dio.delete<void>('$_friendships/$id', options: _authenticated);
  }

  Future<void> block(String targetUserId) async {
    await _dio.post<void>(
      _restrictions,
      data: {'targetUserId': targetUserId},
      options: _authenticated,
    );
  }

  Future<SliceResponse<FriendUserDto>> searchUsers(
    String keyword, {
    int page = 0,
  }) async {
    final response = await _dio.get(
      _users,
      queryParameters: {'keyword': keyword, ..._page(page)},
      options: _authenticated,
    );
    return _slice(response.data, FriendUserDto.fromJson);
  }

  Future<void> sendRequest(String targetId, String message) async {
    await _dio.post<void>(
      _requests,
      data: {'targetId': targetId, 'message': message},
      options: _authenticated,
    );
  }

  Future<SliceResponse<FriendRequestDto>> fetchRequests(
    int page,
    FriendRequestViewType type,
  ) async {
    final response = await _dio.get(
      _requests,
      queryParameters: {'type': type.apiValue, ..._page(page)},
      options: _authenticated,
    );
    return _slice(response.data, FriendRequestDto.fromJson);
  }

  Future<FriendRequestDto> fetchRequest(String id) async {
    final response = await _dio.get('$_requests/$id', options: _authenticated);
    return _object(response.data, FriendRequestDto.fromJson);
  }

  /// 받은 요청은 삭제, 보낸 요청은 취소로 서버 경로가 갈린다. 거절과 달리 둘 다
  /// 상대에게 제한을 남기지 않고 요청 자체만 없앤다.
  Future<void> discardRequest(String id, FriendRequestViewType type) async {
    final path = type == FriendRequestViewType.sent
        ? '$_requests/$id/sent'
        : '$_requests/$id';
    await _dio.delete<void>(path, options: _authenticated);
  }

  Future<void> acceptRequest(String id) async {
    await _dio.post<void>('$_requests/$id/accept', options: _authenticated);
  }

  Future<void> rejectRequest(String id) async {
    await _dio.post<void>('$_requests/$id/reject', options: _authenticated);
  }

  Future<SliceResponse<FriendRestrictionDto>> fetchRestrictions(
    int page,
  ) async {
    final response = await _dio.get(
      _restrictions,
      queryParameters: _page(page),
      options: _authenticated,
    );
    return _slice(response.data, FriendRestrictionDto.fromJson);
  }

  Future<void> unblock(String targetUserId) async {
    await _dio.delete<void>(
      '$_restrictions/blocked-users/$targetUserId',
      options: _authenticated,
    );
  }

  /// 서버는 참·거짓만 준다. 다른 형태의 응답은 관계 없음으로 읽는다.
  Future<bool> _bool(String path) async {
    final response = await _dio.get(path, options: _authenticated);
    final raw = response.data;
    return raw is Map && raw['data'] == true;
  }

  static Map<String, int> _page(int page) => {'page': page, 'size': pageSize};

  static SliceResponse<T> _slice<T>(dynamic raw, JsonItemParser<T> fromJson) {
    final data = ApiResponseParser.parseSlice<T>(raw, fromJson).data;
    return data ?? SliceResponse<T>(content: const [], hasNext: false);
  }

  static T _object<T>(dynamic raw, JsonItemParser<T> fromJson) {
    final data = ApiResponseParser.parseObject<T>(raw, fromJson).data;
    if (data == null) throw StateError('응답에 데이터가 없습니다.');
    return data;
  }
}
