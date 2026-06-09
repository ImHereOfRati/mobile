import 'package:dio/dio.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/infrastructure/network/instance/module/auth_token_refresh_coordinator.dart';
import 'package:injectable/injectable.dart';

import 'module/dio_auth_interceptor.dart';
import 'module/dio_header_cleanup_interceptor.dart';

@module
abstract class DioInstance {
  BaseOptions _baseOptions() {
    return BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    );
  }

  @Named('retryDio')
  @lazySingleton
  Dio retryDio(@Named("baseUrl") String url) {
    final retryDio = Dio(_baseOptions());
    retryDio.interceptors.add(DioHeaderCleanupInterceptor());
    return retryDio;
  }

  @lazySingleton
  Dio dio(
    TokenStorageService tokenStorage,
    @Named("baseUrl") String url,
    AuthTokenRefreshCoordinator coordinator,
  ) {
    final defaultDio = Dio(_baseOptions());

    defaultDio.interceptors.addAll([
      DioHeaderCleanupInterceptor(),
      DioAuthInterceptor(tokenStorage, coordinator),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return defaultDio;
  }
}
