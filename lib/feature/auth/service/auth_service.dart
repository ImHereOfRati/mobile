import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/api_config.dart';
import 'package:iamhere/feature/auth/model/login_result.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/shared/base/api_response/api_response.dart';
import 'package:iamhere/shared/base/result/error_analyst.dart';
import 'package:iamhere/shared/base/result/result_message.dart';
import 'package:injectable/injectable.dart';

import 'auth_service_interface.dart';
import 'dto/auth_response_dto.dart';
import 'dto/oauth_request_dto.dart';

@lazySingleton
class AuthService implements AuthServiceInterface {
  final Dio _dio;
  final TokenStorageService _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  @override
  Future<LoginResult> sendIdTokenToServer(String idToken) async {
    try {
      final response = await _requestAuthenticationToServer(idToken);

      final tokens = _parseToken(response);

      final (:code, :access, :refresh) = tokens;

      await _tokenStorage.saveAccessToken(access);
      await _tokenStorage.saveRefreshToken(refresh);

      return code == 201 ? LoginResult.newUser : LoginResult.existingUser;
    } on DioException catch (e, stack) {
      ErrorAnalyst.log(ResultMessage.dioException.toString(), stack);
      throw Exception(ResultMessage.dioException);
    }
  }

  Future<Response<dynamic>> _requestAuthenticationToServer(
    String idToken,
  ) async {
    return await _dio.post(
      ApiConfig.authLoginPath,
      data: OAuthRequestDto(provider: 'KAKAO', idToken: idToken),
      options: ApiConfig.publicOptions,
    );
  }

  ({int code, String access, String refresh}) _parseToken(Response response) {
    final apiResponse = APIResponse<AuthResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AuthResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.code != 200 && apiResponse.code != 201) {
      throw Exception(apiResponse.message ?? ResultMessage.serverError);
    }

    final authData = apiResponse.data;

    return (
      code: apiResponse.code,
      access: authData.accessToken,
      refresh: authData.refreshToken,
    );
  }
}
