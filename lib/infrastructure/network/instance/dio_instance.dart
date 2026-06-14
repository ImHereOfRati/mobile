import 'package:dio/dio.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/infrastructure/network/instance/module/auth_token_refresh_coordinator.dart';
import 'package:injectable/injectable.dart';

import 'module/dio_auth_interceptor.dart';
import 'module/dio_header_cleanup_interceptor.dart';
import 'module/retry_interceptor.dart';

@module
abstract class DioInstance {
  BaseOptions _baseOptions(String baseUrl) {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    );
  }

  @Named('retryDio')
  @lazySingleton
  Dio retryDio(@Named("baseUrl") String url) {
    final retryDio = Dio(_baseOptions(url));
    retryDio.interceptors.addAll([
      RetryInterceptor(retryDio),
      DioHeaderCleanupInterceptor(),
    ]);
    return retryDio;
  }

  @lazySingleton
  Dio dio(
    TokenStorageService tokenStorage,
    @Named("baseUrl") String url,
    AuthTokenRefreshCoordinator coordinator,
  ) {
    final defaultDio = Dio(_baseOptions(url));

    defaultDio.interceptors.addAll([
      DioHeaderCleanupInterceptor(),
      DioAuthInterceptor(tokenStorage, coordinator),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return defaultDio;
  }
}
