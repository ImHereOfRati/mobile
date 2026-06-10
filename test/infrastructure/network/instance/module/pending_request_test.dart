import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/infrastructure/network/instance/module/pending_request.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'pending_request_test.mocks.dart';

@GenerateMocks([Dio, ErrorInterceptorHandler])
void main() {
  late MockDio mockDio;
  late RequestRetrier retrier;

  setUp(() {
    mockDio = MockDio();
    retrier = RequestRetrier(mockDio);
  });

  test('retryAll_새로운_Bearer_토큰과_함께_대기중인_요청들을_정상처리한다', () async {
    final requestOptions = RequestOptions(path: '/api/test');
    final handler = MockErrorInterceptorHandler();
    retrier.addToQueue(requestOptions, handler);
    when(mockDio.fetch(any)).thenAnswer(
      (_) async => Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {'ok': true},
      ),
    );

    await retrier.retryAll('new-access-token');

    expect(
      requestOptions.headers['Authorization'],
      'Bearer new-access-token',
    );
    verify(handler.resolve(any)).called(1);
  });

  test('failAll_대기중인_모든_요청을_거절처리한다', () {
    final requestOptions = RequestOptions(path: '/api/test');
    final handler = MockErrorInterceptorHandler();
    retrier.addToQueue(requestOptions, handler);
    final error = DioException(requestOptions: requestOptions);

    retrier.failAll(error);

    verify(handler.reject(error)).called(1);
  });

  test('retryAll_재시도_중_예외가_발생하면_해당_요청을_거절처리한다', () async {
    final requestOptions = RequestOptions(path: '/api/test');
    final handler = MockErrorInterceptorHandler();
    retrier.addToQueue(requestOptions, handler);
    when(mockDio.fetch(any)).thenThrow(Exception('network failed'));

    await retrier.retryAll('new-access-token');

    verify(handler.reject(any)).called(1);
  });
}
