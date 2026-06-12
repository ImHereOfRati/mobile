import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/infrastructure/network/instance/token_refresher.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'token_refresher_test.mocks.dart';

@GenerateMocks([Dio, TokenStorageService])
void main() {
  late MockDio mockDio;
  late MockTokenStorageService mockStorage;
  late TokenRefresher tokenRefresher;

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockTokenStorageService();
    tokenRefresher = TokenRefresher(mockStorage, mockDio);
  });

  test('refresh_갱신에_성공하면_새_토큰들을_저장하고_액세스_토큰을_반환한다', () async {
    when(
      mockStorage.getRefreshToken(),
    ).thenAnswer((_) async => 'refresh-token');
    when(
      mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        statusCode: 200,
        data: {
          'imhereResponseCode': 'SUCCESS',
          'message': 'OK',
          'data': {
            'accessToken': 'access-token',
            'refreshToken': 'next-refresh-token',
          },
        },
      ),
    );
    when(mockStorage.saveAccessToken(any)).thenAnswer((_) async {});
    when(mockStorage.saveRefreshToken(any)).thenAnswer((_) async {});

    final result = await tokenRefresher.refresh();

    expect(result, isA<ApiResponse<String>>());
    expect(result.imhereResponseCode, 'SUCCESS');
    expect(result.data, 'access-token');
    verify(mockStorage.saveAccessToken('access-token')).called(1);
    verify(mockStorage.saveRefreshToken('next-refresh-token')).called(1);
  });

  test('refresh_서버에러시_서버의_응답코드와_메시지를_유지하여_반환한다', () async {
    when(
      mockStorage.getRefreshToken(),
    ).thenAnswer((_) async => 'refresh-token');
    when(
      mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/refresh'),
          statusCode: 401,
          data: {
            'imhereResponseCode': 'AUTH-104',
            'message': 'refresh token expired',
            'data': null,
          },
        ),
      ),
    );

    final result = await tokenRefresher.refresh();

    expect(result.imhereResponseCode, 'AUTH-104');
    expect(result.message, 'refresh token expired');
    expect(result.data, isNull);
    verifyNever(mockStorage.saveAccessToken(any));
    verifyNever(mockStorage.saveRefreshToken(any));
  });
}
