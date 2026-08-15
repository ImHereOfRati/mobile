import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iamhere/integration/fcm/repository/fcm_token_repository.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';

import 'fcm_token_storage_service.dart';

/// FCM 토큰을 가져오고 관리하는 서비스
@lazySingleton
class FcmTokenService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FcmTokenStorageService _storageService;
  final FcmTokenRepository _repository;
  StreamSubscription<String>? _tokenRefreshSubscription;

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
      await _storageService.deleteFcmToken();
      AppLogger.debug('FCM Token deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting FCM token: $e');
    }
  }

  /// 현재 FCM 토큰을 저장하고 인증된 사용자 계정에 등록합니다.
  ///
  /// 토큰 생성 실패 시 null을 반환하며, 서버 등록 실패는 로그로 남기고
  /// 토큰 자체는 반환합니다. 다음 로그인 또는 토큰 갱신 때 재시도합니다.
  Future<String?> syncTokenAndEnroll() async {
    try {
      final token = await getToken();

      if (token == null) {
        AppLogger.error('Failed to generate FCM token');
        return null;
      }

      final enrolled = await _repository.enrollFcmToken(token);
      if (!enrolled) {
        AppLogger.error('Failed to enroll FCM token to server');
        return null;
      }

      await _storageService.saveFcmToken(token);

      return token;
    } catch (e) {
      AppLogger.error('Error syncing FCM token: $e');
      return null;
    }
  }

  /// Firebase 토큰이 교체되면 현재 로그인 계정에 새 토큰을 등록한다.
  /// 앱 생명주기 동안 한 번만 구독해야 한다.
  void startTokenRefreshListener() {
    _tokenRefreshSubscription ??= onTokenRefresh.listen((token) async {
      try {
        final enrolled = await _repository.enrollFcmToken(token);
        if (!enrolled) {
          AppLogger.error('Failed to enroll refreshed FCM token to server');
          return;
        }
        await _storageService.saveFcmToken(token);
        AppLogger.debug('Refreshed FCM token enrolled successfully');
      } catch (e) {
        AppLogger.error('Error enrolling refreshed FCM token: $e');
      }
    });
  }
}
