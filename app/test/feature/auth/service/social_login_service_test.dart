import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/auth/model/service/login/google_auth_service.dart';
import 'package:iamhere/feature/auth/model/service/login/kakao_auth_service.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/model/type/login_result.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'social_login_service_test.mocks.dart';

final class _FakeAnalyticsReporter implements AnalyticsReporter {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> setConsent(bool granted) async {}
}

@GenerateMocks([AuthService, KakaoAuthService, GoogleAuthService])
void main() {
  provideDummy<Result<String?>>(Success('dummy'));
  provideDummy<Result<MemberState>>(Success(MemberState.existingUser));

  late SocialLoginService socialLoginService;
  late MockAuthService authService;
  late MockKakaoAuthService kakaoAuthService;
  late MockGoogleAuthService googleAuthService;

  setUp(() {
    authService = MockAuthService();
    kakaoAuthService = MockKakaoAuthService();
    googleAuthService = MockGoogleAuthService();
    socialLoginService = SocialLoginService(
      authService,
      kakaoAuthService,
      googleAuthService,
      analytics: _FakeAnalyticsReporter(),
    );
  });

  test(
    'Kakao token is authenticated with Kakao provider and the same nonce',
    () async {
      when(
        kakaoAuthService.login(nonce: anyNamed('nonce')),
      ).thenAnswer((_) async => Success('kakao-id-token'));
      when(
        authService.sendIdTokenToServer(
          'kakao-id-token',
          nonce: anyNamed('nonce'),
          provider: OauthProvider.kakao,
        ),
      ).thenAnswer((_) async => MemberState.existingUser);

      final result = await socialLoginService.handleKakaoLogin();

      expect(result, isA<Success<MemberState>>());
      final loginNonce = verify(
        kakaoAuthService.login(nonce: captureAnyNamed('nonce')),
      ).captured.single;
      final authNonce = verify(
        authService.sendIdTokenToServer(
          'kakao-id-token',
          nonce: captureAnyNamed('nonce'),
          provider: OauthProvider.kakao,
        ),
      ).captured.single;
      expect(loginNonce, authNonce);
    },
  );

  test('Google token is authenticated with Google provider', () async {
    when(
      googleAuthService.login(nonce: anyNamed('nonce')),
    ).thenAnswer((_) async => Success('google-id-token'));
    when(
      authService.sendIdTokenToServer(
        'google-id-token',
        nonce: anyNamed('nonce'),
        provider: OauthProvider.google,
      ),
    ).thenAnswer((_) async => MemberState.newUser);

    final result = await socialLoginService.handleGoogleLogin();

    expect(result, isA<Success<MemberState>>());
    verify(
      authService.sendIdTokenToServer(
        'google-id-token',
        nonce: anyNamed('nonce'),
        provider: OauthProvider.google,
      ),
    ).called(1);
  });

  test(
    'provider cancellation is returned without calling the auth service',
    () async {
      when(
        googleAuthService.login(nonce: anyNamed('nonce')),
      ).thenAnswer((_) async => Failure('cancelled'));

      final result = await socialLoginService.handleGoogleLogin();

      expect(result, isA<Failure<MemberState>>());
      verifyNever(
        authService.sendIdTokenToServer(any, nonce: anyNamed('nonce')),
      );
    },
  );
}
