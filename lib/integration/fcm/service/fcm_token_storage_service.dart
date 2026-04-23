import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:injectable/injectable.dart';

/// FCM 토큰을 로컬에 안전하게 저장하는 서비스
@lazySingleton
class FcmTokenStorageService {
  static const String _fcmTokenKey = 'fcm_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// FCM 토큰을 로컬에 저장합니다.
  Future<void> saveFcmToken(String fcmToken) async {
    try {
      await _storage.write(key: _fcmTokenKey, value: fcmToken);
      AppLogger.debug('FCM token saved to local storage: $fcmToken');
    } catch (e) {
      AppLogger.error('Error saving FCM token to local storage: $e');
      rethrow;
    }
  }

  /// 로컬에 저장된 FCM 토큰을 가져옵니다.
  Future<String?> getFcmToken() async {
    try {
      final token = await _storage.read(key: _fcmTokenKey);
      if (token != null) {
        AppLogger.debug('FCM token retrieved from local storage');
      } else {
        AppLogger.debug('No FCM token found in local storage');
      }
      return token;
    } catch (e) {
      AppLogger.error('Error retrieving FCM token from local storage: $e');
      return null;
    }
  }

  /// 로컬에 저장된 FCM 토큰을 삭제합니다.
  Future<void> deleteFcmToken() async {
    try {
      await _storage.delete(key: _fcmTokenKey);
      AppLogger.debug('FCM token deleted from local storage');
    } catch (e) {
      AppLogger.error('Error deleting FCM token from local storage: $e');
      rethrow;
    }
  }

  /// 로컬과 Firebase의 토큰이 일치하는지 확인합니다.
  Future<bool> isTokenValid(String? currentToken) async {
    if (currentToken == null) return false;

    final storedToken = await getFcmToken();
    final isValid = storedToken == currentToken;

    if (!isValid) {
      AppLogger.debug(
        'Token mismatch - Local: $storedToken, Current: $currentToken',
      );
    }

    return isValid;
  }
}
