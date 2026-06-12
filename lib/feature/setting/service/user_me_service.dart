import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/setting/service/dto/change_nickname_request_dto.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserMeServiceInterface)
class UserMeService implements UserMeServiceInterface {
  static const String _userMePath = '/api/users/my';
  static const String _userNicknamePath = '/api/users/my';

  final Dio _dio;

  UserMeService({required Dio dio}) : _dio = dio;

  @override
  Future<UserMeResponseDto?> fetchMyInfo() async {
    try {
      final response = await _dio.get(
        _userMePath,
        options: Options(extra: const {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<UserMeResponseDto>(
          response.data,
          UserMeResponseDto.fromJson,
        ).data;
      }

      return null;
    } on DioException catch (e) {
      AppLogger.error('내 정보 조회 실패: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('내 정보 조회 중 오류: $e');
      return null;
    }
  }

  @override
  Future<UserMeResponseDto?> changeNickname(String newNickname) async {
    try {
      final response = await _dio.patch(
        _userNicknamePath,
        data: ChangeNicknameRequestDto(nickname: newNickname).toJson(),
        options: Options(extra: const {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<UserMeResponseDto>(
          response.data,
          UserMeResponseDto.fromJson,
        ).data;
      }

      return null;
    } on DioException catch (e) {
      AppLogger.error('닉네임 변경 실패: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('닉네임 변경 중 오류: $e');
      return null;
    }
  }
}
