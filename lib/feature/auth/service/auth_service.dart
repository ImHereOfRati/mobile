import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/common/base/result/error_analyst.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/infrastructure/network/properties/http_status_code.dart';
import 'package:injectable/injectable.dart';

import 'dto/auth_response.dart';
import 'dto/oauth_request.dart';
import 'oauth_provider.dart';

@lazySingleton
class AuthService {
  static const String _loginPath = '/api/auth/login';
  static const String _registrationPath = '/api/auth/registration';
  static const String _userNotFoundResponseCode = 'AUTH-300';

  final Dio _dio;
  final TokenStorageService _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  Future<MemberState> sendIdTokenToServer(String idToken) async {
    try {
      var response = await _requestAuthenticationToServer(
        path: _loginPath,
        idToken: idToken,
      );
      var apiResponse = _convertResponseToDartObject(response);

      if (apiResponse.imhereResponseCode == _userNotFoundResponseCode) {
        response = await _requestAuthenticationToServer(
          path: _registrationPath,
          idToken: idToken,
        );
        apiResponse = _convertResponseToDartObject(response);
      }

      _handleErrorResponse(apiResponse);
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
    {
    required String path,
    required String idToken,
  }
  ) async {
    final authRequestData = OAuthRequestDto(
      provider: OauthProvider.KAKAO.name,
      idToken: idToken,
    );

    return await _dio.post(
      path,
      data: authRequestData,
      options: Options(
        extra: const {'requiresAuth': false},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  ({int code, String access, String refresh}) _parseToken(Response response) {
    final apiResponse = _convertResponseToDartObject(response);
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
      throw Exception(
        apiResponse.message.isNotEmpty
            ? apiResponse.message
            : ResultMessage.serverError,
      );
    }
  }

  ApiResponse<AuthResponseDto> _convertResponseToDartObject(
    Response<dynamic> response,
  ) {
    final raw = ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    final data = raw.data;
    final authData = data is Map<String, dynamic> && data.isNotEmpty
        ? AuthResponseDto.fromJson(data)
        : null;

    return ApiResponse<AuthResponseDto>(
      imhereResponseCode: raw.imhereResponseCode,
      message: raw.message,
      data: authData,
    );
  }
}
