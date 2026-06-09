import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/instance/module/pending_request.dart';
import 'package:iamhere/core/dio/instance/token_refresher.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthTokenRefreshCoordinator {
  static const reissuePath = '/api/auth/refresh';

  final TokenStorageService _tokenStorage;
  final TokenRefresher _refresher;
  final RequestRetrier _retrier;
  bool _isRefreshing = false;

  AuthTokenRefreshCoordinator(
    this._tokenStorage,
    this._refresher,
    this._retrier,
  );

  bool isRefreshRequest(String requestPath) {
    return requestPath.contains(reissuePath);
  }

  Future<void> handleUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isRefreshing) {
      _retrier.addToQueue(err.requestOptions, handler);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshResult = await _refresher.refresh();
      if (refreshResult.imhereResponseCode != 'SUCCESS' ||
          refreshResult.data == null) {
        await forceLogout(err, handler);
        return;
      }

      final newToken = refreshResult.data!;
      _retrier.addToQueue(err.requestOptions, handler);
      await _retrier.retryAll(newToken);
    } catch (_) {
      await forceLogout(err, handler);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> forceLogout(
    DioException dioException,
    ErrorInterceptorHandler handler,
  ) async {
    await _tokenStorage.deleteAllTokens();
    _retrier.failAll(dioException);
    handler.reject(dioException);
  }
}
