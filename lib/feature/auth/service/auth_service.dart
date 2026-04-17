import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/core/dio/properties/http_status_code.dart';
import 'package:iamhere/core/dio/util/dio_handler.dart';
import 'package:iamhere/feature/auth/model/login_result.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/shared/base/api_response/api_response.dart';
import 'package:iamhere/shared/base/result/result_message.dart';
import 'package:injectable/injectable.dart';

import 'auth_service_interface.dart';
import 'domain/oauth_provider.dart';
import 'dto/auth_response_dto.dart';
import 'dto/oauth_request_dto.dart';

@lazySingleton
class AuthService with DioHandler implements AuthServiceInterface {
  final Dio _dio;
  final TokenStorageService _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  @override
  Future<MemberState> sendIdTokenToServer(String idToken) async {
    return await safeApiCall(() async {
      final response = await _requestAuthenticationToServer(idToken);
      final (:code, :access, :refresh) = _parseToken(response);

      await _saveTokenToStorage(access, refresh);

      if (code == HttpStatusCode.created) {
        return MemberState.newUser;
      }
      return MemberState.existingUser;
    });
  }

  Future<void> _saveTokenToStorage(String access, String refresh) async {
    await _tokenStorage.saveAccessToken(access);
    await _tokenStorage.saveRefreshToken(refresh);
  }

  Future<Response<dynamic>> _requestAuthenticationToServer(
    String idToken,
  ) async {
    final authRequestData = OAuthRequestDto(
      provider: OauthProvider.KAKAO.name,
      idToken: idToken,
    );

    return await _dio.post(
      ApiConfig.authLoginPath,
      data: authRequestData,
      options: ApiConfig.publicOptions,
    );
  }

  ({int code, String access, String refresh}) _parseToken(Response response) {
    final apiResponse = _convertResponseToDartObject(response);
    int responseStatusCode = _handleErrorResponse(apiResponse);

    final authData = apiResponse.data;

    return (
      code: responseStatusCode,
      access: authData.accessToken,
      refresh: authData.refreshToken,
    );
  }

  int _handleErrorResponse(APIResponse<AuthResponseDto> apiResponse) {
    final responseStatusCode = apiResponse.code;

    if (!HttpStatusCode.is2XXStatusCode(responseStatusCode)) {
      throw Exception(apiResponse.message ?? ResultMessage.serverError);
    }
    return responseStatusCode;
  }

  APIResponse<AuthResponseDto> _convertResponseToDartObject(
    Response<dynamic> response,
  ) {
    return APIResponse<AuthResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AuthResponseDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
