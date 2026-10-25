import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/setting/service/user_me_service.dart';
import 'package:iamhere/feature/auth/model/exception/invalid_auth_state_exception.dart';
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

  test('raises an invalid-session error for unauthorized responses', () async {
    when(dio.get('/api/users/my', options: anyNamed('options'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/users/my'),
        response: Response(
          statusCode: 403,
          requestOptions: RequestOptions(path: '/api/users/my'),
        ),
      ),
    );

    expect(service.fetchMyInfo, throwsA(isA<InvalidAuthStateException>()));
  });

  group('changeNickname', () {
    test('patches the nickname and returns the updated user', () async {
      when(
        dio.patch(
          '/api/users/my',
          data: {'nickname': '새 닉네임'},
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'id': '365b7106-da29-4818-b816-967aef946354',
              'email': 'test@example.com',
              'nickname': '새 닉네임',
              'oAuth2Provider': 'KAKAO',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/users/my'),
        ),
      );

      final result = await service.changeNickname('새 닉네임');

      expect(result.nickname, '새 닉네임');
    });

    test('raises an invalid-session error for unauthorized responses', () {
      when(
        dio.patch(
          '/api/users/my',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(_dioError('/api/users/my', 401));

      expect(
        () => service.changeNickname('새 닉네임'),
        throwsA(isA<InvalidAuthStateException>()),
      );
    });

    test('rethrows other request failures', () {
      when(
        dio.patch(
          '/api/users/my',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(_dioError('/api/users/my', 500));

      expect(
        () => service.changeNickname('새 닉네임'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('withdraw', () {
    const path = '/api/users/my/withdrawal';

    test('deletes the account', () async {
      when(dio.delete(path, options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        ),
      );

      await service.withdraw();

      verify(dio.delete(path, options: anyNamed('options'))).called(1);
    });

    test('raises an invalid-session error for forbidden responses', () {
      when(
        dio.delete(path, options: anyNamed('options')),
      ).thenThrow(_dioError(path, 403));

      expect(service.withdraw, throwsA(isA<InvalidAuthStateException>()));
    });

    test('rethrows other request failures', () {
      when(
        dio.delete(path, options: anyNamed('options')),
      ).thenThrow(_dioError(path, 500));

      expect(service.withdraw, throwsA(isA<DioException>()));
    });
  });
}

DioException _dioError(String path, int statusCode) => DioException(
  requestOptions: RequestOptions(path: path),
  response: Response(
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path),
  ),
);
