import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'token_storage_service_test.mocks.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([FlutterSecureStorage])
void main() {
  late TokenStorageService tokenStorageService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorageService = TokenStorageService(mockStorage);
  });

  group('TokenStorageService - Access Token', () {
    const testAccessToken = 'test_access_token_123';

    test('saveAccessToken: Access Token을 저장해야 함', () async {
      // Arrange
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async => Future.value());

      // Act
      await tokenStorageService.saveAccessToken(testAccessToken);

      // Assert
      verify(
        mockStorage.write(key: 'access_token', value: testAccessToken),
      ).called(1);
    });

    test('getAccessToken: 저장된 Access Token을 반환해야 함', () async {
      // Arrange
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => testAccessToken);

      // Act
      final result = await tokenStorageService.getAccessToken();

      // Assert
      expect(result, testAccessToken);
      verify(mockStorage.read(key: 'access_token')).called(1);
    });

    test('getAccessToken: 저장된 토큰이 없으면 null을 반환해야 함', () async {
      // Arrange
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);

      // Act
      final result = await tokenStorageService.getAccessToken();

      // Assert
      expect(result, null);
      verify(mockStorage.read(key: 'access_token')).called(1);
    });

    test('deleteAccessToken: Access Token을 삭제해야 함', () async {
      // Arrange
      when(
        mockStorage.delete(key: anyNamed('key')),
      ).thenAnswer((_) async => Future.value());

      // Act
      await tokenStorageService.deleteAccessToken();

      // Assert
      verify(mockStorage.delete(key: 'access_token')).called(1);
    });
  });

  group('TokenStorageService - Refresh Token', () {
    const testRefreshToken = 'test_refresh_token_456';

    test('saveRefreshToken: Refresh Token을 저장해야 함', () async {
      // Arrange
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async => Future.value());

      // Act
      await tokenStorageService.saveRefreshToken(testRefreshToken);

      // Assert
      verify(
        mockStorage.write(key: 'refresh_token', value: testRefreshToken),
      ).called(1);
    });

    test('getRefreshToken: 저장된 Refresh Token을 반환해야 함', () async {
      // Arrange
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => testRefreshToken);

      // Act
      final result = await tokenStorageService.getRefreshToken();

      // Assert
      expect(result, testRefreshToken);
      verify(mockStorage.read(key: 'refresh_token')).called(1);
    });

    test('getRefreshToken: 저장된 토큰이 없으면 null을 반환해야 함', () async {
      // Arrange
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);

      // Act
      final result = await tokenStorageService.getRefreshToken();

      // Assert
      expect(result, null);
      verify(mockStorage.read(key: 'refresh_token')).called(1);
    });

    test('deleteRefreshToken: Refresh Token을 삭제해야 함', () async {
      // Arrange
      when(
        mockStorage.delete(key: anyNamed('key')),
      ).thenAnswer((_) async => Future.value());

      // Act
      await tokenStorageService.deleteRefreshToken();

      // Assert
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });

  group('TokenStorageService - All Tokens', () {
    test('deleteAllTokens: 모든 토큰을 삭제해야 함', () async {
      // Arrange
      when(
        mockStorage.delete(key: anyNamed('key')),
      ).thenAnswer((_) async => Future.value());

      // Act
      await tokenStorageService.deleteAllTokens();

      // Assert
      verify(mockStorage.delete(key: 'access_token')).called(1);
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
    });

    test('통합: Access Token 저장 후 조회 시나리오', () async {
      // Arrange
      const token = 'integrated_access_token';
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async => Future.value());
      when(
        mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => token);

      // Act
      await tokenStorageService.saveAccessToken(token);
      final result = await tokenStorageService.getAccessToken();

      // Assert
      expect(result, token);
      verify(mockStorage.write(key: 'access_token', value: token)).called(1);
      verify(mockStorage.read(key: 'access_token')).called(1);
    });

    test('통합: Refresh Token 저장 후 조회 시나리오', () async {
      // Arrange
      const token = 'integrated_refresh_token';
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async => Future.value());
      when(
        mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => token);

      // Act
      await tokenStorageService.saveRefreshToken(token);
      final result = await tokenStorageService.getRefreshToken();

      // Assert
      expect(result, token);
      verify(mockStorage.write(key: 'refresh_token', value: token)).called(1);
      verify(mockStorage.read(key: 'refresh_token')).called(1);
    });

    test('통합: 모든 토큰 저장 후 삭제 시나리오', () async {
      // Arrange
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async => Future.value());
      when(
        mockStorage.delete(key: anyNamed('key')),
      ).thenAnswer((_) async => Future.value());

      // Act
      await tokenStorageService.saveAccessToken('access');
      await tokenStorageService.saveRefreshToken('refresh');
      await tokenStorageService.deleteAllTokens();

      // Assert
      verify(mockStorage.write(key: 'access_token', value: 'access')).called(1);
      verify(
        mockStorage.write(key: 'refresh_token', value: 'refresh'),
      ).called(1);
      verify(mockStorage.delete(key: 'access_token')).called(1);
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });

  group('TokenStorageService - Error Handling', () {
    test('saveAccessToken: 저장 실패 시 예외를 던져야 함', () async {
      // Arrange
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenThrow(Exception('Storage write failed'));

      // Act & Assert
      expect(
        () => tokenStorageService.saveAccessToken('token'),
        throwsA(isA<Exception>()),
      );
    });

    test('getAccessToken: 조회 실패 시 예외를 던져야 함', () async {
      // Arrange
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenThrow(Exception('Storage read failed'));

      // Act & Assert
      expect(
        () => tokenStorageService.getAccessToken(),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteAccessToken: 삭제 실패 시 예외를 던져야 함', () async {
      // Arrange
      when(
        mockStorage.delete(key: anyNamed('key')),
      ).thenThrow(Exception('Storage delete failed'));

      // Act & Assert
      expect(
        () => tokenStorageService.deleteAccessToken(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
