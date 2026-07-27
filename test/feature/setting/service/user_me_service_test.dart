import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/setting/service/user_me_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_me_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late UserMeService service;
  late MockDio dio;

  setUp(() {
    dio = MockDio();
    service = UserMeService(dio: dio);
  });

  test(
    'loads the current user for native auth session synchronization',
    () async {
      when(dio.get('/api/users/my', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'id': '365b7106-da29-4818-b816-967aef946354',
              'email': 'test@example.com',
              'nickname': '테스트 사용자',
              'oAuth2Provider': 'KAKAO',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/users/my'),
        ),
      );

      final result = await service.fetchMyInfo();

      expect(result?.id, '365b7106-da29-4818-b816-967aef946354');
      expect(result?.email, 'test@example.com');
      expect(result?.nickname, '테스트 사용자');
      expect(result?.oAuth2Provider, 'KAKAO');
    },
  );

  test('returns null for a non-success response', () async {
    when(dio.get('/api/users/my', options: anyNamed('options'))).thenAnswer(
      (_) async => Response(
        statusCode: 500,
        requestOptions: RequestOptions(path: '/api/users/my'),
      ),
    );

    expect(await service.fetchMyInfo(), isNull);
  });

  test('returns null when the request fails', () async {
    when(dio.get('/api/users/my', options: anyNamed('options'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/users/my'),
        message: 'Network error',
      ),
    );

    expect(await service.fetchMyInfo(), isNull);
  });
}
