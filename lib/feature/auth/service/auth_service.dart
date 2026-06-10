import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/infrastructure/network/properties/api_config.dart';
import 'package:iamhere/infrastructure/network/properties/http_status_code.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/common/base/result/error_analyst.dart';
import 'package:injectable/injectable.dart';

import 'auth_service_interface.dart';
import 'domain/oauth_provider.dart';
import 'dto/auth_response.dart';
import 'dto/oauth_request.dart';

@lazySingleton
class AuthService implements AuthServiceInterface {
  final Dio _dio;
  final TokenStorageService _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  @override
  Future<MemberState> sendIdTokenToServer(String idToken) async {
    try {
      final response = await _requestAuthenticationToServer(idToken);
      final (:code, :access, :refresh) = _parseToken(response);

      await _saveTokenToStorage(access, refresh);

      if (code == HttpStatusCode.created) {
        return MemberState.newUser;
      }
      return MemberState.existingUser;
    } catch (error, stack) {
      ErrorAnalyst.log(error.toString(), stack);
      rethrow;
    }
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
    _handleErrorResponse(apiResponse);
    final responseStatusCode = response.statusCode ?? HttpStatusCode.ok;

    final authData = apiResponse.data;
    if (authData == null) {
      throw Exception(ResultMessage.serverError);
    }

    return (
      code: responseStatusCode,
      access: authData.accessToken,
      refresh: authData.refreshToken,
    );
  }

  void _handleErrorResponse(ApiResponse<AuthResponseDto> apiResponse) {
    final responseCode = apiResponse.imhereResponseCode;

    if (responseCode != 'SUCCESS') {
      throw Exception(apiResponse.message ?? ResultMessage.serverError);
    }
  }

  ApiResponse<AuthResponseDto> _convertResponseToDartObject(
    Response<dynamic> response,
  ) {
    return ApiResponse<AuthResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AuthResponseDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
