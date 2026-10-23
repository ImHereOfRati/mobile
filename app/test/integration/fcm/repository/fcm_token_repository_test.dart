import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/integration/fcm/repository/fcm_token_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'fcm_token_repository_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FcmTokenRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = FcmTokenRepository(mockDio);
  });

  test('FCM 토큰 등록은 201 응답을 성공으로 처리해야 함', () async {
    when(
      mockDio.post(
        '/api/fcm-tokens',
        data: anyNamed('data'),
        options: anyNamed('options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: null,
        statusCode: 201,
        requestOptions: RequestOptions(path: '/api/fcm-tokens'),
      ),
    );

    final result = await repository.enrollFcmToken('token-1');

    expect(result, isTrue);
  });
}
