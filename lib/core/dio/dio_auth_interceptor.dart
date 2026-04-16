import 'package:dio/dio.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';

import '../../shared/base/result/error_analyst.dart';
import 'api_config.dart';
import 'pending_request.dart';
import 'token_refresher.dart';

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
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ErrorAnalyst.log(err.toString(), err.stackTrace);
    if (err.response?.statusCode != 401) return handler.next(err);
    if (err.requestOptions.path.contains(ApiConfig.authReissuePath)) {
      _forceLogout(err, handler);
      return;
    }
    _handleUnauthorized(err, handler);
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

  void _forceLogout(DioException err, ErrorInterceptorHandler handler) {
    _tokenStorage.deleteAllTokens();
    _retrier.failAll(err);
    handler.reject(err);
  }
}
