import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/update_friend_alias_request_dto.dart';
import 'package:iamhere/feature/friend/service/friend_relationship_service_interface.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: FriendRelationshipServiceInterface)
class FriendRelationshipService implements FriendRelationshipServiceInterface {
  final Dio _dio;

  FriendRelationshipService({required Dio dio}) : _dio = dio;

  @override
  Future<List<FriendRelationshipResponseDto>> fetchFriendList() async {
    try {
      final response = await _dio.get(
        ApiConfig.friendListPath,
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : body;

        if (data is List) {
          return data
              .map(
                (e) => FriendRelationshipResponseDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
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
      final response = await _dio.post(
        ApiConfig.friendAliasPath,
        data: request.toJson(),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : body;
        if (data is Map<String, dynamic>) {
          return FriendRelationshipResponseDto.fromJson(data);
        }
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
        ApiConfig.friendBlockPath(friendRelationshipId),
        options: ApiConfig.authOptions,
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
        ApiConfig.friendDeletePath(friendRelationshipId),
        options: ApiConfig.authOptions,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      AppLogger.error('친구 삭제 실패: ${e.message}');
      return false;
    }
  }
}
