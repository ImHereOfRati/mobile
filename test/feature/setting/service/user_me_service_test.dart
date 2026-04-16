import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/dio/api_config.dart';
import 'package:iamhere/feature/setting/service/user_me_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_me_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late UserMeService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = UserMeService(dio: mockDio);
  });

  group('UserMeService - fetchMyInfo', () {
    test('내 정보 조회 성공 시 UserMeResponseDto를 반환해야 함', () async {
      // Arrange
      final responseData = {
        'data': {
          'userId': '550e8400-e29b-41d4-a716-446655440000',
          'userEmail': 'test@example.com',
          'userNickname': '테스트유저',
        },
      };

      when(mockDio.get(
        ApiConfig.userMePath,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConfig.userMePath),
          ));

      // Act
      final result = await service.fetchMyInfo();

      // Assert
      expect(result, isNotNull);
      expect(result!.userId, '550e8400-e29b-41d4-a716-446655440000');
      expect(result.userEmail, 'test@example.com');
      expect(result.userNickname, '테스트유저');
    });

    test('서버 에러 시 null을 반환해야 함', () async {
      // Arrange
      when(mockDio.get(
        ApiConfig.userMePath,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: null,
            statusCode: 500,
            requestOptions: RequestOptions(path: ApiConfig.userMePath),
          ));

      // Act
      final result = await service.fetchMyInfo();

      // Assert
      expect(result, isNull);
    });

    test('DioException 발생 시 null을 반환해야 함', () async {
      // Arrange
      when(mockDio.get(
        ApiConfig.userMePath,
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConfig.userMePath),
        message: 'Network error',
      ));

      // Act
      final result = await service.fetchMyInfo();

      // Assert
      expect(result, isNull);
    });
  });
}
