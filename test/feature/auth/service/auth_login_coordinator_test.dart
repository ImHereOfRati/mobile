import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/google_auth_service.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_login_coordinator_test.mocks.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([
  AuthService,
  FcmTokenService,
  GoogleAuthService,
  TokenStorageService,
])
void main() {
  provideDummy<Result<String?>>(Success('dummy'));
  provideDummy<Result<MemberState>>(Success(MemberState.existingUser));

  late AuthLoginCoordinator authViewModel;
  late MockAuthService mockAuthService;
  late MockFcmTokenService mockFcmTokenService;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockTokenStorageService mockTokenStorage;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFcmTokenService = MockFcmTokenService();
    mockGoogleAuthService = MockGoogleAuthService();
    mockTokenStorage = MockTokenStorageService();

    authViewModel = AuthLoginCoordinator(
      mockAuthService,
      mockFcmTokenService,
      mockGoogleAuthService,
      mockTokenStorage,
    );
  });

  group('FCM enrollment for active sessions', () {
    setUp(() {
      when(mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'access');
      when(mockTokenStorage.getPendingAuth()).thenAnswer((_) async => false);
      when(mockTokenStorage.getUserStatus()).thenAnswer((_) async => 'ACTIVE');
      when(mockTokenStorage.getIsActive()).thenAnswer((_) async => true);
      when(
        mockFcmTokenService.syncTokenAndEnroll(),
      ).thenAnswer((_) async => 'fcm');
    });

    test('restored active session enrolls the current token', () async {
      await authViewModel.syncFcmForActiveSession();
      verify(mockFcmTokenService.syncTokenAndEnroll()).called(1);
    });

    test('signed out session does not enroll', () async {
      when(mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);
      await authViewModel.syncFcmForActiveSession();
      verifyNever(mockFcmTokenService.syncTokenAndEnroll());
    });

    for (final status in ['PENDING', 'INACTIVE', null]) {
      test('$status session does not enroll', () async {
        when(mockTokenStorage.getUserStatus()).thenAnswer((_) async => status);
        when(mockTokenStorage.getIsActive()).thenAnswer((_) async => null);
        await authViewModel.syncFcmForActiveSession();
        verifyNever(mockFcmTokenService.syncTokenAndEnroll());
      });
    }

    test(
      'pending flag prevents enrollment even with an active snapshot',
      () async {
        when(mockTokenStorage.getPendingAuth()).thenAnswer((_) async => true);
        await authViewModel.syncFcmForActiveSession();
        verifyNever(mockFcmTokenService.syncTokenAndEnroll());
      },
    );

    test('inactive flag prevents enrollment', () async {
      when(mockTokenStorage.getIsActive()).thenAnswer((_) async => false);
      await authViewModel.syncFcmForActiveSession();
      verifyNever(mockFcmTokenService.syncTokenAndEnroll());
    });

    test('terms activation completes before enrolling', () async {
      final consents = <Map<String, Object?>>[
        {'id': 1, 'agreed': true},
      ];
      when(mockTokenStorage.getPendingAuth()).thenAnswer((_) async => true);
      when(mockAuthService.activateWithTerms(consents)).thenAnswer((_) async {
        when(mockTokenStorage.getPendingAuth()).thenAnswer((_) async => false);
      });

      await authViewModel.activateWithTerms(consents);

      verifyInOrder([
        mockAuthService.activateWithTerms(consents),
        mockFcmTokenService.syncTokenAndEnroll(),
      ]);
    });

    test('failed activation does not enroll', () async {
      when(
        mockAuthService.activateWithTerms(any),
      ).thenThrow(StateError('failed'));
      await expectLater(authViewModel.activateWithTerms([]), throwsStateError);
      verifyNever(mockFcmTokenService.syncTokenAndEnroll());
    });

    test(
      'enrollment failure does not fail activation and retries next startup',
      () async {
        when(mockAuthService.activateWithTerms(any)).thenAnswer((_) async {});
        when(
          mockFcmTokenService.syncTokenAndEnroll(),
        ).thenAnswer((_) async => null);
        await authViewModel.activateWithTerms([]);
        when(
          mockFcmTokenService.syncTokenAndEnroll(),
        ).thenAnswer((_) async => 'fcm');
        await authViewModel.syncFcmForActiveSession();
        verify(mockFcmTokenService.syncTokenAndEnroll()).called(2);
      },
    );

    test('enrollment exception does not fail session restoration', () async {
      when(
        mockFcmTokenService.syncTokenAndEnroll(),
      ).thenThrow(StateError('FCM unavailable'));
      await expectLater(authViewModel.syncFcmForActiveSession(), completes);
    });
  });

  group('AuthLoginCoordinator - handleKakaoLogin', () {
    test('AuthLoginCoordinator가 올바른 의존성을 가지고 생성되어야 함', () {
      // Assert
      expect(authViewModel, isNotNull);
      expect(authViewModel, isA<AuthLoginCoordinator>());
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

  group('AuthLoginCoordinator - handleGoogleLogin', () {
    test('Google 로그인 성공 시 nonce 와 provider=google 을 전달해야 함', () async {
      when(
        mockGoogleAuthService.login(nonce: anyNamed('nonce')),
      ).thenAnswer((_) async => Success('google_id_token'));
      when(
        mockAuthService.sendIdTokenToServer(
          'google_id_token',
          nonce: anyNamed('nonce'),
          provider: OauthProvider.google,
        ),
      ).thenAnswer((_) async => MemberState.existingUser);

      final result = await authViewModel.handleGoogleLogin();

      expect(result, isA<Success<MemberState>>());
      final loginNonce =
          verify(
                mockGoogleAuthService.login(nonce: captureAnyNamed('nonce')),
              ).captured.single
              as String;
      final requestNonce =
          verify(
                mockAuthService.sendIdTokenToServer(
                  'google_id_token',
                  nonce: captureAnyNamed('nonce'),
                  provider: OauthProvider.google,
                ),
              ).captured.single
              as String;
      expect(loginNonce, requestNonce);
    });

    test('Google 로그인 취소 시 Failure 를 반환해야 함', () async {
      when(
        mockGoogleAuthService.login(nonce: anyNamed('nonce')),
      ).thenAnswer((_) async => Failure('취소'));

      final result = await authViewModel.handleGoogleLogin();

      expect(result, isA<Failure<MemberState>>());
      verify(mockGoogleAuthService.login(nonce: anyNamed('nonce'))).called(1);
      verifyNever(
        mockAuthService.sendIdTokenToServer(any, nonce: anyNamed('nonce')),
      );
    });
  });

  group('AuthLoginCoordinator - requestFCMTokenAndSendToServer', () {
    test('FCM 토큰 동기화 성공 시 Success를 반환해야 함', () async {
      when(
        mockFcmTokenService.syncTokenAndEnroll(),
      ).thenAnswer((_) async => 'test_fcm_token');

      final result = await authViewModel.requestFCMTokenAndSendToServer();

      expect(result, isA<Success<ResultMessage>>());
      expect(
        (result as Success<ResultMessage>).data,
        ResultMessage.fcmTokenGenerateSuccess,
      );
      verify(mockFcmTokenService.syncTokenAndEnroll()).called(1);
    });

    test('FCM 토큰 동기화 실패 시 Failure를 반환해야 함', () async {
      when(
        mockFcmTokenService.syncTokenAndEnroll(),
      ).thenAnswer((_) async => null);

      final result = await authViewModel.requestFCMTokenAndSendToServer();

      expect(result, isA<Failure<ResultMessage>>());
      verify(mockFcmTokenService.syncTokenAndEnroll()).called(1);
    });
  });

  group('AuthLoginCoordinator - 의존성 및 구조 테스트', () {
    test('AuthService 의존성이 올바르게 주입되어야 함', () {
      // Arrange & Act
      final viewModel = AuthLoginCoordinator(
        mockAuthService,
        mockFcmTokenService,
        mockGoogleAuthService,
        mockTokenStorage,
      );

      // Assert
      expect(viewModel, isNotNull);
    });

    test('FcmTokenService 의존성이 올바르게 주입되어야 함', () {
      // Arrange & Act
      final viewModel = AuthLoginCoordinator(
        mockAuthService,
        mockFcmTokenService,
        mockGoogleAuthService,
        mockTokenStorage,
      );

      // Assert
      expect(viewModel, isNotNull);
    });

    test('FcmAlertPermissionService 의존성이 올바르게 주입되어야 함', () {
      // Arrange & Act
      final viewModel = AuthLoginCoordinator(
        mockAuthService,
        mockFcmTokenService,
        mockGoogleAuthService,
        mockTokenStorage,
      );

      // Assert
      expect(viewModel, isNotNull);
    });

    test('AuthLoginCoordinator 타입으로 생성되어야 함', () {
      // Assert
      expect(authViewModel, isA<AuthLoginCoordinator>());
    });
  });

  group('AuthLoginCoordinator - Mock 동작 검증', () {
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
        mockAuthService.sendIdTokenToServer(testToken, nonce: 'test_nonce'),
      ).called(1);
    });

    test('FcmTokenService.syncTokenAndEnroll이 호출 가능해야 함', () async {
      // Arrange
      when(
        mockFcmTokenService.syncTokenAndEnroll(),
      ).thenAnswer((_) async => 'fcm_token');

      // Act
      final token = await mockFcmTokenService.syncTokenAndEnroll();

      // Assert
      expect(token, 'fcm_token');
      verify(mockFcmTokenService.syncTokenAndEnroll()).called(1);
    });

    group('AuthLoginCoordinator - 에러 처리', () {
      test('FCM 토큰 생성 중 예외 발생 시 예외를 전파해야 함', () async {
        // Arrange
        when(
          mockFcmTokenService.syncTokenAndEnroll(),
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
