import 'package:dio/dio.dart';
import 'package:iamhere/core/api_response/api_response_parser.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/exception/invalid_auth_state_exception.dart';
import 'package:iamhere/feature/setting/model/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/model/service/user_me_service_interface.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserMeServiceInterface)
class UserMeService implements UserMeServiceInterface {
  static const _userMePath = '/api/users/my';
  static const _withdrawalPath = '/api/users/my/withdrawal';
  static const _authenticated = {'requiresAuthentication': true};

  final Dio _dio;

  UserMeService({required Dio dio}) : _dio = dio;

  @override
  Future<UserMeResponseDto?> fetchMyInfo() async {
    try {
      final response = await _dio.get(
        _userMePath,
        options: Options(extra: _authenticated),
      );

      if (response.statusCode != 200) return null;
      return ApiResponseParser.parseObject<UserMeResponseDto>(
        response.data,
        UserMeResponseDto.fromJson,
      ).data;
    } on DioException catch (error) {
      _throwIfInvalidAuth(error);
      AppLogger.error('Failed to load current user: ${error.message}');
      return null;
    } catch (error) {
      AppLogger.error('Failed to load current user: $error');
      return null;
    }
  }

  @override
  Future<UserMeResponseDto> changeNickname(String nickname) async {
    try {
      final response = await _dio.patch(
        _userMePath,
        data: {'nickname': nickname},
        options: Options(extra: _authenticated),
      );
      final updated = ApiResponseParser.parseObject<UserMeResponseDto>(
        response.data,
        UserMeResponseDto.fromJson,
      ).data;
      if (updated == null) {
        throw const FormatException('Nickname response has no data.');
      }
      return updated;
    } on DioException catch (error) {
      _throwIfInvalidAuth(error);
      rethrow;
    }
  }

  @override
  Future<void> withdraw() async {
    try {
      await _dio.delete(
        _withdrawalPath,
        options: Options(extra: _authenticated),
      );
    } on DioException catch (error) {
      _throwIfInvalidAuth(error);
      rethrow;
    }
  }

  void _throwIfInvalidAuth(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      throw InvalidAuthStateException(statusCode!);
    }
  }
}
