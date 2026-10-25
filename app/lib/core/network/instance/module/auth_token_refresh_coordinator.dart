import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/auth/viewmodel/auth_invalidation_notifier.dart';
import 'package:iamhere/core/network/instance/module/pending_request.dart';
import 'package:iamhere/core/network/instance/token_refresher.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthTokenRefreshCoordinator {
  static const reissuePath = '/api/auth/refresh';

  final TokenStorageService _tokenStorage;
  final TokenRefresher _refresher;
  final RequestRetrier _retrier;
  final ProviderContainer _providerContainer;
  bool _isRefreshing = false;

  AuthTokenRefreshCoordinator(
    this._tokenStorage,
    this._refresher,
    this._retrier,
    this._providerContainer,
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
    _providerContainer
        .read(authInvalidationProvider.notifier)
        .requestInvalidation();
    _retrier.failAll(dioException);
    handler.reject(dioException);
  }
}
