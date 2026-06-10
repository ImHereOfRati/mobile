import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/infrastructure/network/util/dio_handler.dart';

class TestDioHandler with DioHandler {}

void main() {
  test('mapToApiResponse_서버의_에러코드를_보존하여_응답객체로_매핑한다', () {
    final handler = TestDioHandler();
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: 401,
        data: {
          'imhereResponseCode': 'AUTH-104',
          'message': 'expired',
          'data': null,
        },
      ),
    );

    final result = handler.mapToApiResponse<String>(exception);

    expect(result, isA<ApiResponse<String>>());
    expect(result.imhereResponseCode, 'AUTH-104');
    expect(result.message, 'expired');
  });
}
