import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const int initialDelayMs = 100;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    if (_shouldRetry(err) && _getRetryCount(requestOptions) < maxRetries) {
      _incrementRetryCount(requestOptions);
      final delayMs = _calculateDelay(_getRetryCount(requestOptions));

      await Future.delayed(Duration(milliseconds: delayMs));

      try {
        final response = await Dio().request(
          requestOptions.path,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            contentType: requestOptions.contentType,
            responseType: requestOptions.responseType,
            extra: requestOptions.extra,
          ),
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
        );
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    if (err.response?.statusCode == null) return true;

    final statusCode = err.response!.statusCode;
    return statusCode == 429 || statusCode == 503 || statusCode == 502 || statusCode == 504;
  }

  int _getRetryCount(RequestOptions options) {
    return (options.extra['retryCount'] as int?) ?? 0;
  }

  void _incrementRetryCount(RequestOptions options) {
    options.extra['retryCount'] = (_getRetryCount(options) + 1);
  }

  int _calculateDelay(int retryCount) {
    return initialDelayMs * (1 << (retryCount - 1));
  }
}
