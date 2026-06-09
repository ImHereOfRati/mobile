import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/http_status_code.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';

import '../../../../shared/base/result/error_analyst.dart';
import 'auth_token_refresh_coordinator.dart';

class DioAuthInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage;
  final AuthTokenRefreshCoordinator _coordinator;

  DioAuthInterceptor(this._tokenStorage, this._coordinator);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var isAuthRequire = (options.extra['AuthRequirement'] as bool);
    if (!isAuthRequire) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    ErrorAnalyst.log(err.toString(), err.stackTrace);

    if (err.response?.statusCode != HttpStatusCode.unauthorized) {
      handler.next(err);
      return;
    }

    if (_coordinator.isRefreshRequest(err.requestOptions.path)) {
      await _coordinator.forceLogout(err, handler);
      return;
    }
    await _coordinator.handleUnauthorized(err, handler);
  }
}
