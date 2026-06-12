import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/common/base/result/error_analyst.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/feature/auth/service/auth_exception.dart';
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
      _validateIdToken(idToken);

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
      final (:code, :access, :refresh, :status) = _parseToken(response);

      await _saveTokenToStorage(access, refresh);

      if (status == 'PENDING') {
        return MemberState.pending;
      }
      if (code == HttpStatusCode.created) {
        return MemberState.newUser;
      }
      return MemberState.existingUser;
    } catch (error, stack) {
      ErrorAnalyst.log(error.toString(), stack);
      rethrow;
    }
  }

  void _validateIdToken(String idToken) {
    if (idToken.isEmpty || idToken.trim().isEmpty) {
      throw InvalidTokenException();
    }
  }

  Future<void> _saveTokenToStorage(String access, String refresh) async {
    try {
      await _tokenStorage.saveAccessToken(access);
      await _tokenStorage.saveRefreshToken(refresh);
    } catch (e, st) {
      throw TokenStorageException(e.toString(), stackTrace: st);
    }
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

    try {
      return await _dio.post(
        path,
        data: authRequestData,
        options: Options(
          extra: const {'requiresAuthentication': false},
          validateStatus: (status) => status != null && (status >= 200 && status < 300 || status == 404),
        ),
      );
    } on DioException catch (e, st) {
      throw NetworkException(e.message ?? 'Unknown error', stackTrace: st);
    }
  }

  ({int code, String access, String refresh, String? status}) _parseToken(Response response) {
    final apiResponse = _convertResponseToDartObject(response);
    final responseStatusCode = response.statusCode;

    if (responseStatusCode == null || (responseStatusCode < 200 || responseStatusCode >= 300) && responseStatusCode != 404) {
      throw InvalidResponseException('Invalid status code: $responseStatusCode');
    }

    final authData = apiResponse.data;
    if (authData == null) {
      throw TokenParseException();
    }

    final accessToken = authData.accessToken;
    final refreshToken = authData.refreshToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw TokenParseException();
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw TokenParseException();
    }

    return (
      code: responseStatusCode,
      access: accessToken,
      refresh: refreshToken,
      status: authData.status,
    );
  }

  void _handleErrorResponse(ApiResponse<AuthResponseDto> apiResponse) {
    final responseCode = apiResponse.imhereResponseCode;

    if (responseCode != 'SUCCESS' && responseCode != 'AUTH-300') {
      final msg = apiResponse.message?.toString() ?? '';
      throw ServerAuthException(
        responseCode,
        msg.isNotEmpty ? msg : ResultMessage.serverError.toString(),
      );
    }
  }

  ApiResponse<AuthResponseDto> _convertResponseToDartObject(
    Response<dynamic> response,
  ) {
    try {
      if (response.data is! Map<String, dynamic>) {
        throw InvalidResponseException('Response data is not a map');
      }

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
        message: raw.message.toString(),
        data: authData,
      );
    } catch (e, st) {
      if (e is AuthException) rethrow;
      throw InvalidResponseException(e.toString(), stackTrace: st);
    }
  }
}
