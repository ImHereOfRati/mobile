import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/infrastructure/network/properties/http_status_code.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TokenRefresher {
  static const tokenRefreshEndPoint = '/api/auth/refresh';

  static const notFoundTokenErrorMessage =
      '리프레시 토큰이 저장소에 존재하지 않아 로그인 갱신에 실패했습니다';

  final Dio _dio;
  final TokenStorageService _tokenStorage;

  TokenRefresher(this._tokenStorage, @Named('retryDio') this._dio);

  Future<ApiResponse<String>> refresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      AppLogger.debug(notFoundTokenErrorMessage);
      throw Exception(notFoundTokenErrorMessage);
    }

    try {
      final response = await _dio.post(
        tokenRefreshEndPoint,
        data: {'refreshToken': refreshToken},
      );

      return _saveTokens(response);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null || response.data is! Map<String, dynamic>) {
        rethrow;
      }

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      return ApiResponse.fail(
        imhereErrorCode: apiResponse.imhereResponseCode,
        errorMessage: apiResponse.message,
      );
    }
  }

  Future<ApiResponse<String>> _saveTokens(Response response) async {
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (response.statusCode != HttpStatusCode.ok) {
      return ApiResponse.fail(
        imhereErrorCode: apiResponse.imhereResponseCode,
        errorMessage: apiResponse.message,
      );
    }

    final access = apiResponse.data!['accessToken'];
    final refresh = apiResponse.data!['refreshToken'];

    await _tokenStorage.saveAccessToken(access as String);
    await _tokenStorage.saveRefreshToken(refresh as String);
    return ApiResponse.success(data: access);
  }
}
