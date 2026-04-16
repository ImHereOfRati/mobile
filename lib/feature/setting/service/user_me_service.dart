import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/api_config.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserMeServiceInterface)
class UserMeService implements UserMeServiceInterface {
  final Dio _dio;

  UserMeService({required Dio dio}) : _dio = dio;

  @override
  Future<UserMeResponseDto?> fetchMyInfo() async {
    try {
      final response = await _dio.get(
        ApiConfig.userMePath,
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;

        if (data is Map<String, dynamic>) {
          return UserMeResponseDto.fromJson(data);
        }
      }

      return null;
    } on DioException catch (e) {
      debugPrint('내 정보 조회 실패: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('내 정보 조회 중 오류: $e');
      return null;
    }
  }
}
