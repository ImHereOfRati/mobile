import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';
import 'package:iamhere/core/dio/properties/http_status_code.dart';
import 'package:iamhere/core/dio/response/api_response.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/shared/util/app_logger.dart';
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

    final response = await _dio.post(
      tokenRefreshEndPoint,
      data: {'refreshToken': refreshToken},
    );

    return _saveTokens(response);
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

    final access = apiResponse.data![DioProperties.accessToken];
    final refresh = apiResponse.data![DioProperties.refreshToken];

    await _tokenStorage.saveAccessToken(access as String);
    await _tokenStorage.saveRefreshToken(refresh as String);
    return ApiResponse.success(data: '재로그인 성공');
  }
}
