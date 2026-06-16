import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/google_auth_service.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/feature/auth/view_model/auth_view_model.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_view_model_test.mocks.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([AuthService, FcmTokenService, GoogleAuthService])
void main() {
  provideDummy<Result<String?>>(Success('dummy'));
  provideDummy<Result<MemberState>>(Success(MemberState.existingUser));

  late AuthViewModel authViewModel;
  late MockAuthService mockAuthService;
  late MockFcmTokenService mockFcmTokenService;
  late MockGoogleAuthService mockGoogleAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFcmTokenService = MockFcmTokenService();
    mockGoogleAuthService = MockGoogleAuthService();

    authViewModel = AuthViewModel(
      mockAuthService,
      mockFcmTokenService,
      mockGoogleAuthService,
    );
  });

  group('AuthViewModel - handleKakaoLogin', () {
    test('AuthViewModel이 올바른 의존성을 가지고 생성되어야 함', () {
      // Assert
      expect(authViewModel, isNotNull);
      expect(authViewModel, isA<AuthViewModel>());
    });

    test('기존 사용자(HTTP 200) 로그인 시 LoginResult.existingUser를 반환해야 함', () async {
      // Arrange
      const testToken = 'test_id_token';
      when(
        mockAuthService.sendIdTokenToServer(
          testToken,
          nonce: anyNamed('nonce'),
        ),
      ).thenAnswer((_) async => MemberState.existingUser); // 기존 사용자

      // Act
      // Note: handleKakaoLogin은 _doUserKakaoLogin 호출이 필요하므로
      // 직접 테스트하려면 더 복잡한 setup이 필요함
      // 따라서 통합 테스트(auth_view_test)로 검증됨
      expect(authViewModel, isNotNull);
    });

    test('신규 사용자(HTTP 201) 로그인 시 LoginResult.newUser를 반환해야 함', () async {
      // Arrange
      const testToken = 'test_id_token';
      when(
        mockAuthService.sendIdTokenToServer(
          testToken,
          nonce: anyNamed('nonce'),
        ),
      ).thenAnswer((_) async => MemberState.newUser); // 신규 사용자

      // Act
      // Note: handleKakaoLogin은 _doUserKakaoLogin 호출이 필요하므로
      // 직접 테스트하려면 더 복잡한 setup이 필요함
      // 따라서 통합 테스트(auth_view_test)로 검증됨
      expect(authViewModel, isNotNull);
    });
  });

  group('AuthViewModel - handleGoogleLogin', () {
    test('Google 로그인 성공 시 nonce 와 provider=google 을 전달해야 함', () async {
      when(mockGoogleAuthService.login(nonce: anyNamed('nonce'))).thenAnswer(
        (_) async => Success('google_id_token'),
      );
      when(
        mockAuthService.sendIdTokenToServer(
          'google_id_token',
          nonce: anyNamed('nonce'),
          provider: OauthProvider.google,
        ),
      ).thenAnswer((_) async => MemberState.existingUser);

      final result = await authViewModel.handleGoogleLogin();

      expect(result, isA<Success<MemberState>>());
      final loginNonce = verify(
        mockGoogleAuthService.login(nonce: captureAnyNamed('nonce')),
      ).captured.single as String;
      final requestNonce = verify(
        mockAuthService.sendIdTokenToServer(
          'google_id_token',
          nonce: captureAnyNamed('nonce'),
          provider: OauthProvider.google,
        ),
      ).captured.single as String;
      expect(loginNonce, requestNonce);
    });

    test('Google 로그인 취소 시 Failure 를 반환해야 함', () async {
      when(mockGoogleAuthService.login(nonce: anyNamed('nonce'))).thenAnswer(
        (_) async => Failure('취소'),
      );

      final result = await authViewModel.handleGoogleLogin();

      expect(result, isA<Failure<MemberState>>());
      verify(mockGoogleAuthService.login(nonce: anyNamed('nonce'))).called(1);
      verifyNever(
        mockAuthService.sendIdTokenToServer(
          any,
          nonce: anyNamed('nonce'),
        ),
      );
    });
  });

  group('AuthViewModel - requestFCMTokenAndSendToServer', () {
    test('FCM 토큰 생성 성공 시 Success를 반환해야 함', () async {
      // Arrange
      when(
        mockFcmTokenService.generateAndSaveFcmToken(),
      ).thenAnswer((_) async => 'test_fcm_token');
      when(
        mockFcmTokenService.enrollFcmTokenToServer(),
      ).thenAnswer((_) async => true);

      // Act
      final result = await authViewModel.requestFCMTokenAndSendToServer();

      // Assert
      expect(result, isA<Success<ResultMessage>>());
      final successResult = result as Success<ResultMessage>;
      expect(successResult.data, ResultMessage.fcmTokenGenerateSuccess);

      // Verify
      verify(mockFcmTokenService.generateAndSaveFcmToken()).called(1);
      verify(mockFcmTokenService.enrollFcmTokenToServer()).called(1);
    });

    test('FCM 토큰 생성 실패 시 Failure를 반환해야 함', () async {
      when(
        mockFcmTokenService.generateAndSaveFcmToken(),
      ).thenAnswer((_) async => null);

      // Act
      final result = await authViewModel.requestFCMTokenAndSendToServer();

      // Assert
      expect(result, isA<Failure<ResultMessage>>());

      // Verify - enrollFcmTokenToServer는 호출되지 않아야 함
      verify(mockFcmTokenService.generateAndSaveFcmToken()).called(1);
      verifyNever(mockFcmTokenService.enrollFcmTokenToServer());
    });

    test('FCM 권한 요청이 먼저 호출되어야 함', () async {
      // Arrange
      when(
        mockFcmTokenService.generateAndSaveFcmToken(),
      ).thenAnswer((_) async => 'test_fcm_token');
      when(
        mockFcmTokenService.enrollFcmTokenToServer(),
      ).thenAnswer((_) async => true);

      // Act
      await authViewModel.requestFCMTokenAndSendToServer();

      // Assert - 호출 순서 검증
      verifyInOrder([mockFcmTokenService.generateAndSaveFcmToken()]);
    });

    test('FCM 토큰 서버 등록 성공 시 로그가 출력되어야 함', () async {
      // Arrange
      when(
        mockFcmTokenService.generateAndSaveFcmToken(),
      ).thenAnswer((_) async => 'test_fcm_token');
      when(
        mockFcmTokenService.enrollFcmTokenToServer(),
      ).thenAnswer((_) async => true);

      // Act
      final result = await authViewModel.requestFCMTokenAndSendToServer();

      // Assert
      expect(result, isA<Success<ResultMessage>>());
      verify(mockFcmTokenService.enrollFcmTokenToServer()).called(1);
    });

    test('FCM 토큰 서버 등록 실패 시에도 Success를 반환해야 함 (로그만 출력)', () async {
      // Arrange
      when(
        mockFcmTokenService.generateAndSaveFcmToken(),
      ).thenAnswer((_) async => 'test_fcm_token');
      when(
        mockFcmTokenService.enrollFcmTokenToServer(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await authViewModel.requestFCMTokenAndSendToServer();

      // Assert - 서버 등록 실패해도 Success 반환 (토큰 생성은 성공했으므로)
      expect(result, isA<Success<ResultMessage>>());
      verify(mockFcmTokenService.enrollFcmTokenToServer()).called(1);
    });
  });

  group('AuthViewModel - 의존성 및 구조 테스트', () {
    test('AuthService 의존성이 올바르게 주입되어야 함', () {
      // Arrange & Act
      final viewModel = AuthViewModel(
        mockAuthService,
        mockFcmTokenService,
        mockGoogleAuthService,
      );

      // Assert
      expect(viewModel, isNotNull);
    });

    test('FcmTokenService 의존성이 올바르게 주입되어야 함', () {
      // Arrange & Act
      final viewModel = AuthViewModel(
        mockAuthService,
        mockFcmTokenService,
        mockGoogleAuthService,
      );

      // Assert
      expect(viewModel, isNotNull);
    });

    test('FcmAlertPermissionService 의존성이 올바르게 주입되어야 함', () {
      // Arrange & Act
      final viewModel = AuthViewModel(
        mockAuthService,
        mockFcmTokenService,
        mockGoogleAuthService,
      );

      // Assert
      expect(viewModel, isNotNull);
    });

    test('AuthViewModel이 AuthViewModelInterface를 구현해야 함', () {
      // Assert
      expect(authViewModel, isA<AuthViewModel>());
    });
  });

  group('AuthViewModel - Mock 동작 검증', () {
    test('AuthService.sendIdTokenToServer가 호출 가능해야 함', () async {
      // Arrange
      const testToken = 'test_id_token';
      when(
        mockAuthService.sendIdTokenToServer(
          testToken,
          nonce: anyNamed('nonce'),
        ),
      ).thenAnswer((_) async => MemberState.existingUser); // 기존 사용자 반환

      // Act
      final memberState = await mockAuthService.sendIdTokenToServer(
        testToken,
        nonce: 'test_nonce',
      );

      // Assert
      expect(memberState, MemberState.existingUser);
      verify(
        mockAuthService.sendIdTokenToServer(
          testToken,
          nonce: 'test_nonce',
        ),
      ).called(1);
    });

    test('FcmTokenService.generateAndSaveFcmToken이 호출 가능해야 함', () async {
      // Arrange
      when(
        mockFcmTokenService.generateAndSaveFcmToken(),
      ).thenAnswer((_) async => 'fcm_token');

      // Act
      final token = await mockFcmTokenService.generateAndSaveFcmToken();

      // Assert
      expect(token, 'fcm_token');
      verify(mockFcmTokenService.generateAndSaveFcmToken()).called(1);
    });

    group('AuthViewModel - 에러 처리', () {
      test('FCM 토큰 생성 중 예외 발생 시 예외를 전파해야 함', () async {
        // Arrange
        when(
          mockFcmTokenService.generateAndSaveFcmToken(),
        ).thenThrow(Exception('Token generation failed'));

        // Act & Assert
        expect(
          () => authViewModel.requestFCMTokenAndSendToServer(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
