import 'package:dio/dio.dart';
import 'package:iamhere/core/api_response/api_response.dart';
import 'package:iamhere/core/network/properties/http_status_code.dart';
import 'package:iamhere/core/result/result_message.dart';
import 'package:iamhere/feature/auth/model/dto/auth_response.dart';
import 'package:iamhere/feature/auth/model/dto/auth_api_response_dto.dart';
import 'package:iamhere/feature/auth/model/dto/oauth_request.dart';
import 'package:iamhere/feature/auth/model/exception/auth_exception.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthRepository {
  static const _authPath = '/api/auth';
  static const _agreementPath = '/api/agreements';
  static const _refreshPath = '/api/auth/refresh';
  static const _authReceiveTimeout = Duration(seconds: 20);

  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthApiResponseDto> authenticate({
    required String idToken,
    required String nonce,
    required OauthProvider provider,
  }) async {
    final request = OAuthRequestDto(
      provider: provider.name.toUpperCase(),
      idToken: idToken,
      nonce: nonce,
    );
    try {
      final response = await _dio.post(
        _authPath,
        data: request.toJson(),
        options: Options(
          receiveTimeout: _authReceiveTimeout,
          extra: const {'requiresAuthentication': false},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return _parseAuthResponse(response);
    } on DioException catch (error, stackTrace) {
      throw NetworkException(
        error.message ?? 'Unknown error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> acceptTerms(List<Map<String, Object?>> consents) async {
    final response = await _dio.post<void>(
      _agreementPath,
      data: {'consents': consents},
      options: Options(extra: const {'requiresAuthentication': true}),
    );
    if (response.statusCode != HttpStatusCode.noContent) {
      throw InvalidResponseException(
        'Invalid agreement status code: ${response.statusCode}',
      );
    }
  }

  Future<AuthApiResponseDto> refresh(String refreshToken) async {
    final response = await _dio.post(
      _refreshPath,
      data: {'refreshToken': refreshToken},
      options: Options(extra: const {'requiresAuthentication': false}),
    );
    return _parseAuthResponse(response);
  }

  AuthApiResponseDto _parseAuthResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw InvalidResponseException('Invalid status code: $statusCode');
    }

    final apiResponse = _parseApiResponse(response);
    if (apiResponse.imhereResponseCode != 'SUCCESS') {
      final message = apiResponse.message.toString();
      throw ServerAuthException(
        apiResponse.imhereResponseCode,
        message.isNotEmpty ? message : ResultMessage.serverError.toString(),
      );
    }

    final authData = apiResponse.data;
    if (authData == null ||
        authData.accessToken.isEmpty ||
        authData.refreshToken.isEmpty) {
      throw TokenParseException();
    }
    return AuthApiResponseDto(statusCode: statusCode, data: authData);
  }

  ApiResponse<AuthResponseDto> _parseApiResponse(Response<dynamic> response) {
    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw InvalidResponseException('Response data is not a map');
      }
      final raw = ApiResponse<Object?>.fromJson(data, (json) => json);
      final responseData = raw.data;
      final authData =
          responseData is Map<String, dynamic> && responseData.isNotEmpty
          ? AuthResponseDto.fromJson(responseData)
          : null;
      return ApiResponse<AuthResponseDto>(
        imhereResponseCode: raw.imhereResponseCode,
        message: raw.message.toString(),
        data: authData,
      );
    } catch (error, stackTrace) {
      if (error is AuthException) rethrow;
      throw InvalidResponseException(error.toString(), stackTrace: stackTrace);
    }
  }
}
