import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/friend_restriction_deleted_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/friend_restriction_response_dto.dart';
import 'package:iamhere/feature/friend/service/friend_restriction_service_interface.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: FriendRestrictionServiceInterface)
class FriendRestrictionService implements FriendRestrictionServiceInterface {
  final Dio _dio;

  FriendRestrictionService({required Dio dio}) : _dio = dio;

  @override
  Future<List<FriendRestrictionResponseDto>> fetchRestrictions() async {
    try {
      final response = await _dio.get(
        ApiConfig.friendRestrictionPath,
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : body;

        if (data is List) {
          return data
              .map((e) => FriendRestrictionResponseDto.fromJson(
                  e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('제한 목록 조회 실패: ${e.message}');
      return [];
    }
  }

  @override
  Future<FriendRestrictionDeletedResponseDto?> deleteRestriction(
      int friendRestrictionId) async {
    try {
      final response = await _dio.delete(
        ApiConfig.friendRestrictionDeletePath(friendRestrictionId),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        if (data is Map<String, dynamic>) {
          return FriendRestrictionDeletedResponseDto.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('제한 해제 실패: ${e.message}');
      return null;
    }
  }
}
