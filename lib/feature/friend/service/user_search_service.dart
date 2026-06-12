import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/user_search_response_dto.dart';
import 'package:iamhere/feature/friend/service/user_search_service_interface.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserSearchServiceInterface)
class UserSearchService implements UserSearchServiceInterface {
  static const String _userSearchPath = '/api/users';

  final Dio _dio;

  UserSearchService({required Dio dio}) : _dio = dio;

  @override
  Future<List<UserSearchResponseDto>> searchByNickname(String keyword) async {
    try {
      final response = await _dio.get(
        _userSearchPath,
        queryParameters: {'keyword': keyword},
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseSlice<UserSearchResponseDto>(
              response.data,
              UserSearchResponseDto.fromJson,
            ).data?.content ??
            const [];
      }

      return [];
    } on DioException catch (e) {
      AppLogger.error('유저 검색 실패: ${e.message}');
      AppLogger.error('Response: ${e.response?.data}');
      return [];
    } catch (e) {
      AppLogger.error('유저 검색 중 오류: $e');
      return [];
    }
  }
}
