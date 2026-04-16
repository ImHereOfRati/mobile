import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/dio_properties.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:injectable/injectable.dart';

import '../module/dio_auth_interceptor.dart';
import '../module/pending_request.dart';
import 'token_refresher.dart';

@module
abstract class DioModule {
  @lazySingleton
  Dio dio(TokenStorageService tokenStorage, @Named("baseUrl") String url) {
    final dio = _consistDefaultDio(url);

    final refresher = TokenRefresher(tokenStorage, url);
    final retrier = RequestRetrier()..setDio(dio);

    dio.interceptors.addAll([
      DioAuthInterceptor(tokenStorage, refresher, retrier),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }

  Dio _consistDefaultDio(String baseUrl) {
    final defaultDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          DioProperties.contentTypeHeader: DioProperties.applicationJson,
        },
      ),
    );
    return defaultDio;
  }
}
