import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/user_search_response_dto.dart';
import 'package:iamhere/feature/friend/service/user_search_service_interface.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserSearchServiceInterface)
class UserSearchService implements UserSearchServiceInterface {
  final Dio _dio;

  UserSearchService({required Dio dio}) : _dio = dio;

  @override
  Future<List<UserSearchResponseDto>> searchByNickname(String keyword) async {
    try {
      final response = await _dio.get(
        ApiConfig.userSearchPath(keyword),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : body;

        if (data is List) {
          return data
              .map(
                (e) =>
                    UserSearchResponseDto.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      debugPrint('유저 검색 실패: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return [];
    } catch (e) {
      debugPrint('유저 검색 중 오류: $e');
      return [];
    }
  }
}
