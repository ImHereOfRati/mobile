import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:iamhere/core/result/error_analyst.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/core/result/result_message.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/service/google_auth_service.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:injectable/injectable.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

@injectable
class AuthLoginCoordinator {
  static const _nonceLength = 32;

  final AuthService _authService;
  final FcmTokenService _fcmTokenService;
  final GoogleAuthService _googleAuthService;
  final TokenStorageService _tokenStorage;
  final AnalyticsReporter _analytics;

  AuthLoginCoordinator(
    this._authService,
    this._fcmTokenService,
    this._googleAuthService,
    this._tokenStorage, {
    AnalyticsReporter? analytics,
  }) : _analytics = analytics ?? FirebaseAnalyticsReporter();

  Future<Result<MemberState>> handleKakaoLogin() => _login(
    provider: OauthProvider.kakao,
    requestIdToken: _doUserKakaoLogin,
    missingTokenMessage: ResultMessage.kakaoAccountLoginFail,
  );

  Future<Result<MemberState>> handleGoogleLogin() => _login(
    provider: OauthProvider.google,
    requestIdToken: (nonce) => _googleAuthService.login(nonce: nonce),
    missingTokenMessage: ResultMessage.googleAuthFailNotGoodResult,
  );

  /// 제공자별 ID 토큰 발급 절차만 다르고, 이후 서버 교환 과정은 동일하다.
  Future<Result<MemberState>> _login({
    required OauthProvider provider,
    required Future<Result<String?>> Function(String nonce) requestIdToken,
    required ResultMessage missingTokenMessage,
  }) async {
    await _analytics.logEvent(
      'login_started',
      parameters: {'provider': provider.name},
    );
    final nonce = _generateNonce();
    final result = await requestIdToken(nonce);

    return result.when(
      success: (idToken) async {
        if (idToken == null || idToken.isEmpty) {
          await _analytics.logEvent(
            'login_failed',
            parameters: {'provider': provider.name},
          );
          return Failure(missingTokenMessage.toString());
        }
        try {
          final state = await _authService.sendIdTokenToServer(
            idToken,
            nonce: nonce,
            provider: provider,
          );
          await _analytics.logEvent(
            'login_completed',
            parameters: {'provider': provider.name},
          );
          return Success(state);
        } catch (e, st) {
          ErrorAnalyst.log(e.toString(), st);
          await _analytics.logEvent(
            'login_failed',
            parameters: {'provider': provider.name},
          );
          return Failure(e.toString());
        }
      },
      failure: (msg) async {
        await _analytics.logEvent(
          'login_failed',
          parameters: {'provider': provider.name},
        );
        return Failure(msg);
      },
    );
  }

  Future<void> activateWithTerms(List<Map<String, Object?>> consents) async {
    await _authService.activateWithTerms(consents);
    await syncFcmForActiveSession();
  }

  /// 저장된 활성 세션만 등록하며, 알림 실패가 인증이나 앱 시작을 막지 않는다.
  Future<void> syncFcmForActiveSession() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      if (await _tokenStorage.getPendingAuth()) return;
      final status = (await _tokenStorage.getUserStatus())?.toUpperCase();
      final isActive = await _tokenStorage.getIsActive();
      if (status == 'PENDING' || status == 'INACTIVE' || isActive == false) {
        return;
      }
      if (status != 'ACTIVE' && isActive != true) return;
      await requestFCMTokenAndSendToServer();
    } catch (error, stack) {
      ErrorAnalyst.log(error.toString(), stack);
    }
  }

  Future<Result<ResultMessage>> requestFCMTokenAndSendToServer() async {
    final fcmToken = await _fcmTokenService.syncTokenAndEnroll();
    if (fcmToken == null) {
      return Failure(ResultMessage.fcmTokenGenerateFail.toString());
    }
    return Success(ResultMessage.fcmTokenGenerateSuccess);
  }

  Future<Result<String?>> _doUserKakaoLogin(String nonce) async {
    if (await isKakaoTalkInstalled()) {
      return _loginWithKakaoTalkApplication(nonce);
    }
    return _loginWithKakaoAccountOnWebPopUp(nonce);
  }

  Future<Result<String?>> _loginWithKakaoTalkApplication(String nonce) async {
    try {
      final token = await UserApi.instance.loginWithKakaoTalk(nonce: nonce);
      return Success(token.idToken);
    } catch (error, trace) {
      if (error is PlatformException && error.code == 'CANCELED') {
        return Failure(
          ResultMessage.kakaoLoginCanceled.toString(),
          trace: trace,
        );
      }

      return Failure(ResultMessage.kakaoTalkLoginFail.toString(), trace: trace);
    }
  }

  Future<Result<String?>> _loginWithKakaoAccountOnWebPopUp(String nonce) async {
    try {
      final token = await UserApi.instance.loginWithKakaoAccount(nonce: nonce);
      return Success(token.idToken);
    } catch (error, trace) {
      return Failure(
        ResultMessage.kakaoAccountLoginFail.toString(),
        trace: trace,
      );
    }
  }

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(_nonceLength, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
