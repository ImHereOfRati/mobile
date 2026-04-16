import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';
import 'package:iamhere/core/dio/properties/http_status_code.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';

import '../../../shared/base/result/error_analyst.dart';
import '../instance/token_refresher.dart';
import '../properties/api_config.dart';
import 'pending_request.dart';

class DioAuthInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage;
  final TokenRefresher _refresher;
  final RequestRetrier _retrier;
  bool _isRefreshing = false;

  DioAuthInterceptor(this._tokenStorage, this._refresher, this._retrier);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra['requiresAuth'] as bool? ?? true;
    if (!requiresAuth) return handler.next(options);

    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers[DioProperties.authorizationHeader] =
          '${DioProperties.bearer} $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ErrorAnalyst.log(err.toString(), err.stackTrace);
    _exceptNotUnAuthorizedResponse(err, handler);
    _exceptAuthPathFromReAuth(err, handler);
    _handleUnauthorized(err, handler);
  }

  void _exceptNotUnAuthorizedResponse(
    DioException dioException,
    ErrorInterceptorHandler handler,
  ) {
    if (dioException.response?.statusCode != HttpStatusCode.unauthorized) {
      return handler.next(dioException);
    }
  }

  void _exceptAuthPathFromReAuth(
    DioException exception,
    ErrorInterceptorHandler handler,
  ) {
    final requestPath = exception.requestOptions.path;
    if (requestPath.contains(ApiConfig.authReissuePath)) {
      _forceLogout(exception, handler);
      return;
    }
  }

  void _forceLogout(
    DioException dioException,
    ErrorInterceptorHandler handler,
  ) {
    _tokenStorage.deleteAllTokens();
    _retrier.failAll(dioException);
    handler.reject(dioException);
  }

  void _handleUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isRefreshing) {
      _retrier.addToQueue(err.requestOptions, handler);
      return;
    }
    _isRefreshing = true;
    final newToken = await _refresher.refresh();
    if (newToken != null) {
      _retrier.addToQueue(err.requestOptions, handler);
      _retrier.retryAll(newToken);
    } else {
      _forceLogout(err, handler);
    }
    _isRefreshing = false;
  }
}
