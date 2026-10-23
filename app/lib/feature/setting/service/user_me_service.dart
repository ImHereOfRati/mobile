import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/invalid_auth_session_exception.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserMeServiceInterface)
class UserMeService implements UserMeServiceInterface {
  static const _userMePath = '/api/users/my';

  final Dio _dio;

  UserMeService({required Dio dio}) : _dio = dio;

  @override
  Future<UserMeResponseDto?> fetchMyInfo() async {
    try {
      final response = await _dio.get(
        _userMePath,
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode != 200) return null;
      return ApiResponseParser.parseObject<UserMeResponseDto>(
        response.data,
        UserMeResponseDto.fromJson,
      ).data;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw InvalidAuthSessionException(statusCode!);
      }
      AppLogger.error('Failed to load current user: ${error.message}');
      return null;
    } catch (error) {
      AppLogger.error('Failed to load current user: $error');
      return null;
    }
  }
}
