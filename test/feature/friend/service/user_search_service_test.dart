import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/dio/api_config.dart';
import 'package:iamhere/feature/friend/service/user_search_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_search_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late UserSearchService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = UserSearchService(dio: mockDio);
  });

  group('UserSearchService - searchByNickname', () {
    test('닉네임 검색 성공 시 유저 리스트를 반환해야 함', () async {
      // Arrange
      final responseData = {
        'data': [
          {
            'userId': '550e8400-e29b-41d4-a716-446655440000',
            'userEmail': 'test1@example.com',
            'userNickname': '테스트유저1',
          },
          {
            'userId': '550e8400-e29b-41d4-a716-446655440001',
            'userEmail': 'test2@example.com',
            'userNickname': '테스트유저2',
          },
        ],
      };

      when(mockDio.get(
        ApiConfig.userSearchPath('테스트'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConfig.userSearchPath('테스트')),
          ));

      // Act
      final result = await service.searchByNickname('테스트');

      // Assert
      expect(result.length, 2);
      expect(result[0].userNickname, '테스트유저1');
      expect(result[0].userEmail, 'test1@example.com');
      expect(result[0].userId, '550e8400-e29b-41d4-a716-446655440000');
      expect(result[1].userNickname, '테스트유저2');
    });

    test('검색 결과가 없으면 빈 리스트를 반환해야 함', () async {
      // Arrange
      when(mockDio.get(
        ApiConfig.userSearchPath('없는유저'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {'data': []},
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConfig.userSearchPath('없는유저')),
          ));

      // Act
      final result = await service.searchByNickname('없는유저');

      // Assert
      expect(result, isEmpty);
    });

    test('DioException 발생 시 빈 리스트를 반환해야 함', () async {
      // Arrange
      when(mockDio.get(
        ApiConfig.userSearchPath('에러'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConfig.userSearchPath('에러')),
        message: 'Network error',
      ));

      // Act
      final result = await service.searchByNickname('에러');

      // Assert
      expect(result, isEmpty);
    });
  });
}
