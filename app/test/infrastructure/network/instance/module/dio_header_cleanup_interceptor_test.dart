import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/infrastructure/network/instance/module/dio_header_cleanup_interceptor.dart';
import 'package:mockito/mockito.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  test('onRequest_헤더값이_null인_경우_해당_헤더를_제거한다', () {
    final interceptor = DioHeaderCleanupInterceptor();
    final options = RequestOptions(path: '/api/test');
    options.headers.addAll({
      'keep': 'value',
      'removeNull': null,
      'removeBlank': '   ',
      'removeLiteral': 'null',
    });
    final handler = MockRequestInterceptorHandler();

    interceptor.onRequest(options, handler);

    expect(options.headers.containsKey('keep'), isTrue);
    expect(options.headers.containsKey('removeNull'), isFalse);
    expect(options.headers.containsKey('removeBlank'), isFalse);
    expect(options.headers.containsKey('removeLiteral'), isFalse);
    verify(handler.next(options)).called(1);
  });
}
