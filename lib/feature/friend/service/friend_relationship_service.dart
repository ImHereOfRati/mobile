import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/update_friend_alias_request_dto.dart';
import 'package:iamhere/feature/friend/service/friend_relationship_service_interface.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: FriendRelationshipServiceInterface)
class FriendRelationshipService implements FriendRelationshipServiceInterface {
  static const String _friendListPath = '/api/friendships';
  static String _friendAliasPath(String id) => '/api/friendships/$id/alias';
  static String _friendBlockPath(String id) => '/api/friendships/$id/block';
  static String _friendDeletePath(String id) => '/api/friendships/$id';

  final Dio _dio;

  FriendRelationshipService({required Dio dio}) : _dio = dio;

  @override
  Future<List<FriendRelationshipResponseDto>> fetchFriendList() async {
    try {
      final response = await _dio.get(
        _friendListPath,
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseSlice<FriendRelationshipResponseDto>(
              response.data,
              FriendRelationshipResponseDto.fromJson,
            ).data?.content ??
            const [];
      }
      return [];
    } on DioException catch (e) {
      AppLogger.error('친구 목록 조회 실패: ${e.message}');
      return [];
    }
  }

  @override
  Future<FriendRelationshipResponseDto?> updateAlias(
    UpdateFriendAliasRequestDto request,
  ) async {
    try {
      final response = await _dio.patch(
        _friendAliasPath(request.friendRelationshipId!),
        data: request.toJson(),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<FriendRelationshipResponseDto>(
          response.data,
          FriendRelationshipResponseDto.fromJson,
        ).data;
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('별명 변경 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<bool> blockFriend(String friendRelationshipId) async {
    try {
      final response = await _dio.post(
        _friendBlockPath(friendRelationshipId),
        options: Options(extra: const {'requiresAuthentication': true}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      AppLogger.error('친구 차단 실패: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> deleteFriend(String friendRelationshipId) async {
    try {
      final response = await _dio.delete(
        _friendDeletePath(friendRelationshipId),
        options: Options(extra: const {'requiresAuthentication': true}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      AppLogger.error('친구 삭제 실패: ${e.message}');
      return false;
    }
  }
}
