import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/infrastructure/network/util/dio_handler.dart';

class _TestDioHandler with DioHandler {}

void main() {
  late _TestDioHandler handler;

  setUp(() {
    handler = _TestDioHandler();
  });

  test('safeApiCall 은 알 수 없는 예외를 일관된 unknown error 응답으로 변환한다', () async {
    final result = await handler.safeApiCall<String>(() async {
      throw StateError('unexpected state');
    });

    expect(result.imhereResponseCode, DioHandler.unknownErrorCode);
    expect(result.message, ResultMessage.unknownError.message);
  });

  test('mapToApiResponse 는 응답 body가 없으면 기본 네트워크 오류 메시지를 사용한다', () {
    final result = handler.mapToApiResponse<String>(
      DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        message: null,
      ),
    );

    expect(result.imhereResponseCode, DioHandler.networkErrorCode);
    expect(result.message, ResultMessage.dioException.message);
  });
}
