import 'dart:convert';
import 'dart:math';

import 'package:iamhere/core/result/error_analyst.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/core/result/result_message.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/auth/model/service/login/google_auth_service.dart';
import 'package:iamhere/feature/auth/model/service/login/kakao_auth_service.dart';
import 'package:iamhere/feature/auth/model/type/login_result.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:injectable/injectable.dart';

@injectable
class SocialLoginService {
  static const _nonceLength = 32;

  SocialLoginService(
    AuthService authService,
    KakaoAuthService kakaoAuthService,
    GoogleAuthService googleAuthService, {
    AnalyticsReporter? analytics,
  }) : _authService = authService,
       _kakaoAuthService = kakaoAuthService,
       _googleAuthService = googleAuthService,
       _analytics = analytics ?? FirebaseAnalyticsReporter();

  final AuthService _authService;
  final KakaoAuthService _kakaoAuthService;
  final GoogleAuthService _googleAuthService;
  final AnalyticsReporter _analytics;

  Future<Result<MemberState>> handleKakaoLogin() => _login(
    provider: OauthProvider.kakao,
    requestIdToken: _kakaoAuthService.login,
    missingTokenMessage: ResultMessage.kakaoAccountLoginFail,
  );

  Future<Result<MemberState>> handleGoogleLogin() => _login(
    provider: OauthProvider.google,
    requestIdToken: _googleAuthService.login,
    missingTokenMessage: ResultMessage.googleAuthFailNotGoodResult,
  );

  Future<Result<MemberState>> _login({
    required OauthProvider provider,
    required Future<Result<String?>> Function({required String nonce})
    requestIdToken,
    required ResultMessage missingTokenMessage,
  }) async {
    await _analytics.logEvent(
      'login_started',
      parameters: {'provider': provider.name},
    );
    final nonce = _generateNonce();
    final result = await requestIdToken(nonce: nonce);

    return result.when(
      success: (idToken) async {
        if (idToken == null || idToken.isEmpty) {
          await _logFailure(provider);
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
        } catch (error, stackTrace) {
          ErrorAnalyst.log(error.toString(), stackTrace);
          await _logFailure(provider);
          return Failure(error.toString());
        }
      },
      failure: (message) async {
        await _logFailure(provider);
        return Failure(message);
      },
    );
  }

  Future<void> _logFailure(OauthProvider provider) => _analytics.logEvent(
    'login_failed',
    parameters: {'provider': provider.name},
  );

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(_nonceLength, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
