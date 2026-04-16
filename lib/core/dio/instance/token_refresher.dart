import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';
import 'package:iamhere/core/dio/properties/http_status_code.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';

class TokenRefresher {
  static const debuggingMessage = '리프레시 토큰 미존재로 인한 토큰 갱신 실패';
  static const exceptionMessage = '"리프레시 토큰이 저장소에 존재하지 합시다"';

  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  TokenRefresher(this._tokenStorage, this._baseUrl);

  Future<String?> refresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    _existRefreshToken(refreshToken);

    try {
      final dio = _consistDefaultDio();
      final response = await dio.post(
        ApiConfig.authReissuePath,
        data: {DioProperties.refreshToken: refreshToken},
      );
      return await _saveTokens(response);
    } catch (_) {
      return null;
    }
  }

  Dio _consistDefaultDio() {
    final defaultDio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          DioProperties.contentTypeHeader: DioProperties.applicationJson,
        },
      ),
    );
    return defaultDio;
  }

  void _existRefreshToken(String? refreshToken) {
    if (refreshToken == null) {
      debugPrint(debuggingMessage);
      throw Exception(exceptionMessage);
    }
  }

  Future<String?> _saveTokens(Response response) async {
    if (response.statusCode != HttpStatusCode.ok) {
      return null;
    }

    final data = response.data;
    if (data == null || data is! Map) return null;

    final access = data[DioProperties.accessToken];
    final refresh = data[DioProperties.refreshToken];

    if (access != null) await _tokenStorage.saveAccessToken(access);
    if (refresh != null) await _tokenStorage.saveRefreshToken(refresh);
    return access;
  }
}
