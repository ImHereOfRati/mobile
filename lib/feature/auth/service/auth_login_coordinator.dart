import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:iamhere/common/base/result/error_analyst.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/service/google_auth_service.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:injectable/injectable.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

@injectable
class AuthLoginCoordinator {
  static const _nonceLength = 32;

  final AuthService _authService;
  final FcmTokenService _fcmTokenService;
  final GoogleAuthService _googleAuthService;

  AuthLoginCoordinator(
    this._authService,
    this._fcmTokenService,
    this._googleAuthService,
  );

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
    final nonce = _generateNonce();
    final result = await requestIdToken(nonce);

    return result.when(
      success: (idToken) async {
        if (idToken == null || idToken.isEmpty) {
          return Failure(missingTokenMessage.toString());
        }
        try {
          final state = await _authService.sendIdTokenToServer(
            idToken,
            nonce: nonce,
            provider: provider,
          );
          return Success(state);
        } catch (e, st) {
          ErrorAnalyst.log(e.toString(), st);
          return Failure(e.toString());
        }
      },
      failure: (msg) async => Failure(msg),
    );
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
