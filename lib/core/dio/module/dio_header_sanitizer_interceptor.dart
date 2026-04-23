import 'package:dio/dio.dart';

/// 요청 헤더에서 null 값을 제거하는 인터셉터.
/// If-None-Match 와 같은 조건부 헤더가 null 로 직렬화되어 전송되는 것을 방지한다.
class DioHeaderSanitizerInterceptor extends Interceptor {
  static const _nullLiteral = 'null';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.removeWhere((_, value) => _isNullish(value));
    handler.next(options);
  }

  bool _isNullish(Object? value) {
    if (value == null) return true;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty || trimmed == _nullLiteral;
    }
    return false;
  }
}
