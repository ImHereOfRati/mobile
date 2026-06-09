import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class RequestRetrier {
  final Dio _dio;
  final List<PendingRequest> _pendingRequests = [];

  RequestRetrier(@Named('retryDio') this._dio);

  void addToQueue(RequestOptions options, ErrorInterceptorHandler handler) {
    _pendingRequests.add(PendingRequest(options, handler));
  }

  Future<void> retryAll(String newAccessToken) async {
    while (_pendingRequests.isNotEmpty) {
      final pending = _pendingRequests.removeAt(0);
      await _retryRequest(pending, newAccessToken);
    }
  }

  void failAll(DioException err) {
    while (_pendingRequests.isNotEmpty) {
      final pending = _pendingRequests.removeAt(0);
      pending.handler.reject(err);
    }
  }

  Future<void> _retryRequest(
    PendingRequest pendingRequest,
    String token,
  ) async {
    pendingRequest.requestOptions.headers[DioProperties.authorizationHeader] =
        '${DioProperties.bearer} $token';
    try {
      final response = await _dio.fetch(pendingRequest.requestOptions);
      pendingRequest.handler.resolve(response);
    } catch (e) {
      pendingRequest.handler.reject(
        DioException(requestOptions: pendingRequest.requestOptions, error: e),
      );
    }
  }
}

class PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  const PendingRequest(this.requestOptions, this.handler);
}
