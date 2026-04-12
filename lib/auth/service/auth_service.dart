import 'package:dio/dio.dart';
import 'package:iamhere/auth/service/auth_service_interface.dart';
import 'package:iamhere/auth/service/dto/oauth_request_dto.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';
import 'package:iamhere/shared/base/result/error_analyst.dart';
import 'package:iamhere/shared/base/result/result_message.dart';
import 'package:iamhere/shared/infrastructure/dio/api_config.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthService implements AuthServiceInterface {
  final Dio _dio;
  final TokenStorageService _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  @override
  Future<bool> sendIdTokenToServer(String idToken) async {
    try {
      final response = await _dio.post(
        ApiConfig.authLoginPath,
        data: OAuthRequestDto(provider: 'KAKAO', idToken: idToken),
        options: ApiConfig.publicOptions,
      );

      // 200, 201 응답만 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;

        if (accessToken != null) {
          await _tokenStorage.saveAccessToken(accessToken);
        }

        if (refreshToken != null) {
          await _tokenStorage.saveRefreshToken(refreshToken);
        }

        // 상태 반환: 201이면 신규 사용자(true), 200이면 기존 사용자(false)
        return response.statusCode == 201;
      }

      // 기타 상태 코드는 false 반환 (기존 사용자로 간주)
      return false;
    } on DioException catch (e, stack) {
      ErrorAnalyst.log(ResultMessage.dioException.toString(), stack);
      throw Exception(ResultMessage.dioException);
    }
  }
}
