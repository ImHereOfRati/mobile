import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';

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
    for (final pending in _pendingRequests) {
      pending.handler.reject(err);
    }
    _pendingRequests.clear();
  }

  Future<void> _retryRequest(
    PendingRequest pendingRequest,
    String token,
  ) async {
    pendingRequest.requestOptions.headers[DioProperties.authorizationHeader] =
        '${DioProperties.bearer} $token';
    try {
      final response = await _dio!.fetch(pendingRequest.requestOptions);
      pendingRequest.handler.resolve(response);
    } catch (e) {
      pendingRequest.handler.reject(
        DioException(requestOptions: pendingRequest.requestOptions, error: e),
      );
    }
  }
}
