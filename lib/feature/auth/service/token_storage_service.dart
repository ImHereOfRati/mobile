import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TokenStorageService {
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _pendingAuthKey = 'pending_auth';
  static const String _userStatusKey = 'auth_user_status';
  static const String _isActiveKey = 'auth_is_active';

  TokenStorageService(this._storage);

  /// Access Token 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Refresh Token 저장
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Access Token 조회
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Refresh Token 조회
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> savePendingAuth(bool isPending) async {
    await _storage.write(key: _pendingAuthKey, value: isPending.toString());
  }

  Future<bool> getPendingAuth() async {
    final value = await _storage.read(key: _pendingAuthKey);
    return value == 'true';
  }

  Future<void> saveUserStatus(String? userStatus) async {
    if (userStatus == null || userStatus.isEmpty) {
      await _storage.delete(key: _userStatusKey);
      return;
    }
    await _storage.write(key: _userStatusKey, value: userStatus);
  }

  Future<String?> getUserStatus() async {
    return await _storage.read(key: _userStatusKey);
  }

  Future<void> saveIsActive(bool? isActive) async {
    if (isActive == null) {
      await _storage.delete(key: _isActiveKey);
      return;
    }
    await _storage.write(key: _isActiveKey, value: isActive.toString());
  }

  Future<bool?> getIsActive() async {
    final value = await _storage.read(key: _isActiveKey);
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> saveAuthSnapshot({String? userStatus, bool? isActive}) async {
    await savePendingAuth(userStatus == 'PENDING');
    await saveUserStatus(userStatus);
    await saveIsActive(isActive);
  }

  /// 모든 토큰 삭제
  Future<void> deleteAllTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _pendingAuthKey);
    await _storage.delete(key: _userStatusKey);
    await _storage.delete(key: _isActiveKey);
  }

  /// Access Token 삭제
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  /// Refresh Token 삭제
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
}
