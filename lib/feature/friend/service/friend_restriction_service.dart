import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/friend_restriction_response_dto.dart';
import 'package:iamhere/feature/friend/service/friend_restriction_service_interface.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: FriendRestrictionServiceInterface)
class FriendRestrictionService implements FriendRestrictionServiceInterface {
  static const String _friendRestrictionPath = '/api/friends/restrictions';
  static String _friendRestrictionDeletePath(String id) =>
      '/api/friends/restrictions/$id';

  final Dio _dio;

  FriendRestrictionService({required Dio dio}) : _dio = dio;

  @override
  Future<List<FriendRestrictionResponseDto>> fetchRestrictions() async {
    try {
      final response = await _dio.get(
        _friendRestrictionPath,
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseSlice<FriendRestrictionResponseDto>(
              response.data,
              FriendRestrictionResponseDto.fromJson,
            ).data?.content ??
            const [];
      }
      return [];
    } on DioException catch (e) {
      AppLogger.error('제한 목록 조회 실패: ${e.message}');
      return [];
    }
  }

  @override
  Future<bool> deleteRestriction(String friendRestrictionId) async {
    try {
      final response = await _dio.delete(
        _friendRestrictionDeletePath(friendRestrictionId),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        ApiResponseParser.parseVoid(response.data);
        return true;
      }

      return false;
    } on DioException catch (e) {
      AppLogger.error('제한 해제 실패: ${e.message}');
      return false;
    }
  }
}
