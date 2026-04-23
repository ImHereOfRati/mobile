import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iamhere/integration/fcm/repository/fcm_token_repository.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:injectable/injectable.dart';

import 'fcm_token_storage_service.dart';

/// FCM 토큰을 가져오고 관리하는 서비스
@lazySingleton
class FcmTokenService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FcmTokenStorageService _storageService;
  final FcmTokenRepository _repository;

  FcmTokenService(this._storageService, this._repository);

  /// FCM 토큰을 가져옵니다.
  /// 토큰이 없거나 만료된 경우 새로 생성됩니다.
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        AppLogger.debug('FCM Token received: $token');
      } else {
        AppLogger.error('Failed to get FCM token');
      }
      return token;
    } catch (e) {
      AppLogger.error('Error getting FCM token: $e');
      return null;
    }
  }

  /// FCM 토큰 갱신을 감지합니다.
  /// 토큰이 갱신될 때마다 호출되는 콜백을 설정합니다.
  Stream<String> get onTokenRefresh {
    return _firebaseMessaging.onTokenRefresh;
  }

  /// 현재 저장된 FCM 토큰을 삭제합니다.
  /// 로그아웃 시 호출하면 유용합니다.
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      AppLogger.debug('FCM Token deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting FCM token: $e');
    }
  }

  /// FCM 토큰을 생성하고 로컬 저장소에 저장합니다.
  ///
  /// Returns: 성공 시 FCM 토큰, 실패 시 null
  Future<String?> generateAndSaveFcmToken() async {
    try {
      // Firebase로부터 FCM 토큰 발급
      final token = await getToken();

      if (token == null) {
        AppLogger.error('Failed to generate FCM token');
        return null;
      }

      // 로컬 저장소에 FCM 토큰 저장
      await _storageService.saveFcmToken(token);
      AppLogger.debug('FCM token generated and saved successfully');

      return token;
    } catch (e) {
      AppLogger.error('Error in generateAndSaveFcmToken: $e');
      return null;
    }
  }

  /// 로컬에 저장된 FCM 토큰을 서버에 등록합니다.
  ///
  /// Returns: 성공 시 true, 실패 시 false
  Future<bool> enrollFcmTokenToServer() async {
    try {
      // 로컬에서 FCM 토큰 가져오기
      final token = await _storageService.getFcmToken();

      if (token == null) {
        AppLogger.debug('No FCM token found in local storage');
        return false;
      }

      // 서버에 FCM 토큰 등록
      final success = await _repository.enrollFcmToken(token);

      if (success) {
        AppLogger.debug('FCM token enrolled to server successfully');
      } else {
        AppLogger.error('Failed to message FCM token to server');
      }

      return success;
    } catch (e) {
      AppLogger.error('Error in enrollFcmTokenToServer: $e');
      return false;
    }
  }
}
