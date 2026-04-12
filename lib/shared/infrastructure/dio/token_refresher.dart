import 'package:dio/dio.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';

class TokenRefresher {
  final TokenStorageService _tokenStorage;
  final String _baseUrl;
  static const String _tokenReissueEndPoint = '/api/v1/auth/reissue';

  TokenRefresher(this._tokenStorage, this._baseUrl);

  Future<String?> refresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl, headers: {'Content-Type': 'application/json'}));
      final response = await dio.post(_tokenReissueEndPoint, data: {'refreshToken': refreshToken});
      return await _saveTokens(response);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _saveTokens(Response response) async {
    if (response.statusCode != 200) return null;

    final data = response.data;
    if (data == null || data is! Map) return null;

    final access = data['accessToken'];
    final refresh = data['refreshToken'];

    if (access != null) await _tokenStorage.saveAccessToken(access);
    if (refresh != null) await _tokenStorage.saveRefreshToken(refresh);
    return access;
  }
}