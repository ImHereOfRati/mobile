import 'package:dio/dio.dart';

class PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  PendingRequest(this.requestOptions, this.handler);
}

class RequestRetrier {
  Dio? _dio;
  final List<PendingRequest> _pendingRequests = [];

  void setDio(Dio dio) => _dio = dio;

  void addToQueue(RequestOptions options, ErrorInterceptorHandler handler) {
    _pendingRequests.add(PendingRequest(options, handler));
  }

  void retryAll(String newAccessToken) {
    for (final pending in _pendingRequests) {
      _retryRequest(pending, newAccessToken);
    }
    _pendingRequests.clear();
  }

  void failAll(DioException err) {
    for (final pending in _pendingRequests) pending.handler.reject(err);
    _pendingRequests.clear();
  }

  Future<void> _retryRequest(PendingRequest pending, String token) async {
    pending.requestOptions.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio!.fetch(pending.requestOptions);
      pending.handler.resolve(response);
    } catch (e) {
      pending.handler.reject(DioException(requestOptions: pending.requestOptions, error: e));
    }
  }
}