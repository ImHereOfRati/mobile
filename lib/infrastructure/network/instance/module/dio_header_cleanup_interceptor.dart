import 'package:dio/dio.dart';

/// Request header에서 null, blank, "null" 값을 제거하는 interceptor.
class DioHeaderCleanupInterceptor extends Interceptor {
  static const _nullLiteral = 'null';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.removeWhere((_, value) => _isRemovableHeaderValue(value));
    handler.next(options);
  }

  bool _isRemovableHeaderValue(Object? value) {
    if (value == null) return true;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty || trimmed == _nullLiteral;
    }
    return false;
  }
}
