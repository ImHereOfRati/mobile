import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/auth/service/auth_service.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([Dio, TokenStorageService])
void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockTokenStorageService mockTokenStorage;

  setUp(() {
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorageService();
    authService = AuthService(mockDio, mockTokenStorage);
  });

  group('AuthService - sendIdTokenToServer', () {
    const testIdToken = 'test_id_token_123';
    const testAccessToken = 'test_access_token_456';
    const testRefreshToken = 'test_refresh_token_789';

    test('성공: 200 응답 시 false를 반환하고 토큰을 저장해야 함', () async {
      final responseData = {
        'accessToken': testAccessToken,
        'refreshToken': testRefreshToken,
      };

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      when(
        mockTokenStorage.saveAccessToken(any),
      ).thenAnswer((_) async => Future.value());
      when(
        mockTokenStorage.saveRefreshToken(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      final isNewUser = await authService.sendIdTokenToServer(testIdToken);

      // Assert
      expect(isNewUser, false); // 기존 사용자 (200)
      verify(mockDio.post(any, data: anyNamed('data'))).called(1);

      verify(mockTokenStorage.saveAccessToken(testAccessToken)).called(1);
      verify(mockTokenStorage.saveRefreshToken(testRefreshToken)).called(1);
    });

    test('성공: 201 응답 시 true를 반환하고 토큰을 저장해야 함', () async {
      // Arrange
      final responseData = {
        'accessToken': testAccessToken,
        'refreshToken': testRefreshToken,
      };

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      when(
        mockTokenStorage.saveAccessToken(any),
      ).thenAnswer((_) async => Future.value());
      when(
        mockTokenStorage.saveRefreshToken(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      final isNewUser = await authService.sendIdTokenToServer(testIdToken);

      // Assert
      expect(isNewUser, true); // 신규 사용자 (201)
      verify(mockTokenStorage.saveAccessToken(testAccessToken)).called(1);
      verify(mockTokenStorage.saveRefreshToken(testRefreshToken)).called(1);
    });

    test('성공: accessToken만 있을 때 accessToken만 저장해야 함', () async {
      // Arrange
      final responseData = {'accessToken': testAccessToken};

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      when(
        mockTokenStorage.saveAccessToken(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await authService.sendIdTokenToServer(testIdToken);

      // Assert
      verify(mockTokenStorage.saveAccessToken(testAccessToken)).called(1);
      verifyNever(mockTokenStorage.saveRefreshToken(any));
    });

    test('성공: refreshToken만 있을 때 refreshToken만 저장해야 함', () async {
      // Arrange
      final responseData = {'refreshToken': testRefreshToken};

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      when(
        mockTokenStorage.saveRefreshToken(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await authService.sendIdTokenToServer(testIdToken);

      // Assert
      verify(mockTokenStorage.saveRefreshToken(testRefreshToken)).called(1);
      verifyNever(mockTokenStorage.saveAccessToken(any));
    });

    test('성공: 토큰이 null일 때 저장하지 않아야 함', () async {
      // Arrange
      final responseData = {'accessToken': null, 'refreshToken': null};

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      // Act
      await authService.sendIdTokenToServer(testIdToken);

      // Assert
      verifyNever(mockTokenStorage.saveAccessToken(any));
      verifyNever(mockTokenStorage.saveRefreshToken(any));
    });

    test('실패: 401 응답 시 false를 반환하고 토큰을 저장하지 않아야 함', () async {
      // Arrange
      final responseData = {
        'accessToken': testAccessToken,
        'refreshToken': testRefreshToken,
      };

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 401,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      // Act
      final isNewUser = await authService.sendIdTokenToServer(testIdToken);

      // Assert
      expect(isNewUser, false); // 201이 아니므로 false
      verifyNever(mockTokenStorage.saveAccessToken(any));
      verifyNever(mockTokenStorage.saveRefreshToken(any));
    });

    test('실패: 500 응답 시 false를 반환하고 토큰을 저장하지 않아야 함', () async {
      // Arrange
      final responseData = {
        'accessToken': testAccessToken,
        'refreshToken': testRefreshToken,
      };

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 500,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      // Act
      final isNewUser = await authService.sendIdTokenToServer(testIdToken);

      // Assert
      expect(isNewUser, false); // 201이 아니므로 false
      verifyNever(mockTokenStorage.saveAccessToken(any));
      verifyNever(mockTokenStorage.saveRefreshToken(any));
    });

    test('DIO 에러 발생 시 다시 오류를 던진다', () async {
      //given
      final requestOptions = RequestOptions(path: '/api/v1/auth/login');

      when(
        mockDio.post(any, data: anyNamed('data')),
      ).thenThrow(DioException(requestOptions: requestOptions));

      // when, then
      expect(
        authService.sendIdTokenToServer(testIdToken),
        throwsA(isA<Exception>()),
      );

      // then
      verifyNever(mockTokenStorage.saveAccessToken(any));
      verifyNever(mockTokenStorage.saveRefreshToken(any));
    });
  });
}
